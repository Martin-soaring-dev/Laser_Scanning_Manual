function obj = LS_deviation_calculation(obj,varargin)
%%  依赖关系判断
if obj.syset.flags.read_flag_profileansy~=1
    error('profile extraction has not been processed yet!')
end
%%  default values
default_flag_plot = 1;      % 是否绘图
default_w         = 01.20;  % 线宽
default_h         = 00.60;  % 线高
default_w_set_flag= 0;      % 是否设置线宽
default_h_set_flag= 0;      % 是否设置线高
default_temp_mode = 2;      % 拟合模式 1:插值 2:插补
%   声明一个p为inputParser格式的。其实也可以理解为一个该格式的句柄一样的东西
IP = inputParser;
addRequired(IP,'obj');
%   接下来两个是可选参数，名字分别为’stepsize'和'OptimalityTolerance'，如果没有检测到输入将有相应的缺省值defaulth和epsilon。这些都在函数开头声明好了
addParameter(IP,'flag_plot',default_flag_plot);
addParameter(IP,'w',default_w);
addParameter(IP,'h',default_h);
addParameter(IP,'w_set_flag',default_w_set_flag);
addParameter(IP,'h_set_flag',default_h_set_flag);
addParameter(IP,'temp_mode',default_temp_mode);
%   利用parse函数将输入参数与上面的进行匹配
parse(IP,obj,varargin{:});
%   此时就已经生成好了一个inputParser格式的参数p，p里面含有不少东西，其中它的Results为一个结构体，是输入参数在匹配后的值，利用这个可以完成我的output的赋值
flag_plot = IP.Results.flag_plot;
w = IP.Results.w;
h = IP.Results.h;
w_set_flag = IP.Results.w_set_flag;
h_set_flag = IP.Results.h_set_flag;
temp_mode  = IP.Results.temp_mode;
%%  处理程序
temp_tj = obj.TJ_data.TJ4PT;
temp_pf = obj.LS_profile;
temp_pt = [obj.Surface.traj_comp.path];
deviation = struct;
%   读取组别-实际
actua_group = [obj.LS_profile.group]';
actua_group_list = unique(actua_group);
actua_group_list = actua_group_list(actua_group_list>0);
%   读取组别-理想
ideal_group = temp_tj(:,14);
ideal_group_list = unique(ideal_group);
ideal_group_list = ideal_group_list(ideal_group_list>0);
%   组数判断
if ideal_group_list~=actua_group_list
    error('理想与实际组别数量不一致，请检查！')
end
%   轨迹数据初始化
ideal_trajectory = struct;
actua_trajectory = struct;
num=1;
for i=1:length(ideal_group_list)
    %   读取轨迹-实际
    temp_sn = find(actua_group==actua_group_list(i));
    for j=1:length(temp_sn)
        actua_trajectory(i).data(j).sn = temp_pf(temp_sn(j)).sn;
        actua_trajectory(i).data(j).ssn= temp_pf(temp_sn(j)).seria;
        actua_trajectory(i).data(j).gp = temp_pf(temp_sn(j)).group;
        actua_trajectory(i).data(j).x  = temp_pf(temp_sn(j)).x;
        actua_trajectory(i).data(j).y  = temp_pf(temp_sn(j)).y;
        actua_trajectory(i).data(j).z  = temp_pf(temp_sn(j)).sh;
        actua_trajectory(i).data(j).act= temp_pf(temp_sn(j)).act;
        if temp_pf(temp_sn(j)).act~=1
            actua_trajectory(i).data(j).gp=0;
        end
        actua_trajectory(i).data(j).ss = temp_pf(temp_sn(j)).ss;
        actua_trajectory(i).data(j).sw = temp_pf(temp_sn(j)).sw;
        actua_trajectory(i).data(j).sh = temp_pf(temp_sn(j)).sh;
        actua_trajectory(i).data(j).ff = obj.Devinfo.trajectory.feed_rate(2);
    end
    %   读取轨迹-理想
    temp_sn = find(ideal_group==ideal_group_list(i));
    %   对理想点进行插值密化
    %   (1) 读取点位数据
    x1=temp_pt(temp_sn,1);
    y1=temp_pt(temp_sn,2);
    z1=ones(size(x1))*obj.TJ_data.TJ4ZZ;
    x2=[actua_trajectory(i).data.x]';
    y2=[actua_trajectory(i).data.y]';
    z2=[actua_trajectory(i).data.z]';
    a2=[actua_trajectory(i).data.act]';
    sw=[actua_trajectory(i).data.sw]';
    sh=[actua_trajectory(i).data.sh]';
    temp_ideal_points = [x1,y1,z1,ones(size(x1))];                          % 读取第i组的理想点
    temp_t            = linspace(0,1,size(temp_ideal_points,1));            % 构造参数temp_t
    temp_actua_points = [x2,y2,z2,a2];                                      % 读取第i组的实际点
    %   (2) 线性插补中间点，作为理想点
    t = linspace(0,1,round(size(temp_actua_points,1)*1e-2)*1e4);            % 按实际点数量100倍进行插值
    temp_x = interp1(temp_t,temp_ideal_points(:,1),t)';
    temp_y = interp1(temp_t,temp_ideal_points(:,2),t)';
    temp_z = interp1(temp_t,temp_ideal_points(:,3),t)';
    %   理想线宽线高，如果未指定，则计算均值
    if w_set_flag~=1
        w=mean(sw);
    end
    if h_set_flag~=1
        h=mean(sh);
    end
    for j=1:length(temp_x)
        ideal_trajectory(i).data(j).sn = num; num=num+1;
        ideal_trajectory(i).data(j).ssn= j;
        ideal_trajectory(i).data(j).gp = ideal_group_list(i);
        ideal_trajectory(i).data(j).t  = t(j);
        ideal_trajectory(i).data(j).x  = temp_x(j);
        ideal_trajectory(i).data(j).y  = temp_y(j);
        ideal_trajectory(i).data(j).z  = temp_z(j);
        % ideal_trajectory(i).data(j).z  = obj.TJ_data.TJ4ZZ;
        ideal_trajectory(i).data(j).dx = NaN;
        ideal_trajectory(i).data(j).dy = NaN;
        ideal_trajectory(i).data(j).dz = NaN;
        ideal_trajectory(i).data(j).dd = NaN;
        ideal_trajectory(i).data(j).ff = obj.Devinfo.trajectory.feed_rate(2);
        ideal_trajectory(i).data(j).w  = w;
        ideal_trajectory(i).data(j).h  = h;
        ideal_trajectory(i).data(j).dw = NaN;
        ideal_trajectory(i).data(j).dh = NaN;
    end
    ideal_trajectory(i).transaction    = [obj.Surface.traj_comp.trans];
end
%   初始化
rmin = 0;
rmax = 1;
rstep= 1e-2;
%   通过判断，这时按组数进行循环
for i=1:length(ideal_group_list)
    current_group = ideal_group_list(i); %当前组数
    % current_ideal = find(ideal_group==current_group); %当前理想点序列
    % current_actua = find(actua_group==current_group); %当前实际点序列
    x1=[ideal_trajectory(i).data.x]';
    y1=[ideal_trajectory(i).data.y]';
    z1=[ideal_trajectory(i).data.z]';
    x2=[actua_trajectory(i).data.x]';
    y2=[actua_trajectory(i).data.y]';
    z2=[actua_trajectory(i).data.z]';
    a2=[actua_trajectory(i).data.act]';
    sw=[actua_trajectory(i).data.sw]';
    sh=[actua_trajectory(i).data.sh]';
    ff=[actua_trajectory(i).data.ff]';
    ideal_points=[x1,y1,z1,ones(size(x1))];
    actua_points=[x2,y2,z2,a2];
    %   绘图
    if flag_plot==1
        f1=figure(1);
        plot(x1,y1,'k-',x2,y2,'r.')
        switch i
            case 1
                hold on
            case length(ideal_group_list)
                hold off
        end
    end
    % %   保存
    % obj.LS_deviation(i).ideal_point=[temp_x,temp_y,temp_z,ones(size(temp_x))];
    % obj.LS_deviation(i).actua_point=[x2,y2,z2,a2,sw,sh,ff];
    %   计算对应点
    %   中间标量tempe的说明：
    %       1   x
    %       2   y
    %       3   z
    %       4   dx
    %       5   dy
    %       6   dz
    %       7   序列(理想点)
    %       8   distance
    %       9   sw
    %       10  sh
    for j =1:length(a2)
        if a2(j)==1
        tempe = actua_points(j,1:3);
        distv = tempe-ideal_points(:,1:3);
        distv(:,3)=0;   %   这里先把dz强行规定为0，以后有需要再改
        dists = vecnorm(distv',2)';
        % sqrt(distv(:,1).^2+distv(:,2).^2+distv(:,3).^2);
        %   计算并保存距离数据点最近的理论点的位置
        mindn = find(dists==min(dists),1,"first");
        % if length(mindn)>1
        %     mindn = mindn(1);
        % end
        tempe(4:6)=distv(mindn,1:3);                                        %4-6列保存偏差向量
        tempe(7) = mindn;                                                   %7列保存序列
        %   保存距离数值
        mindis= dists(tempe(end));                                          
        %   如果误差太大，则需要舍弃，否则会错误
        if mindis>rmax
            continue
        end
        tempe(8) = mindis;                                                  %8列保存距离
        %   保存线宽线高
        tempe(9) = sw(j);                                                   %9列保存线宽
        tempe(10) =sh(j);                                                   %10列保存线高
        % %   接下来要做一些组别判断，如果不是同一组的，则需要舍弃
        % %         if tempe(7)~=Pthe(tempe(8),5)
        % %             continue
        % %         end
        % Pexp(8,i)=tempe(8);
        % Pexp(9,i)=tempe(9);
        %   如果是NaN可以写入，如果已经写入，但是写入的误差比现在计算的小，也可以写入，反之则不写入，进入下一轮循环
        EV = ideal_trajectory(i).data(tempe(7)).dd;
        if ~isnan(EV)
            if EV>=tempe(8)
                continue
            end
        end
        ideal_trajectory(i).data(tempe(7)).dx = tempe(4);
        ideal_trajectory(i).data(tempe(7)).dy = tempe(5);
        ideal_trajectory(i).data(tempe(7)).dz = tempe(6);
        ideal_trajectory(i).data(tempe(7)).dd = tempe(8);
        ideal_trajectory(i).data(tempe(7)).dw = ideal_trajectory(i).data(tempe(7)).w-tempe(9);
        ideal_trajectory(i).data(tempe(7)).dh = ideal_trajectory(i).data(tempe(7)).h-tempe(10);
        end
    end
    %   现在已经找到了每个实际点对应的理想点，并把误差等信息附在理想点数据上
    %   现在需要对理想点数据做处理，使得其尺度与实际点一致
    %   这里就需要使用插值。
    flag_nan = isnan([ideal_trajectory(i).data.dx])|isnan([ideal_trajectory(i).data.dy])|isnan([ideal_trajectory(i).data.dz]);
    nan_sn_0 = find(flag_nan)';
    nan_sn_1 = find(~flag_nan)';    
    nan_sn_1st=find(~isnan([ideal_trajectory(i).data.dx]),1,"first");
    nan_sn_end=find(~isnan([ideal_trajectory(i).data.dx]),1,"last");

    sn3 = [ideal_trajectory(i).data.sn]';
    ssn3= [ideal_trajectory(i).data.ssn]';
    gp3 = [ideal_trajectory(i).data.gp]';
    t3  = [ideal_trajectory(i).data.t]';
    x3  = [ideal_trajectory(i).data.x]';
    y3  = [ideal_trajectory(i).data.y]';
    z3  = [ideal_trajectory(i).data.z]';
    dx3 = [ideal_trajectory(i).data.dx]';
    dy3 = [ideal_trajectory(i).data.dy]';
    dz3 = [ideal_trajectory(i).data.dz]';
    dd3 = [ideal_trajectory(i).data.dd]';
    ff3 = [ideal_trajectory(i).data.ff]';
    w3 = [ideal_trajectory(i).data.w]';
    h3 = [ideal_trajectory(i).data.h]';
    dw3 = [ideal_trajectory(i).data.dw]';
    dh3 = [ideal_trajectory(i).data.dh]';

    % 变量初始化
    t4  = t3(nan_sn_1st:nan_sn_end); 
    sn4 = sn3; 
    ssn4= ssn3; 
    gp4 = gp3;
    dx4 = dx3; 
    dy4 = dy3; 
    dz4 = dz3; 
    dd4 = sqrt(dx4.^2+dy4.^2+dz4.^2); 
    dw4 = dw3; 
    dh4 = dh3;

    % temp_mode=2;
    switch temp_mode
        case 1
            dx4(nan_sn_1st:nan_sn_end) = interp1(t3,x3+dx3,t4,"spline")-x3(nan_sn_1st:nan_sn_end);
            dy4(nan_sn_1st:nan_sn_end) = interp1(t3,y3+dy3,t4,"spline")-y3(nan_sn_1st:nan_sn_end);
            dz4(nan_sn_1st:nan_sn_end) = interp1(t3,z3+dz3,t4,"spline")-z3(nan_sn_1st:nan_sn_end);
            dw4(nan_sn_1st:nan_sn_end) = interp1(t3,dw3,t4,"spline"); %dw4=dw4(nan_sn_1st:nan_sn_end);
            dh4(nan_sn_1st:nan_sn_end) = interp1(t3,dh3,t4,"spline"); %dh4=dh4(nan_sn_1st:nan_sn_end);
        case 2
            p=1-1e-4;
            % p=1-1e-20;
            pp=csaps(t3,x3+dx3,p); ff=fittype('smoothingspline'); cf=cfit(ff,pp); dx4(nan_sn_1st:nan_sn_end)=feval(cf,t4);
            pp=csaps(t3,y3+dy3,p); ff=fittype('smoothingspline'); cf=cfit(ff,pp); dy4(nan_sn_1st:nan_sn_end)=feval(cf,t4);
            pp=csaps(t3,z3+dz3,p); ff=fittype('smoothingspline'); cf=cfit(ff,pp); dz4(nan_sn_1st:nan_sn_end)=feval(cf,t4);
            p=1-1e-6;
            pp=csaps(t3,dw3,p); ff=fittype('smoothingspline'); cf=cfit(ff,pp); dw4(nan_sn_1st:nan_sn_end)=feval(cf,t4);
            pp=csaps(t3,dh3,p); ff=fittype('smoothingspline'); cf=cfit(ff,pp); dh4(nan_sn_1st:nan_sn_end)=feval(cf,t4);
        case 3
            p=1e-2;
            pp=spaps(t3,x3+dx3,p); dx4(nan_sn_1st:nan_sn_end)=fnval(pp,t4);
            pp=spaps(t3,y3+dy3,p); dy4(nan_sn_1st:nan_sn_end)=fnval(pp,t4);
            pp=spaps(t3,z3+dz3,p); dz4(nan_sn_1st:nan_sn_end)=fnval(pp,t4);
            p=1e-5;
            pp=spaps(t3,dw3,p); dw4(nan_sn_1st:nan_sn_end)=fnval(pp,t4);
            pp=spaps(t3,dh3,p); dh4(nan_sn_1st:nan_sn_end)=fnval(pp,t4);
    end
    %   保存误差
    for j=1:length(t4)
        deviation(i).data(j).sn = sn4(j);
        deviation(i).data(j).ssn= ssn4(j);
        deviation(i).data(j).gp = gp4(j);
        deviation(i).data(j).t  = t4(j);
        deviation(i).data(j).x  = x3(j);
        deviation(i).data(j).y  = y3(j);
        deviation(i).data(j).z  = z3(j);
        deviation(i).data(j).dx = dx4(j);
        deviation(i).data(j).dy = dy4(j);
        deviation(i).data(j).dz = dz4(j);
        deviation(i).data(j).dd = dd4(j);
        deviation(i).data(j).ff = ff3(j);
        deviation(i).data(j).ww = w3(j);
        deviation(i).data(j).dw = dw4(j);
        deviation(i).data(j).hh = h3(j);
        deviation(i).data(j).dh = dh4(j);
    end

    %t4=t4(nan_sn_1st:nan_sn_end);
    if flag_plot==1
        f2=figure(2);
        set(f2,"Units",'pixels',"Position",[0 1 6 8]*96)
        a = subplot(3,1,1);
        % scatter3(x3,y3,z3,10,dd3,"filled");
        % hold on
        % % plot3(x3+dx3,y3+dy3,z3+dz3,'r.');
        % % quiver3(x3,y3,z3,dx3,dy3,dz3);
        % hold off
        % view([0 0 1])
        % % axis equal
        % subplot(2,2,2)
        % scatter3(x3,y3,z3,10,dd4,"filled");
        scatter(x3,y3,10,dd4,"filled");
        hold on
        % plot3(x3+dx4,y3+dy4,z3+dz4,'r.');
        % plot3(x3+dx4,y3+dy4,'r.');
        plot(x1,y1,'r--')
        % quiver3(x3,y3,z3,dx4,dy4,dz4,"off");
        % quiver(x3,y3,dx4,dy4,"off");
        hold off
        view([0 0 1])
        title('Trajectory Error')
        grid on
        xlabel('X [mm]');
        ylabel('Y [mm]');
        set(gca,'FontName','Times New Roman')
        c=colorbar("eastoutside");
        % set(a,'CLim',[0 0.5]); %可以通过这两行来强行设定色阶范围，方便出图
        % set(c,"Limits",[0,0.5]);
        axis equal

        a=subplot(3,1,2);
        % plot(t3,dw3,'b.',t3,dh3,'r.')
        % plot(t3,w3-dw4)
        scatter3(x3,y3,z3,10,abs(dw4),"filled");
        hold on
        plot(x1,y1,'r--')
        hold off
        title('Strand Width error')
        xlabel('X [mm]');
        ylabel('Y [mm]');
        set(gca,'FontName','Times New Roman')
        set(a,'CLim',[0 0.5]);
        colorbar("eastoutside","Limits",[0,0.5])
        view([0 0 1])
        axis equal

        a=subplot(3,1,3);
        % plot(t3,dw4,t3,dh4)
        % plot(x3,h3-dh4)
        scatter3(x3,y3,z3,10,abs(dh4),"filled")
        hold on
        plot(x1,y1,'r--')
        hold off
        title('Strand Height error')
        xlabel('X [mm]');
        ylabel('Y [mm]');
        set(gca,'FontName','Times New Roman')
        set(a,'CLim',[0 0.5]);
        colorbar("eastoutside","Limits",[0,0.5])
        view([0 0 1])
        axis equal

        f3=figure(3);
        set(f3,"Units",'pixels',"Position",[6 1 6 8]*96)
        a = subplot(3,1,1);
        % scatter3(x3,y3,z3,10,dd3,"filled");
        % hold on
        % % plot3(x3+dx3,y3+dy3,z3+dz3,'r.');
        % % quiver3(x3,y3,z3,dx3,dy3,dz3);
        % hold off
        % view([0 0 1])
        % % axis equal
        % subplot(2,2,2)
        % scatter3(x3,y3,z3,10,dd4,"filled");
        % scatter(x3,y3,10,dd4,"filled");
        edge=[obj.LS_Vox(i).edge];
        temp=[obj.PC_data_merged.Merged_PC.X];
        temp=temp(temp(:,1)>=edge(1)&temp(:,1)<=edge(2)&temp(:,2)>=edge(3)&temp(:,2)<=edge(4),:);
        % temp_offset = [0 -0.5 0 0 0 0];
        temp_offset = [0 0 0 0 0 0];
        temp=(trans_matrix(temp_offset,1)*[temp,ones(size(temp,1),1)]')'; temp(:,4)=[];   %这里进行了一点变换，可以手动修改
        scatter(temp(:,1),temp(:,2),10,temp(:,3)-min(temp(:,3)),"filled")
        hold on
        % plot3(x3+dx4,y3+dy4,z3+dz4,'r.');
        % plot3(x3+dx4,y3+dy4,'r.');
        plot(x1,y1,'g-')
        plot(x2,y2,'r.');
        % quiver3(x3,y3,z3,dx4,dy4,dz4,"off");
        % quiver(x3,y3,dx4,dy4,"off");
        hold off
        % view([0 0 1])
        title('Trajectory')
        grid on
        xlabel('X [mm]');
        ylabel('Y [mm]');
        set(gca,'FontName','Times New Roman')
        legend({'','target','actual'})
        % c=colorbar("eastoutside");
        % set(a,'CLim',[0 0.7]);
        % set(c,"Limits",[0,0.7]);
        axis equal

        a=subplot(3,1,2);
        % plot(t3,dw3,'b.',t3,dh3,'r.')
        % plot(t3,w3-dw4)
        % scatter3(x3,y3,z3,10,abs(dw4),"filled");
        % plot(x3,w-dw3-0.15*linspace(0,1,length(x3))'+0.2,'k.');
        % plot(x3,w-dw3,'k.');
        plot(x3(ssn4),w-dw4(ssn4),'k.');
        % hold on
        % plot(x1,y1,'r--')
        % hold off
        title('Strand Width')
        xlabel('X [mm]');
        ylabel('W [mm]');
        set(gca,'FontName','Times New Roman')
        grid on
        % set(a,'CLim',[0 0.5]);
        % colorbar("eastoutside","Limits",[0,0.5])
        % view([0 0 1])
        % axis equal

        a=subplot(3,1,3);
        % plot(t3,dw4,t3,dh4)
        % plot(x3,h3-dh4)
        % scatter3(x3,y3,z3,10,abs(dh4),"filled")
        % plot(x3,h-dh3,'k.');
        plot(x3(ssn4),h-dh4(ssn4),'k.');
        % hold on
        % plot(x1,y1,'r--')
        % hold off
        title('Strand Height')
        xlabel('X [mm]');
        ylabel('H [mm]');
        set(gca,'FontName','Times New Roman')
        grid on
        % set(a,'CLim',[0 0.5]);
        % colorbar("eastoutside","Limits",[0,0.5])
        % view([0 0 1])
        % axis equal
        disp(['w=',num2str(w)]);
        disp(['h=',num2str(h)]);

        f4=figure(4);
        set(f4,"Units",'pixels',"Position",[12 1 6 8]*96)
        
        a = subplot(3,1,1);
        plot(x3(ssn4),dd4(ssn4),'k.');
        title('Trajectory error')
        xlabel('X [mm]');
        ylabel('W [mm]');
        set(gca,'FontName','Times New Roman')
        grid on
        % axis equal

        a=subplot(3,1,2);
        % plot(t3,dw3,'b.',t3,dh3,'r.')
        % plot(t3,w3-dw4)
        % scatter3(x3,y3,z3,10,abs(dw4),"filled");
        % plot(x3,w-dw3-0.15*linspace(0,1,length(x3))'+0.2,'k.');
        plot(x3,w-dw3,'k.');
        hold on
        plot(x3(ssn4),w-dw4(ssn4),'r--');
        % plot(x1,y1,'r--')
        hold off
        title('Strand Width')
        xlabel('X [mm]');
        ylabel('W [mm]');
        set(gca,'FontName','Times New Roman')
        grid on
        % set(a,'CLim',[0 0.5]);
        % colorbar("eastoutside","Limits",[0,0.5])
        % view([0 0 1])
        % axis equal

        a=subplot(3,1,3);
        % plot(t3,dw4,t3,dh4)
        % plot(x3,h3-dh4)
        % scatter3(x3,y3,z3,10,abs(dh4),"filled")
        plot(x3,h-dh3,'k.');
        hold on
        plot(x3(ssn4),h-dh4(ssn4),'r--');
        % plot(x1,y1,'r--')
        hold off
        title('Strand Height')
        xlabel('X [mm]');
        ylabel('H [mm]');
        set(gca,'FontName','Times New Roman')
        grid on
        % set(a,'CLim',[0 0.5]);
        % colorbar("eastoutside","Limits",[0,0.5])
        % view([0 0 1])
        % axis equal
        disp(['w=',num2str(w)]);
        disp(['h=',num2str(h)]);

        close(f1);
        f1=figure(1);
        subplot(1,2,1)
        plot(x3+dx3,y3+dy3,'k.',dx4,dy4,'r.')
        grid on
        subplot(1,2,2)
        plot(t3,dx4,'r.',t3,dy4,'b.')
        grid on
        set(gca,'FontName','Times New Roman')
        
        %   存图
        saveas(f2,[obj.syset.path_outfig,'LS_deviation_fig1_group_',num2str(i)]);
        saveas(f2,[obj.syset.path_outfig,'LS_deviation_fig1_group_',num2str(i),'.emf']);
        saveas(f2,[obj.syset.path_outfig,'LS_deviation_fig1_group_',num2str(i),'.png']);
        saveas(f3,[obj.syset.path_outfig,'LS_deviation_fig2_group_',num2str(i)]);
        saveas(f3,[obj.syset.path_outfig,'LS_deviation_fig2_group_',num2str(i),'.emf']);
        saveas(f3,[obj.syset.path_outfig,'LS_deviation_fig2_group_',num2str(i),'.png']);
        saveas(f4,[obj.syset.path_outfig,'LS_deviation_fig3_group_',num2str(i)]);
        saveas(f4,[obj.syset.path_outfig,'LS_deviation_fig3_group_',num2str(i),'.emf']);
        saveas(f4,[obj.syset.path_outfig,'LS_deviation_fig3_group_',num2str(i),'.png']);
    end
    %   保存
    obj.LS_deviation(i).actua_trajectory=actua_trajectory(i).data;
    obj.LS_deviation(i).ideal_trajectory=ideal_trajectory(i).data;
    obj.LS_deviation(i).deviation=deviation(i).data;
    obj.LS_deviation(i).transaction=ideal_trajectory(i).transaction;
end
%%  绘图
% plot(ideal_trajectory(:,1),ideal_trajectory(:,2),'k-',actua_trajectory(:,1),actua_trajectory(:,2),'r.')
%%  结束与标记
obj.syset.flags.cacu_flag_deviation = 1;
end