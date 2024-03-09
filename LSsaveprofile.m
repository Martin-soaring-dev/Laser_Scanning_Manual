function LSsaveprofile(obj,varargin)
%   绘制和保存数据
%   LSsaveprofile(obj)
%   LSsaveprofile(obj,option,values)
%   Option:
%   1. "codraw": 是否绘制合并图片，这个图是综合图，绘制时特别慢，Value=1/0.
%   2. "svflag": 是否保存图像，Value=1/0
%%  依赖关系判断
if obj.syset.flags.read_flag_profileansy~=1
    error('profile extraction has not been processed yet!')
end
%%  default values
default_codraw = 0;                 %   合并绘制
default_svflag = 0;                 %   保存标志
%   声明一个p为inputParser格式的。其实也可以理解为一个该格式的句柄一样的东西
IP = inputParser;
addRequired(IP,'obj');
%   接下来两个是可选参数，名字分别为’stepsize'和'OptimalityTolerance'，如果没有检测到输入将有相应的缺省值defaulth和epsilon。这些都在函数开头声明好了
addParameter(IP,'codraw',default_codraw);
addParameter(IP,'svflag',default_svflag);
%   利用parse函数将输入参数与上面的进行匹配
parse(IP,obj,varargin{:});
%此时就已经生成好了一个inputParser格式的参数p，p里面含有不少东西，其中它的Results为一个结构体，是输入参数在匹配后的值，利用这个可以完成我的output的赋值
codraw = IP.Results.codraw;
svflag = IP.Results.svflag;
%%  处理程序
zreg = obj.PC_data_merged.group_data.reg;
for m=1:length(obj.LS_profile)
    xx = obj.LS_profile(m).xx;
    yy = obj.LS_profile(m).yy;
    xxt= xx(yy-zreg>=0);
    yyt= yy(yy-zreg>=0);
    % % swm = max(xxt)-min(xxt);
    % % shm = max(yyt)-min(yyt);
    % minx(m)=min([obj.LS_profile(m).xx]);
    % maxx(m)=max([obj.LS_profile(m).xx]);
    edge = [obj.LS_profile(m).edge];
    minx(m)=edge(1);
    maxx(m)=edge(2);
    % % miny(m)=min([obj.LS_profile(m).yy]);
    % % maxy(m)=max([obj.LS_profile(m).yy]);
    % miny(m)=min([obj.LS_profile(m).yy])-zreg;
    % maxy(m)=max([obj.LS_profile(m).yy])-zreg;
    miny(m)=edge(3)-zreg;
    maxy(m)=edge(4)-zreg;
    % sw(m)=swm; sh(m)=shm;
end
% 绘图初始化
close all
% 图1
m=540;
f1 = figure(1);
a11 = axes;
xx = obj.LS_profile(m).xx;
% yy = obj.LS_profile(m).yy;
% fy = eval(obj.LS_profile(m).curve_cmd);
yy = obj.LS_profile(m).yy-zreg;
fy = eval(obj.LS_profile(m).curve_cmd);
gp = obj.LS_profile(m).group;
sn = obj.LS_profile(m).seria;
% minxx = min(minx([obj.LS_profile.group]==gp));
% maxxx = max(maxx([obj.LS_profile.group]==gp));
% minyy = min(miny([obj.LS_profile.group]==gp));
% maxyy = max(maxy([obj.LS_profile.group]==gp));
minxx = min(minx(find([obj.LS_profile.act]==1)));
maxxx = max(maxx(find([obj.LS_profile.act]==1)));
minyy = min(miny(find([obj.LS_profile.act]==1)));
maxyy = max(maxy(find([obj.LS_profile.act]==1)));
p1 = plot(a11,xx,yy,'.k',xx,fy,'r-');
tt = ['group ',num2str(gp,'%02i'),', num ',num2str(sn,'%03i'),' [',num2str(obj.LS_profile(m).x,'%03.2f'),',',num2str(obj.LS_profile(m).y,'%03.2f'),']'];
title(tt)
xlabel('n [mm]') % 法线轴
ylabel('b [mm]') % 副法线轴
grid on
axis([minxx maxxx minyy maxyy]);
% axis equal
set(gca,'FontName','Times New Roman')
if codraw
    % 图2
    f2 = figure(2);
    a21 = axes(f2,"Position",[0.10 0.50 0.40 0.40]);
    %   图2-1：曲面
    x = min(obj.Surface.surface_eq.Points(:,1)):0.1:max(obj.Surface.surface_eq.Points(:,1));
    y = min(obj.Surface.surface_eq.Points(:,2)):0.1:max(obj.Surface.surface_eq.Points(:,2));
    [xx1,yy1] = meshgrid(x,y);
    ff = obj.Surface.surface_eq;
    zz1 = ff(xx1,yy1);
    p211 = mesh(xx1,yy1,zz1,'FaceAlpha','0');
    hold on
    %   中心线及起止点
    c = obj.Devinfo.inplt;
    for i=1:length(obj.LS_Vox)
        tx = [obj.LS_Vox(i).curve.controlpoints(:,1);obj.LS_Vox(i).curve.controlpoints(end,7)];
        tx1= tx(1):c*sign(tx(end)-tx(1)):tx(end);
        tf = obj.LS_Vox(i).curve.curve_model;
        p212(i) = plot(tx1,tf(tx1),'r-','LineWidth',1);
        p213(i) = plot(tx(1),tf(tx(1)),...
            'MarkerFaceColor',[0 1 0],...
            'MarkerEdgeColor',[0 0 0],...
            'MarkerSize',8,...
            'Marker','o');
        p214(i) = plot(tx(end),tf(tx(end)),...
            'MarkerFaceColor',[1 0 0],...
            'MarkerEdgeColor',[0 0 0],...
            'MarkerSize',8,...
            'Marker','o');
    end
    a1 = [obj.LS_profile(m).x,obj.LS_profile(m).y,obj.LS_profile(m).i,obj.LS_profile(m).j]; %读取当前点的xyij
    a1(3:4) = a1(3:4)/norm(a1(3:4)); %ij标准化
    kv = 5; %缩放倍数kv 实际长度等于2×kv
    a1(3:4) = a1(3:4)*kv;
    xy1= a1(1:2)+[a1(4),-a1(3)];
    xy2= a1(1:2)+[-a1(4),a1(3)];
    dxy= (xy2-xy1)*1e-1;
    x1 = xy1(1); y1 = xy1(2); x2 = xy2(1); y2 = xy2(2);
    dx = dxy(1); dy = dxy(2);
    %   当前面
    p215 = plot(x1:dx:x2,y1:dy:y2,'y-','LineWidth',3);
    %   当前面相关矢量
    x3 = [a1(1);a1(1)];
    y3 = [a1(2);a1(2)];
    u3 = [a1(3);-a1(4)];
    v3 = [a1(4);a1(3)];
    p216 = quiver(a21,x3,y3,u3,v3,...
        'AutoScaleFactor',0.8,...
        'Color',[1 0 1],...
        'MaxHeadSize',0.8,...
        'LineWidth',2);
    %   当前点
    p217 = plot(a1(1),a1(2),...
        'MarkerFaceColor',[1 1 0],...
        'MarkerEdgeColor',[1 0 1],...
        'MarkerSize',8,...
        'Marker','o');
    hold off
    box on
    view([0 0 1])
    axis([min(x) max(x) min(y) max(y)])
    axis equal
    xlabel('x [mm]')
    ylabel('y [mm]')
    title('Overview')
    % colorbar('eastoutside')
    % colorbar('south')
    set(gca,'FontName','Times New Roman')

    %   图2-2：截面
    a22= axes(f2,"Position",[0.60 0.50 0.30 0.40]);
    p221 = plot(a22,xx,yy,'.k',xx,fy,'r-');
    title(tt)
    xlabel('n [mm]') % 法线轴
    ylabel('b [mm]') % 副法线轴
    grid on
    axis([minxx maxxx minyy maxyy]);
    set(gca,'FontName','Times New Roman')

    %   图2-3：线宽线高
    a23 = axes(f2,"Position",[0.10 0.10 0.35 0.25]);
    act= [obj.LS_profile.act]';
    sn = find(act);
    ss = [obj.LS_profile.ss]';
    sw = NaN(size(ss)); sh=sw;
    sw(sn) = [obj.LS_profile(sn).sw]';
    sh(sn) = [obj.LS_profile(sn).sh]';
    sw = smooth(sw);
    sh = smooth(sh);
    % yyaxis left
    p231= plot(ss,sw,'k-');
    hold on
    p232= plot(ss(m),sw(m),...
        'MarkerFaceColor',[1 1 0],...
        'MarkerEdgeColor',[1 0 0],...
        'MarkerSize',6,...
        'Marker','o');
    hold off
    ylabel('Strand Width [mm]')
    xlabel('Trajectory distance [mm]')
    title('Strand Feature')
    grid on
    set(gca,'FontName','Times New Roman')

    a24 = axes(f2,"Position",[0.55 0.10 0.35 0.25]);
    % yyaxis right
    p233= plot(ss,sh,'b-');
    hold on
    p234= plot(ss(m),sh(m),...
        'MarkerFaceColor',[1 1 0],...
        'MarkerEdgeColor',[1 0 0],...
        'MarkerSize',6,...
        'Marker','o');
    hold off
    ylabel('Strand Height [mm]')

    xlabel('Trajectory distance [mm]')
    title('Strand Feature')
    grid on
    set(gca,'FontName','Times New Roman')
end
%%
ACT = [obj.LS_profile.act];
% SN  = find(ACT);
for m=1:length(obj.LS_profile)
    if ACT(m)==0
        continue
    end
    % % 图1
    % f1 = figure(1);
    xx = obj.LS_profile(m).xx;
    % yy = obj.LS_profile(m).yy;
    % fy = eval(obj.LS_profile(m).curve_cmd);
    yy = obj.LS_profile(m).yy-zreg;
    fy = eval(obj.LS_profile(m).curve_cmd);
    gp = obj.LS_profile(m).group;
    sn = obj.LS_profile(m).seria;
    minxx = min(minx([obj.LS_profile.group]==gp));
    maxxx = max(maxx([obj.LS_profile.group]==gp));
    minyy = min(miny([obj.LS_profile.group]==gp));
    maxyy = max(maxy([obj.LS_profile.group]==gp));
    % p1 = plot(xx,yy,'.k',xx,fy,'r-');
    p1(1).XData = xx; p1(1).YData = yy;
    p1(2).XData = xx; p1(2).YData = fy;
    tt = ['group ',num2str(gp,'%02i'),', num ',num2str(sn,'%03i'),' [',num2str(obj.LS_profile(m).x,'%03.2f'),',',num2str(obj.LS_profile(m).y,'%03.2f'),']'];
    a11.Title.String=tt;
    % xlabel('n [mm]') % 法线轴
    % ylabel('b [mm]') % 副法线轴
    % grid on
    % axis([minxx maxxx minyy maxyy]);
    % % axis equal
    % set(gca,'FontName','Times New Roman')
    if svflag
        saveas(f1,[obj.syset.path_outfig,'profile_g',num2str(gp,'%03i'),'_n',num2str(sn,'%03i'),'.jpg'])
    end
    % drawnow update
    if codraw
        % 图2
        %   曲面
        x = min(obj.Surface.surface_eq.Points(:,1)):0.1:max(obj.Surface.surface_eq.Points(:,1));
        y = min(obj.Surface.surface_eq.Points(:,2)):0.1:max(obj.Surface.surface_eq.Points(:,2));
        [xx1,yy1] = meshgrid(x,y);
        ff = obj.Surface.surface_eq;
        zz1 = ff(xx1,yy1);
        % p211 = mesh(xx,yy,zz,'FaceAlpha','0');
        p211.XData=xx1;p211.YData=yy1;p211.ZData=zz1;
        % hold on
        %   中心线及起止点
        for i=1:length(obj.LS_Vox)
            % tx = obj.LS_Vox(i).curve.breaks;
            tx = [obj.LS_Vox(i).curve.controlpoints(:,1);obj.LS_Vox(i).curve.controlpoints(end,7)];
            % tx1= min(tx):0.1:max(tx);
            tx1= tx(1):c*sign(tx(end)-tx(1)):tx(end);
            tf = obj.LS_Vox(i).curve.curve_model;
            % p212(i) = plot(tx1,tf(tx1),'r-','LineWidth',1);
            % p212(i).XData=tx1;p212(i).YData=tf(tx1);
            % p213(i) = plot(tx(1),tf(tx(1)),...
            %     'MarkerFaceColor',[0 1 0],...
            %     'MarkerEdgeColor',[0 0 0],...
            %     'MarkerSize',8,...
            %     'Marker','o');
            % p213(i).XData=tx(1);p213(i).YData=tf(tx(1));
            % p214(i) = plot(tx(end),tf(tx(end)),...
            %     'MarkerFaceColor',[1 0 0],...
            %     'MarkerEdgeColor',[0 0 0],...
            %     'MarkerSize',8,...
            %     'Marker','o');
            % p214(i).XData=tx(end);p214(i).YData=tf(tx(end));
        end
        a1 = [obj.LS_profile(m).x,obj.LS_profile(m).y,obj.LS_profile(m).i,obj.LS_profile(m).j]; %读取当前点的xyij
        a1(3:4) = a1(3:4)/norm(a1(3:4)); %ij标准化
        kv = 5; %缩放倍数kv 实际长度等于2×kv
        a1(3:4) = a1(3:4)*kv;
        xy1= a1(1:2)+[a1(4),-a1(3)];
        xy2= a1(1:2)+[-a1(4),a1(3)];
        dxy= (xy2-xy1)*1e-1;
        x1 = xy1(1); y1 = xy1(2); x2 = xy2(1); y2 = xy2(2);
        dx = dxy(1); dy = dxy(2);
        %   当前面
        % p215 = plot(x1:dx:x2,y1:dy:y2,'y-','LineWidth',3);
        p215.XData=x1:dx:x2;p215.YData=y1:dy:y2;
        %   当前面相关矢量
        x3 = [a1(1);a1(1)];
        y3 = [a1(2);a1(2)];
        u3 = [a1(3);-a1(4)];
        v3 = [a1(4);a1(3)];
        % p216 = quiver(a21,x3,y3,u3,v3,...
        %     'AutoScaleFactor',0.8,...
        %     'Color',[1 0 1],...
        %     'MaxHeadSize',0.8,...
        %     'LineWidth',2);
        p216.XData=x3;p216.YData=y3;p216.UData=u3;p216.VData=v3;
        %   当前点
        % p217 = plot(a1(1),a1(2),...
        %     'MarkerFaceColor',[1 1 0],...
        %     'MarkerEdgeColor',[1 0 1],...
        %     'MarkerSize',8,...
        %     'Marker','o');
        p217.XData=a1(1);p217.YData=a1(2);
        % hold off
        % box on
        % view([0 0 1])
        % axis([min(x) max(x) min(y) max(y)])
        % axis equal
        % xlabel('x [mm]')
        % ylabel('y [mm]')
        % colorbar('eastoutside')
        % set(gca,'FontName','Times New Roman')
        a21.Title.String='Overview';

        % a22 = axes(f2,"Position",[0.55 0.55 0.4 0.4]);
        % p221(1).XData = xx; p221(1).YData = yy;
        % p221(2).XData = xx; p221(2).YData = fy;
        p221(1).XData = xx(yy>=0); p221(1).YData = yy(yy>=0);
        p221(2).XData = xx(fy>=0); p221(2).YData = fy(fy>=0);
        a22.Title.String=tt;

        % a23 = axes(f2,"Position",[0.55 0.10 0.4 0.4]);
        % sst = [obj.LS_profile.s];
        % ss  = zeros(size(sst));
        % for i=1:length(sst)
            % ss(i)=sum(sst(1:i));
        % end
        % sst= [obj.LS_profile.s];
        % ss2= sum(sst(1:m));
        % xx2= xx(yy>=0);
        % yy2= yy(yy>=0);
        % swm= max(xx2)-min(xx2);
        % shm= max(yy2)-min(yy2);
        % yyaxis left
        % p231= plot(ss,sw,'k-');
        % hold on
        % p232= plot(ss2,swm,...
        %     'MarkerFaceColor',[0 1 1],...
        %     'MarkerEdgeColor',[1 0 0],...
        %     'MarkerSize',8,...
        %     'Marker','o');
        % hold off
        p232.XData=ss(m);p232.YData=sw(m);
        % ylabel('Strand Width [mm]')

        % yyaxis right
        % p233= plot(ss,sh,'b-');
        % hold on
        % p234= plot(ss2,shm,...
        %     'MarkerFaceColor',[0 1 1],...
        %     'MarkerEdgeColor',[1 0 0],...
        %     'MarkerSize',8,...
        %     'Marker','o');
        % hold off
        p234.XData=ss(m);p234.YData=sh(m);
        % ylabel('Strand Height [mm]')

        % xlabel('Trajectory distance [mm]')
        % title('Strand Feature')
        a23.Title.String='Strand Width Distribution';
        a24.Title.String='Strand Height Distribution';
        % grid on
        % set(gca,'FontName','Times New Roman')
        if svflag
            saveas(f2,[obj.syset.path_outfig,'profile\','combined_g',num2str(gp,'%03i'),'_n',num2str(sn,'%03i'),'.jpg'])
        end
    end
    drawnow update
end
end