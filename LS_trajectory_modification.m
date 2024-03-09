function obj = LS_trajectory_modification(obj,varargin)
%%  依赖关系判断
if obj.syset.flags.read_flag_sccmload~=1
    error('strand_model has not been processed yet!')
end
%%  default values
default_flag_plot = 1;      % 是否绘图
default_flag_plotin=0;      % 是否绘制曲面
default_flag_parfor=1;      % 是否并行计算
default_flag_delay= 1;      % 是否延迟补偿
default_k         = 1;      % 修正系数
default_k_u       = 0.3;    % 修正系数-挤出速度
default_k_h       = 0.8;    % 修正系数-挤出速度
%   声明一个p为inputParser格式的。其实也可以理解为一个该格式的句柄一样的东西
IP = inputParser;
addRequired(IP,'obj');
%   接下来两个是可选参数，名字分别为’stepsize'和'OptimalityTolerance'，如果没有检测到输入将有相应的缺省值defaulth和epsilon。这些都在函数开头声明好了
addParameter(IP,'flag_plot',default_flag_plot);
addParameter(IP,'flag_plotin',default_flag_plotin);
addParameter(IP,'flag_parfor',default_flag_parfor);
addParameter(IP,'flag_delay',default_flag_delay);
addParameter(IP,'k',default_k);
addParameter(IP,'k_u',default_k_u);
addParameter(IP,'k_h',default_k_h);
%   利用parse函数将输入参数与上面的进行匹配
parse(IP,obj,varargin{:});
%   此时就已经生成好了一个inputParser格式的参数p，p里面含有不少东西，其中它的Results为一个结构体，是输入参数在匹配后的值，利用这个可以完成我的output的赋值
flag_plot = IP.Results.flag_plot;
flag_plotin=IP.Results.flag_plotin;
flag_parfor=IP.Results.flag_parfor;
flag_delay= IP.Results.flag_delay;
k         = IP.Results.k;
k_u       = IP.Results.k_u;
k_h       = IP.Results.k_h;
%%  处理程序
%   读取截面模型数据
strand_model = obj.LS_model.strand_model;
gof          = obj.LS_model.gof;
output       = obj.LS_model.output;
datainfo     = obj.LS_model.datainfo;
%   读取基本设定
dd = obj.Devinfo.nozzle_diameter;
FE = obj.Devinfo.extruderate;
LH = obj.Devinfo.trajectory.layer_height;
%   模型曲面参数
fit_density = 1e3;
xl = linspace(datainfo.Hmin,datainfo.Hmax,fit_density);
yl = linspace(datainfo.Vmin,datainfo.Vmax,fit_density);
[XL,YL] = meshgrid(xl,yl);
ZL = strand_model(XL,YL);
if flag_plotin==1 %如果开了动画，就先绘图，然后后续更新句柄
    %   做一下初始化计算，后续更新数据
    AV = mean([datainfo.Vmin,datainfo.Vmax]);
    AH = mean([datainfo.Hmin,datainfo.Hmax]);
    ASW= strand_model(AH*1.1,AV*1.1);
    TSW= strand_model(AH*0.9,AV*0.9);
    % ASH= AH-0.1;
    TXL = XL; TYL = YL; TZL = ZL;
    Z_sn = find(abs(TZL-ASW)<=1e-3); Xsolu = TXL(Z_sn); Ysolu = TYL(Z_sn); Zsolu = TZL(Z_sn);
    distv= [Xsolu-AH,Ysolu-AV,Zsolu-ASW];
    dist = sqrt(distv(:,1).^2+distv(:,2).^2+distv(:,3).^2);
    distp= find(dist==min(dist));
    xm = Xsolu(distp); ym = Ysolu(distp); zm = Zsolu(distp);
    Z_sn2 = find(abs(TZL-TSW)<=1e-3); Xsolu2 = TXL(Z_sn2); Ysolu2 = TYL(Z_sn2); Zsolu2 = TZL(Z_sn2);
    distv2=Xsolu2-xm; dist2 =abs(distv2); distp2=find(dist2 == min(dist2) );
    Xsolu3 = Xsolu2(distp2); Ysolu3 = Ysolu2(distp2); Zsolu3 = Zsolu2(distp2);
    %   绘制初始图片
    f6=figure(6);
    p1=plot(strand_model);                                      % 绘制模型
    hold on
    p2=plot3(AH,AV,strand_model(AH,AV),'y.','MarkerSize',50);   % 实际工艺点
    p3=plot3(Xsolu,Ysolu,Zsolu,'r.');                           % 实际线宽
    p4=plot3(xm,ym,zm,'g.','MarkerSize',50);                    % 等效工艺点
    p5=plot3(Xsolu2,Ysolu2,Zsolu2,'g.');                        % 目标曲线
    p6=plot3(Xsolu3,Ysolu3,Zsolu3,'r.','MarkerSize',50);        % 目标工艺点
    p7=quiver3(xm,ym,zm,Xsolu3-xm,Ysolu3-ym,Zsolu3-zm,'r');     % 工艺调节向量
    hold off
    view([0 0 1])
    xlabel('H/a_0')
    ylabel('V/U')
    zlabel('W')
    title(['i=',num2str(0),',Actual:',num2str(0),'mm,Target:',num2str(0),'mm.'])
    set(gca,'FontName','Times New Roman')
end
% 初始化并行池
if flag_parfor==1
    % parpool(4);
else
    fff = waitbar(0,'Processing...');
end
%   轨迹补偿
for i=1:length(obj.LS_deviation)
    % 对每一组
    if flag_parfor==1
        % for j=1:length(obj.LS_deviation(i).deviation)
        nump = length(obj.LS_deviation(i).deviation);
        ww = [obj.LS_deviation(i).deviation.ww]';
        dw = [obj.LS_deviation(i).deviation.dw]';
        ff = [obj.LS_deviation(i).deviation.ff]';
        df = NaN(size(ff));
        hh = [obj.LS_deviation(i).deviation.hh]';
        dh = [obj.LS_deviation(i).deviation.dh]';
        parfor j=1:nump
            % percent = j/round(nump*1e-2);
            % if rem(percent,1)==0
            %     % mod(100*j/length(obj.LS_deviation(i).deviation),1)<1e-2
            %     % disp([num2str(100*j/length(obj.LS_deviation(i).deviation)),'%'])
            %     waitbar(j/length(nump),fff,['group ',num2str(i),' Processing...',num2str(round(j/nump*1e2),'%05.2f'),'%'])
            % end

            % 对于线条数据，查询工艺曲面对工艺参数做调整
            % 如果是需要做启停段补偿的数据，则不做速度调整
            if ~isnan(dw(j))
                AV = ff(j)/FE/k_u;                                    % 速度正规化
                AH = (hh(j)-dh(j))/dd/k_h;  % 高度正规化
                %   ！！！！如果需要修正的话，需要在这里调节
                % AV = AV-a;
                % AH = AH-strand_model.c;
                %   结束
                ASW = (ww(j)-dw(j))/dd; % 线宽正规化
                TSW = ww(j)/dd;                                       % 目标线宽正规化
                ASH = hh(j)/dd;                                       % 目标线高正规化
                %   如果不在实验数据的范围内，则应禁止操作，并跳过该点
                if AV<datainfo.Vmin || AV>datainfo.Vmax || AH<datainfo.Hmin || AH>datainfo.Hmax
                    msg = '不在实验数据的范围内，禁止操作，并跳过该点';
                    warning(msg)
                    %             continue
                    xl2 = linspace(min(datainfo.Hmin,AH),max(datainfo.Hmax,AH),fit_density);
                    yl2 = linspace(min(datainfo.Vmin,AV),max(datainfo.Vmax,AV),fit_density);
                    [XL2,YL2] = meshgrid(xl2,yl2);
                    TXL = XL2;
                    TYL = YL2;
                    TZL = strand_model(XL2,YL2);
                else
                    TXL = XL;
                    TYL = YL;
                    TZL = ZL;
                end
                %   进行线宽的调整
                %   判断实际线宽是否在模型范围内
                if ASW<min(min(TZL)) || ASW>max(max(TZL))
                    % 不在范围内，警告并做调整
                    msg = ['第',num2str(i),'个数据的线宽(',num2str(LJ_processed_data.adjusted_data(i,6)),'mm),不在模型接受范围[',num2str(min(min(TZL))),',',num2str(max(max(TZL))),']内，将其置为模型极值！'];
                    warning(msg)
                    if ASW<min(min(TZL))
                        ASW = min(min(TZL));
                    elseif ASW<max(max(TZL))
                        ASW = max(max(TZL));
                    end
                end
                %   在模型曲面上寻找符合实际线宽的数据点
                Z_sn = find(abs(TZL-ASW)<=1e-3);
                Xsolu = TXL(Z_sn);
                Ysolu = TYL(Z_sn);
                Zsolu = TZL(Z_sn);
                % %   绘图
                % if flag_plotin==1
                %     % figure(6)
                %     % plot(strand_model)
                %     % xlabel('H/a_0')
                %     % ylabel('V/U')
                %     % zlabel('W')
                %     % hold on
                %     % plot3(Xsolu,Ysolu,Zsolu,'r.')
                %     % plot3(AH,AV,strand_model(AH,AV),'y.','MarkerSize',50)
                %     % hold off
                %     % view([0 0 1])
                %     set(p2,'XData',AH,'YData',AV,'ZData',strand_model(AH,AV));
                %     set(p3,'XData',Xsolu,'YData',Ysolu,'ZData',Zsolu);
                % end
                %   找到参数范围内距离实际点最近的点
                %         distv= [Xsolu-ASH,Ysolu-AV,Zsolu-ASW];
                distv= [Xsolu-AH,Ysolu-AV,Zsolu-ASW];
                dist = sqrt(distv(:,1).^2+distv(:,2).^2+distv(:,3).^2);
                distp= find(dist==min(dist));
                xm = Xsolu(distp);
                ym = Ysolu(distp);
                zm = Zsolu(distp);
                % %   绘图
                % if flag_plotin==1
                %     % hold on
                %     % plot3(xm,ym,zm,'g.','MarkerSize',50)
                %     % hold off
                %     set(p4,'XData',xm,'YData',ym,'ZData',zm);
                % end
                %   查找目标值对应的曲线
                Z_sn2 = find(abs(TZL-TSW)<=1e-3);
                if isempty(Z_sn2)
                    warning('找不到调整点，舍弃')
                    continue
                end
                Xsolu2 = TXL(Z_sn2);
                Ysolu2 = TYL(Z_sn2);
                Zsolu2 = TZL(Z_sn2);
                % %   绘图
                % if flag_plotin==1
                %     % hold on
                %     % plot3(Xsolu2,Ysolu2,Zsolu2,'g.')
                %     % hold off
                %     set(p5,'XData',Xsolu2,'YData',Ysolu2,'ZData',Zsolu2);
                % end
                %   按照只调整UH找到上一步结果中符合结果的点
                distv2=Xsolu2-xm;
                dist2 =abs(distv2);
                distp2=find(dist2 == min(dist2) );
                if length(distp2)>1
                    distp2(2:end)=[];
                end
                Xsolu3 = Xsolu2(distp2);
                Ysolu3 = Ysolu2(distp2);
                Zsolu3 = Zsolu2(distp2);
                % %   绘图
                % if flag_plotin==1
                %     % hold on
                %     % plot3(Xsolu3,Ysolu3,Zsolu3,'r.','MarkerSize',50)
                %     % quiver3(xm,ym,zm,Xsolu3-xm,Ysolu3-ym,Zsolu3-zm,'r')
                %     % hold off
                %     % title(['i=',num2str(i),',实际线宽:',num2str(obj.LS_deviation(i).deviation(j).ww-obj.LS_deviation(i).deviation(j).dw),'mm,理想线宽:',num2str(obj.LS_deviation(i).deviation(j).ww),'mm.'])
                %     % pause(0.005)
                %     set(p6,'XData',Xsolu3,'YData',Ysolu3,'ZData',Zsolu3);
                %     set(p7,'XData',xm,'YData',ym,'ZData',zm,'UData',Xsolu3-xm,'VData',Ysolu3-ym,'WData',Zsolu3-zm);
                %     title(['num=',num2str(j),',Actual:',num2str(ww(j)-dw(j)),'mm,Target:',num2str(ww(j)),'mm.'])
                %     pause(0.005)
                % end
                %   把速度的变化量记录下来
                % LJ_processed_data.adjusted_data(i,11) = 60*LJ_processed_data.adjusted_data(i,12)*(Ysolu3-ym);
                % obj.LS_deviation(i).deviation(j).df=60*obj.LS_deviation(i).deviation(j).ff*(Ysolu3-ym);
                df(j) = ff(j)*(Ysolu3-ym);
            end
        end
    else
        nump = length(obj.LS_deviation(i).deviation);
        ww = [obj.LS_deviation(i).deviation.ww]';
        dw = [obj.LS_deviation(i).deviation.dw]';
        ff = [obj.LS_deviation(i).deviation.ff]';
        df = NaN(size(ff));
        hh = [obj.LS_deviation(i).deviation.hh]';
        dh = [obj.LS_deviation(i).deviation.dh]';
        for j=1:nump
            percent = j/round(nump*1e-2);
            if rem(percent,1)==0
                % mod(100*j/length(obj.LS_deviation(i).deviation),1)<1e-2
                % disp([num2str(100*j/length(obj.LS_deviation(i).deviation)),'%'])
                waitbar(j/nump,fff,['group ',num2str(i),' Processing...',num2str(round(j/nump*1e2),'%05.2f'),'%'])
            end

            % 对于线条数据，查询工艺曲面对工艺参数做调整
            % 如果是需要做启停段补偿的数据，则不做速度调整
            if ~isnan(dw(j))
                AV = ff(j)/FE/k_u;                                    % 速度正规化
                AH = (hh(j)-dh(j))/dd/k_h;  % 高度正规化
                %   ！！！！如果需要修正的话，需要在这里调节
                % AV = AV-a;
                % AH = AH-strand_model.c;
                %   结束
                ASW = (ww(j)-dw(j))/dd; % 线宽正规化
                TSW = ww(j)/dd;                                       % 目标线宽正规化
                ASH = hh(j)/dd;                                       % 目标线高正规化
                %   如果不在实验数据的范围内，则应禁止操作，并跳过该点
                if AV<datainfo.Vmin || AV>datainfo.Vmax || AH<datainfo.Hmin || AH>datainfo.Hmax
                    msg = '不在实验数据的范围内，禁止操作，并跳过该点';
                    warning(msg)
                    %             continue
                    xl2 = linspace(min(datainfo.Hmin,AH),max(datainfo.Hmax,AH),fit_density);
                    yl2 = linspace(min(datainfo.Vmin,AV),max(datainfo.Vmax,AV),fit_density);
                    [XL2,YL2] = meshgrid(xl2,yl2);
                    TXL = XL2;
                    TYL = YL2;
                    TZL = strand_model(XL2,YL2);
                else
                    TXL = XL;
                    TYL = YL;
                    TZL = ZL;
                end
                %   进行线宽的调整
                %   判断实际线宽是否在模型范围内
                if ASW<min(min(TZL)) || ASW>max(max(TZL))
                    % 不在范围内，警告并做调整
                    msg = ['第',num2str(i),'个数据的线宽(',num2str(LJ_processed_data.adjusted_data(i,6)),'mm),不在模型接受范围[',num2str(min(min(TZL))),',',num2str(max(max(TZL))),']内，将其置为模型极值！'];
                    warning(msg)
                    if ASW<min(min(TZL))
                        ASW = min(min(TZL));
                    elseif ASW<max(max(TZL))
                        ASW = max(max(TZL));
                    end
                end
                %   在模型曲面上寻找符合实际线宽的数据点
                Z_sn = find(abs(TZL-ASW)<=1e-3);
                Xsolu = TXL(Z_sn);
                Ysolu = TYL(Z_sn);
                Zsolu = TZL(Z_sn);
                %   绘图
                if flag_plotin==1
                    % figure(6)
                    % plot(strand_model)
                    % xlabel('H/a_0')
                    % ylabel('V/U')
                    % zlabel('W')
                    % hold on
                    % plot3(Xsolu,Ysolu,Zsolu,'r.')
                    % plot3(AH,AV,strand_model(AH,AV),'y.','MarkerSize',50)
                    % hold off
                    % view([0 0 1])
                    set(p2,'XData',AH,'YData',AV,'ZData',strand_model(AH,AV));
                    set(p3,'XData',Xsolu,'YData',Ysolu,'ZData',Zsolu);
                end
                %   找到参数范围内距离实际点最近的点
                %         distv= [Xsolu-ASH,Ysolu-AV,Zsolu-ASW];
                distv= [Xsolu-AH,Ysolu-AV,Zsolu-ASW];
                dist = sqrt(distv(:,1).^2+distv(:,2).^2+distv(:,3).^2);
                distp= find(dist==min(dist));
                xm = Xsolu(distp);
                ym = Ysolu(distp);
                zm = Zsolu(distp);
                %   绘图
                if flag_plotin==1
                    % hold on
                    % plot3(xm,ym,zm,'g.','MarkerSize',50)
                    % hold off
                    set(p4,'XData',xm,'YData',ym,'ZData',zm);
                end
                %   查找目标值对应的曲线
                Z_sn2 = find(abs(TZL-TSW)<=1e-3);
                if isempty(Z_sn2)
                    warning('找不到调整点，舍弃')
                    continue
                end
                Xsolu2 = TXL(Z_sn2);
                Ysolu2 = TYL(Z_sn2);
                Zsolu2 = TZL(Z_sn2);
                %   绘图
                if flag_plotin==1
                    % hold on
                    % plot3(Xsolu2,Ysolu2,Zsolu2,'g.')
                    % hold off
                    set(p5,'XData',Xsolu2,'YData',Ysolu2,'ZData',Zsolu2);
                end
                %   按照只调整UH找到上一步结果中符合结果的点
                distv2=Xsolu2-xm;
                dist2 =abs(distv2);
                distp2=find(dist2 == min(dist2) );
                if length(distp2)>1
                    distp2(2:end)=[];
                end
                Xsolu3 = Xsolu2(distp2);
                Ysolu3 = Ysolu2(distp2);
                Zsolu3 = Zsolu2(distp2);
                %   绘图
                if flag_plotin==1
                    % hold on
                    % plot3(Xsolu3,Ysolu3,Zsolu3,'r.','MarkerSize',50)
                    % quiver3(xm,ym,zm,Xsolu3-xm,Ysolu3-ym,Zsolu3-zm,'r')
                    % hold off
                    % title(['i=',num2str(i),',实际线宽:',num2str(obj.LS_deviation(i).deviation(j).ww-obj.LS_deviation(i).deviation(j).dw),'mm,理想线宽:',num2str(obj.LS_deviation(i).deviation(j).ww),'mm.'])
                    % pause(0.005)
                    set(p6,'XData',Xsolu3,'YData',Ysolu3,'ZData',Zsolu3);
                    set(p7,'XData',xm,'YData',ym,'ZData',zm,'UData',Xsolu3-xm,'VData',Ysolu3-ym,'WData',Zsolu3-zm);
                    title(['num=',num2str(j),',Actual:',num2str(ww(j)-dw(j)),'mm,Target:',num2str(ww(j)),'mm.'])
                    pause(0.005)
                end
                %   把速度的变化量记录下来
                % LJ_processed_data.adjusted_data(i,11) = 60*LJ_processed_data.adjusted_data(i,12)*(Ysolu3-ym);
                % obj.LS_deviation(i).deviation(j).df=60*obj.LS_deviation(i).deviation(j).ff*(Ysolu3-ym);
                df(j) = ff(j)*(Ysolu3-ym);
            end
        end
    end
    %   第一次写入数据
    for j=1:nump
        % 这里计算偏差向量vx vy vz，以及修正后的轨迹cx cy cz、速率调节量df
        obj.LS_deviation(i).deviation(j).vx=obj.LS_deviation(i).deviation(j).dx-obj.LS_deviation(i).deviation(j).x;
        obj.LS_deviation(i).deviation(j).vy=obj.LS_deviation(i).deviation(j).dy-obj.LS_deviation(i).deviation(j).y;
        obj.LS_deviation(i).deviation(j).vz=obj.LS_deviation(i).deviation(j).dz-obj.LS_deviation(i).deviation(j).z;
        obj.LS_deviation(i).deviation(j).cx=obj.LS_deviation(i).deviation(j).x-obj.LS_deviation(i).deviation(j).vx*k;
        obj.LS_deviation(i).deviation(j).cy=obj.LS_deviation(i).deviation(j).y-obj.LS_deviation(i).deviation(j).vy*k;
        obj.LS_deviation(i).deviation(j).cz=obj.LS_deviation(i).deviation(j).z-obj.LS_deviation(i).deviation(j).vz*k;
        obj.LS_deviation(i).deviation(j).df=df(j)*k_u;
    end

    %   延迟数据处理
    sn=1;
    % curve_cps   = [];
    % draft_gcode = [];
    % temp_curve_fitting = struct('curve_model',[]);
    flag_dwell  = 0;
    p_on        = 106;
    p_off       = 107;
    %   然后，拟合并提取控制点，保存在curve_cps中
    %列数: 1       2       3       4       5       6       7       8       9
    %解释: P1_x    P1_y    P2_x    P2_y    P3_x    P3_y    P4_x    P4_y    group
    %列数: 10      11      12      13
    %解释: F_1     F_2     P1_z    P4_z
    %   读取第i组的数据
    ssn = [obj.LS_deviation(i).deviation.ssn]';
    x   = [obj.LS_deviation(i).deviation.cx]';
    y   = [obj.LS_deviation(i).deviation.cy]';
    z   = [obj.LS_deviation(i).deviation.cz]';
    vx  = [obj.LS_deviation(i).deviation.vx]';
    vy  = [obj.LS_deviation(i).deviation.vy]';
    vz  = [obj.LS_deviation(i).deviation.vz]';
    for j=1:length(x)
        if isnan(x(j)); x(j)=obj.LS_deviation(i).deviation(j).x; end
        if isnan(y(j)); y(j)=obj.LS_deviation(i).deviation(j).y; end
        if isnan(z(j)); z(j)=obj.LS_deviation(i).deviation(j).z; end
    end
    act = ~isnan([obj.LS_deviation(i).deviation.dx]');
    f0  = [obj.LS_deviation(i).deviation.ff]';
    f1  = [obj.LS_deviation(i).deviation.ff]'+[obj.LS_deviation(i).deviation.df]';
    sw  = [obj.LS_deviation(i).deviation.ww]';
    %   计算第i组是否有延迟
    temp_dwell  = find(isnan([obj.LS_deviation(i).deviation.df]'));
    %   如果有延迟，则计算一下需要停留的时间
    temp_t = [];
    if ~isempty(temp_dwell)
        %   先找到第一组延迟，剔除杂点
        temp_label  = dbscan(temp_dwell,1,1);
        temp_dwell(temp_label~=1)=[];
        %   二次判断
        if ~isempty(temp_dwell)
            flag_dwell = 1;
            %   先把坐标点和速度找到
            temp_x = x;
            temp_y = y;
            temp_z = z;
            temp_vx= vx;
            temp_vy= vy;
            temp_vz= vz;
            temp_f = f0;
            temp_f2= f1;
            p = spaps(find(~isnan(f1)),f1(~isnan(f1)),1e4);
            temp_f2(~isnan(f1))= fnval(p,find(~isnan(f1)));
            temp_sw= sw;
            %   这里通过均值滤波，找到加速完成的节点，然后该节点之前的部分平移到起点，中间的部分做一下填充
            pericent = 2;
            num_filt = round(pericent*1e-2*length(obj.LS_deviation(i).deviation)); % 取n个点求均值
            test_temp = NaN(length(temp_f2)-num_filt,1);
            for j = 1:length(temp_f2)-num_filt
                test_temp(j) = temp_f2(j+round(num_filt/2),1)-mean(temp_f2(j:j+num_filt,1));
            end
            %   做个简单的测试
            if flag_delay ==1
                figure(2)
                subplot(3,1,1)
                plot(temp_f2)
                subplot(3,1,2)
                plot(test_temp)
                subplot(3,1,3)
                % semilogy(abs(test_temp))
                plot(diff(test_temp))
            end
            %   计算偏移量，并作置换
            % slide = find(log10(test_temp)<=1,1,'First');
            slide = find(abs(test_temp(1:end-1))<=1e-3 & diff(test_temp)>0,1,"first");
            temp_f0 = temp_f(temp_dwell);
            temp_f2(1:slide-temp_dwell(end))=temp_f2(temp_dwell(end)+1:slide);
            temp_f2(slide-temp_dwell(end)+1:slide)=mean(temp_f2([slide-temp_dwell(end),slide]));
            %   轨迹也需要做相应的调整
            temp_vx(1:slide-temp_dwell(end))=temp_vx(temp_dwell(end)+1:slide);
            temp_vx(slide-temp_dwell(end)+1:slide)=mean(temp_vx([slide-temp_dwell(end),slide]));
            temp_vy(1:slide-temp_dwell(end))=temp_vy(temp_dwell(end)+1:slide);
            temp_vy(slide-temp_dwell(end)+1:slide)=mean(temp_vy([slide-temp_dwell(end),slide]));
            temp_vz(1:slide-temp_dwell(end))=temp_vz(temp_dwell(end)+1:slide);
            temp_vz(slide-temp_dwell(end)+1:slide)=mean(temp_vz([slide-temp_dwell(end),slide]));
            % 保存新的cx xy cz
            for j=1:slide
                obj.LS_deviation(i).deviation(j).cx=obj.LS_deviation(i).deviation(j).x-temp_vx(j);
                obj.LS_deviation(i).deviation(j).cy=obj.LS_deviation(i).deviation(j).y-temp_vy(j);
                obj.LS_deviation(i).deviation(j).cz=obj.LS_deviation(i).deviation(j).z-temp_vz(j);
            end
            % for j=slide-temp_dwell(end)+1:slide
            % 
            % end
            %   然后计算延迟区经历的时间
            temp_xx = temp_x(temp_dwell);
            temp_yy = temp_y(temp_dwell);
            temp_zz = temp_z(temp_dwell);
            temp_ff = temp_f(temp_dwell);
            temp_t = sum( ...
                ( ...
                (temp_xx(2:end)-temp_xx(1:end-1)).^2+ ...
                (temp_yy(2:end)-temp_yy(1:end-1)).^2+ ...
                (temp_zz(2:end)-temp_zz(1:end-1)).^2 ...
                ).^0.5.* ...
                60.*1000./temp_ff(2:end) ...
                ); %ms
        end
    end
    % 保存延迟数据
    obj.LS_deviation(i).time_delay=temp_t;
    for j=1:length(obj.LS_deviation(i).deviation)
        obj.LS_deviation(i).deviation(j).f2=temp_f2(j);
    end
    
    % 拟合并保存修正轨迹
    % tt = [obj.LS_deviation(i).deviation.t]';
    tt = [obj.LS_deviation(i).deviation.ssn]';
    xx = [obj.LS_deviation(i).deviation.cx]';
    yy = [obj.LS_deviation(i).deviation.cy]';
    zz = [obj.LS_deviation(i).deviation.cz]';
    obj.LS_deviation(i).X_Curve.sp = spaps(tt,xx,1);
    obj.LS_deviation(i).Y_Curve.sp = spaps(tt,yy,1);
    obj.LS_deviation(i).Z_Curve.sp = spaps(tt,zz,1);

    % 计算总路程，用于计算挤出量
    xyz = [[obj.LS_deviation(i).deviation.cx]',[obj.LS_deviation(i).deviation.cy]',[obj.LS_deviation(i).deviation.cy]'];
    ss = vecnorm((xyz(2:end,:)-xyz(1:end-1,:))',2)';
    obj.LS_deviation(i).deviation(1).ss=0;
    for j=2:length(obj.LS_deviation(i).deviation)
        obj.LS_deviation(i).deviation(j).ss=ss(j-1);
    end
    
    %   绘图
    if flag_plot==1
        f6=figure(5);
        set(f6,"Units",'pixels',"Position",[1 1 6 4]*96)
        plot(   [obj.LS_deviation(i).deviation.x]' ,[obj.LS_deviation(i).deviation.y]' ,'k--',...
                [obj.LS_deviation(i).deviation.dx]',[obj.LS_deviation(i).deviation.dy]','r.',...
                [obj.LS_deviation(i).deviation.cx]',[obj.LS_deviation(i).deviation.cy]','b-');          
        title('Trajectory Compensation')
        xlabel('X [mm]');
        ylabel('Y [mm]');
        legend({'Original','Actual','Compensated'})
        set(gca,'FontName','Times New Roman')
        grid on

        %   保存绘图
        saveas(f6,[obj.syset.path_outfig,'LS_trj_modifig_1_group_',num2str(i)]);
        saveas(f6,[obj.syset.path_outfig,'LS_trj_modifig_1_group_',num2str(i),'.emf']);
        saveas(f6,[obj.syset.path_outfig,'LS_trj_modifig_1_group_',num2str(i),'.jpg']);
    end
end

if flag_parfor==1
    % 关闭并行池
    delete(gcp);
else
    close(fff)
end
%%  结束与标记
obj.syset.flags.flag_adjusted_traj = 1;
end