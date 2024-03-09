function obj = LS_profile_extruction(obj,varargin)
%   Description
%   obj = LS_profile_extruction(obj)                -   extract profile
%   obj = LS_profile_extruction(obj,'save_flag',1)  -   extract and save
%%  依赖关系判断
if obj.syset.flags.read_flag_sdgrou~=1
    error('skeleton_extraction has not been processed yet!')
end
%%  default values
default_save_flag = 0;
default_ver = 2;            % 曲线离散化计算模式选择
default_fit_mode = 1;       % % 拟合模式，1.直接拟合y=f(x) 2.参数化拟合x=f(t),y=f(t)
%   声明一个p为inputParser格式的。其实也可以理解为一个该格式的句柄一样的东西
IP = inputParser;
addRequired(IP,'obj');
%   接下来两个是可选参数，名字分别为’stepsize'和'OptimalityTolerance'，如果没有检测到输入将有相应的缺省值defaulth和epsilon。这些都在函数开头声明好了
addParameter(IP,'save_flag',default_save_flag);
addParameter(IP,'ver',default_ver);
addParameter(IP,'fit_mode',default_fit_mode);
%   利用parse函数将输入参数与上面的进行匹配
parse(IP,obj,varargin{:});
%   此时就已经生成好了一个inputParser格式的参数p，p里面含有不少东西，其中它的Results为一个结构体，是输入参数在匹配后的值，利用这个可以完成我的output的赋值
save_flag = IP.Results.save_flag;
ver = IP.Results.ver;
fit_mode = IP.Results.fit_mode;
%%  处理程序
test  = 0;
debug = 0;
factor= 1.2;
%   基本思路：
%   (1)读取分组信息；(2)获取线条中心线法矢量，生成法平面方程fn；(3)求法平面与线条方程的交线c，取c中大于zreg的部分作为线条截面
%   然后再在截面分析中：
%   (1)分析截面宽度高度即可。
c = obj.Devinfo.inplt;
m= 1;
s= 0;
previousposition=[0 0 0];
current_position=[0 0 0];
ts=0;
for i=1:length(obj.LS_Vox) % 对每一组线条
    switch fit_mode
        case 1
            curve = obj.LS_Vox(i).curve;    % 读取线条轨迹
            cfunc = curve.curve_model;      % 读取轨迹函数
        case 2
            curvex= obj.LS_Vox(i).curve_x;  % 读取线条轨迹
            curvey= obj.LS_Vox(i).curve_y;  % 读取线条轨迹
            xfunc = curvex.curve_model;     % 读取轨迹函数
            yfunc = curvey.curve_model;     % 读取轨迹函数
    end
    edge  = obj.LS_Vox(i).edge;     % 读取曲面边界
    ssurf = obj.LS_Vox(i).function; % 读取曲面函数
    zreg  = obj.PC_data_merged.group_data.reg;
    % ver = 1; %曲线离散化计算
    switch ver
        case 1 % X方向离散
            switch fit_mode
                case 1
                    xcurve = (curve.controlpoints(1,1):c*curve.curve_dir:curve.controlpoints(end,7))';
                    ycurve = cfunc(xcurve);
                    scurve = [0;vecnorm([xcurve(2:end)-xcurve(1:end-1),ycurve(2:end)-ycurve(1:end-1)]',2)'];
                case 2
                    tcurve=0:c*1e-3:1;
                    xcurve = xfunc(tcurve);
                    ycurve = yfunc(tcurve);
                    scurve = [0;vecnorm([xcurve(2:end)-xcurve(1:end-1),ycurve(2:end)-ycurve(1:end-1)]',2)'];
            end
        case 2 % 路径方向离散
            switch fit_mode
                case 1
                    xcurve=curve.controlpoints(1,1);
                    ycurve=cfunc(curve.controlpoints(1,1));
                    scurve=0;
                    num=1;
                    while 1
                        tempx = (xcurve(num):c*1e-2*curve.curve_dir:curve.controlpoints(end,7))';
                        sn = find(vecnorm(([tempx-xcurve(num),cfunc(tempx)-cfunc(xcurve(num))])',2)-c>=0,1,"first");
                        if isempty(sn)
                            distance = norm((xcurve(num)-curve.controlpoints(end,7)),(cfunc(xcurve(num))-cfunc(curve.controlpoints(end,7))));
                            if distance>=0.5*c
                                xcurve(num+1)=curve.controlpoints(end,7);
                                ycurve(num+1)=cfunc(curve.controlpoints(end,7));
                                scurve(num+1)=distance;
                            end
                            break
                        else
                            xcurve(num+1)=tempx(sn);
                            ycurve(num+1)=cfunc(tempx(sn));
                            scurve(num+1)=c;
                            num=num+1;
                        end
                    end
                case 2
                    tcurve=0:c*1e-4:1;
                    xcurve=xfunc(tcurve);xcurve=reshape(xcurve,[],1);
                    ycurve=yfunc(tcurve);ycurve=reshape(ycurve,[],1);
                    xy=[xcurve,ycurve];
                    temps=[0;vecnorm([xy(2:end,:)-xy(1:end-1,:)]',2)'];
                    s=zeros(size(temps));
                    pool=parpool(2);
                    parfor j=1:length(temps); s(j)=sum(temps(1:j)); end
                    starg= [0:c*1e-1:s(end)];
                    sns  = NaN(size(starg));
                    parfor j=1:length(starg)
                        temp1=abs(s-starg(j));
                        [temp2,idt]=sort(temp1);
                        temp3=find(temp2>0,1,"first");
                        temp4=idt(temp3);
                        sns(j)=temp4;
                    end
                    pool = gcp('nocreate');
                    delete(pool);
                    tcurve=tcurve(sns);
                    xcurve=xcurve(sns);
                    ycurve=ycurve(sns);
                    scurve=s(sns);
                    tcurve=reshape(tcurve,[],1);
            end
    end
    xcurve = reshape(xcurve,[],1);
    ycurve = reshape(ycurve,[],1);
    scurve = reshape(scurve,[],1);
    % obj.obj.LS_Vox(i).xcurve=xcurve;
    % obj.obj.LS_Vox(i).ycurve=ycurve;
    if debug
        plot(xcurve,ycurve,'k.');
    end
    switch fit_mode
        case 1
            % vect2 = [curve.controlpoints(:,1:4);curve.controlpoints(end,[7,8,5,6])];                  % 构建二维切向向量
            % vect2(:,3:4) = vect2(:,3:4)./vecnorm((vect2(:,3:4))',2);                                  % 向量标准化
            vecvec= [   2e-1*c*curve.curve_dir*ones(size(xcurve)),...
                cfunc(xcurve+1e-1*c*curve.curve_dir)-cfunc(xcurve-1e-1*c*curve.curve_dir)];
        case 2
            vecvec= [ xfunc(tcurve+c*1e-4)-xfunc(tcurve-c*1e-4),yfunc(tcurve+c*1e-4)-yfunc(tcurve-c*1e-4)];
    end
    vecvec= vecvec./vecnorm(vecvec',2)';
    vect2 = [xcurve,ycurve,vecvec];
    vect3 = [vect2(:,[1,2]),zeros(size(vect2(:,1))),vect2(:,[3,4]),zeros(size(vect2(:,1)))];    % 构建三维切向向量
    % 这里只是很简单的，如果面对空间线条，需要对这行👆做修改
    % 构建所有法平面方程 Ax+By+Cz+D=0;
    A = vect3(:,4); B = vect3(:,5); C = vect3(:,6);
    D = -(A.*vect3(:,1)+B.*vect3(:,2)+C.*vect3(:,3));
    cc = c/10;                      % 离散化曲面
    x = edge(1):cc:edge(2); y = edge(3):cc:edge(4); % 构建散点
    [xx,yy]=meshgrid(x,y);
    zz = ssurf(xx,yy);
    x1 = reshape(xx,[],1); y1 = reshape(yy,[],1); z1 = reshape(zz,[],1);
    for j=1:length(A) % 对每个法平面
        ts=ts+scurve(j);
        %   计算曲面上每个点到法平面的距离 d = d0/d1
        d0 = A(j)*x1+B(j)*y1+C(j)*z1+D(j);
        d1 = abs(d0)./(A(j)^2+B(j)^2+C(j)^2);
        % sn = find(d1<factor*c & z1>zreg);       % 找到距离小于c且高度大于zreg的点，认为这些点是交线
        sn = find(d1<factor*c);       % 找到距离小于c且高度大于zreg的点，认为这些点是交线
        x2 = x1(sn); y2 = y1(sn); z2 = z1(sn);
        xyz2 = [x2, y2, z2, ones(size(x2))];    % 构造齐次坐标
        %   构造坐标变换（先平移再旋转）
        t1 = trans_matrix([([0 0 0]-vect3(j,1:3)),0,0,0],1);  % 先移动到[0 0 0]
        [pos_sph1(1),pos_sph1(2)] = cart2sph(vect3(j,4),vect3(j,5),vect3(j,6));   %   分量转为旋转
        [pos_sph2(1),pos_sph2(2)] = cart2sph(0,0,1);                        %   分享转为旋转
        pos_sph1 = rad2deg(pos_sph1); pos_sph2 = rad2deg(pos_sph2);         %   转为角度制
        t2 = trans_matrix([0,0,0,0,-pos_sph1(2),-pos_sph1(1)],1);
        t3 = trans_matrix([0,0,0,0,-90,-90],1);
        t = t3*t2*t1;
        xyz3 = (t*xyz2')';                      % 做线性变换
        xyz3 = sortrows(xyz3,1);                % 对结果做
        x3 = xyz3(:,1); y3 = xyz3(:,2); z3 = xyz3(:,3);                     % 将坐标变换到XOY平面上
        %   提取截面信息
        % x4 = x3(y3>=zreg);
        % y4 = y3(y3>=zreg);
        p=0.9999;
        pp = csaps(x3,y3,p);                %   Create piecewise function coefficients
        ff = fittype('smoothingspline');    %   Create fittype object
        cf = cfit(ff,pp);                   %   Create cfit object
        yf = cf(x3);
        %   计算当前中心线对应的线条截面范围
        pos1=find(x3<=0&yf<=zreg,1,'last');
        pos2=find(x3>=0&yf<=zreg,1,'first');
        %   计算线宽线高
        x4 = x3(pos1:pos2);
        y4 = yf(pos1:pos2);
        sw = max(x4)-min(x4);
        sh = max(y4)-min(y4);
        %   拟合与保存
        obj.LS_profile(m).sn=m;
        obj.LS_profile(m).group=i;
        obj.LS_profile(m).seria=j;
        obj.LS_profile(m).act=1;
        obj.LS_profile(m).x=vect3(j,1);
        obj.LS_profile(m).y=vect3(j,2);
        obj.LS_profile(m).z=vect3(j,3);
        obj.LS_profile(m).i=vect3(j,4);
        obj.LS_profile(m).j=vect3(j,5);
        obj.LS_profile(m).k=vect3(j,6);
        obj.LS_profile(m).s=scurve(j);
        obj.LS_profile(m).ss=ts;
        % obj.LS_profile(m).edge=[min(x3),max(x3),min(y3),max(y3),min(z3),max(z3)];
        % obj.LS_profile(m).xx = x3;
        % obj.LS_profile(m).yy = y3;
        obj.LS_profile(m).edge=[min(x4),max(x4),min(y4),max(y4),min(z3),max(z3)];
        obj.LS_profile(m).xx = x4;
        obj.LS_profile(m).yy = y4;
        obj.LS_profile(m).sw = sw;
        obj.LS_profile(m).sh = sh;
        obj.LS_profile(m).curve_cmd = 'csaps(xx,yy,0.98,xx);';
        % obj.LS_profile(m).curve = cp_extract_cspline(x3,smooth(y3,0.8),0.92,'kk',0.1,'k1',0.5,'k2',1);
        if test
            figure(2)
            try
            xx = obj.LS_profile(m).xx;
            yy = obj.LS_profile(m).yy;
            fy = eval(obj.LS_profile(m).curve_cmd);
            % plot(x3,y3,'.k',x3,fy,'r-');
            plot(xx,yy,'.k',xx,fy,'r-');
            tt = ['group ',num2str(i,'%02i'),', num ',num2str(j,'%03i'),' [',num2str(vect3(j,1),'%03.2f'),',',num2str(vect3(j,2),'%03.2f'),']'];
            title(tt)
            xlabel('n [mm]') % 法线轴
            ylabel('b [mm]') % 副法线轴
            set(gca,'FontName','Times New Roman')
            if save_flag
                saveas(gca,[obj.syset.path_outfig,'profile_g',num2str(i,'%03i'),'_n',num2str(j,'%03i'),'.jpg'])
            end
            if debug
                figure(1)
                mesh(xx,yy,zz)
                figure(2)
                plot3(x2,y2,z2,'r.',x3,y3,z3,'b.');
                view([0 0 1])
            end
            end
        end
        m=m+1;
    end
end
%%  结束与标记
obj.syset.flags.read_flag_profiletxra = 1;
end