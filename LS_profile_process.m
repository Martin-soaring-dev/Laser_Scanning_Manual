function obj = LS_profile_process(obj,varargin)
%%  依赖关系判断
if obj.syset.flags.read_flag_profiletxra~=1
    error('profile extraction has not been processed yet!')
end
%%  default values
default_mode = 1;           % 模式选择，1：正常处理 2：数据剔除
default_smooth_flag=1;      % 是否平滑？默认1
default_groupedplot=0;      % 是否分组绘制？
%   声明一个p为inputParser格式的。其实也可以理解为一个该格式的句柄一样的东西
IP = inputParser;
addRequired(IP,'obj');
%   接下来两个是可选参数，名字分别为’stepsize'和'OptimalityTolerance'，如果没有检测到输入将有相应的缺省值defaulth和epsilon。这些都在函数开头声明好了
addParameter(IP,'mode',default_mode);
addParameter(IP,'smooth_flag',default_smooth_flag);
addParameter(IP,'groupedplot',default_groupedplot);
%   利用parse函数将输入参数与上面的进行匹配
parse(IP,obj,varargin{:});
%   此时就已经生成好了一个inputParser格式的参数p，p里面含有不少东西，其中它的Results为一个结构体，是输入参数在匹配后的值，利用这个可以完成我的output的赋值
mode = IP.Results.mode;
smooth_flag = IP.Results.smooth_flag;
groupedplot = IP.Results.groupedplot;
%%  处理程序
zreg=obj.PC_data_merged.group_data.reg;
act = [obj.LS_profile.act];
sn= find(act);
switch mode
    case 1
        s = [obj.LS_profile.s];
        ss= [obj.LS_profile.ss];
        sw= NaN(size(ss));
        sh= NaN(size(ss));
        for i=1:length(sn)
            xx=obj.LS_profile(sn(i)).xx;
            yy=obj.LS_profile(sn(i)).yy;
            xx=xx(yy>=zreg);
            yy=yy(yy>=zreg);
            sw(sn(i))=obj.LS_profile(sn(i)).sw;
            sh(sn(i))=obj.LS_profile(sn(i)).sh;
        end
        % %   赋值 计算在LS_profile_extraction中做过了
        % for i=1:length(s)
        %     obj.LS_profile(i).ss=ss(i);
        %     obj.LS_profile(i).sw=sw(i);
        %     obj.LS_profile(i).sh=sh(i);
        % end
        %   在模式2中保存sw,sh的原始数据，不做修改，以便于日后绘图时可以按需要加以平滑和调整，
        %   以实现最佳的视觉效果

        %   数据平滑
        if smooth_flag
            sw = smooth(sw);
            sh = smooth(sh);
        end
        %   拟合？
        x=ss;
        y=sw;
        p=0.5;
        pp = csaps(x,y,p);                  %   Create piecewise function coefficients
        ff = fittype('smoothingspline');    %   Create fittype object
        cf = cfit(ff,pp);                   %   Create cfit object
        sw2= cf(ss);

        x=ss;
        y=sh;
        p=0.5;
        pp = csaps(x,y,p);                  %   Create piecewise function coefficients
        ff = fittype('smoothingspline');    %   Create fittype object
        cf = cfit(ff,pp);                   %   Create cfit object
        sh2= cf(ss);

        %   绘图
        if groupedplot

        else
            figure(1)
            yyaxis left
            plot(ss(sn),sw(sn),'k.');
            ylabel('Strand Width [mm]')

            yyaxis right
            plot(ss(sn),sh(sn),'b.');
            ylabel('Strand Height [mm]')

            xlabel('Trajectory distance [mm]')
            title('Strand Feature')
            grid on
            set(gca,'FontName','Times New Roman')



            %   绘图
            figure(1)
            yyaxis left
            hold on
            plot(ss(sn),sw2(sn),'k-');
            hold off
            ylabel('Strand Width [mm]')

            yyaxis right
            hold on
            plot(ss(sn),sh2(sn),'b-');
            hold off
            ylabel('Strand Height [mm]')

            xlabel('Trajectory distance [mm]')
            title('Strand Feature fitted')
            grid on
            set(gca,'FontName','Times New Roman')
            % groupedplot
        end
    case 2
        s = [obj.LS_profile.s];
        ss= [obj.LS_profile.ss];
        sw= [obj.LS_profile.sw];
        sh= [obj.LS_profile.sh];
        loop_plag=1;
        finishflg=0;
        while loop_plag==1
            %   绘图
            figure(3)
            yyaxis left
            plot(sn,sw(sn),'k.');
            ylabel('Strand Width [mm]')

            yyaxis right
            plot(sn,sh(sn),'b.');
            ylabel('Strand Height [mm]')

            xlabel('Trajectory distance [mm]')
            title('Strand Feature')
            grid on
            set(gca,'FontName','Times New Roman')
            %   对话式剔除点
            %   交互式微调程序
            prompt2='Please input start,end num to delete (Type Q/q to quit; Y/y to finish):';
            str2 = input(prompt2,'s');
            if contains(str2,'Q') || contains(str2,'q') %退出
                loop_plag=0;
                warning(strcat("quit operation!"));
                continue
            elseif contains(str2,'Y') || contains(str2,'y') %完成
                for i=1:length(act)
                    obj.LS_profile(i).act=act(i);
                end
                obj = LS_profile_process(obj,'mode',1);
                disp('operation finished')
                loop_plag=0;
                continue
            else
                temp_s2 = str2num(str2);
                if isempty(temp_s2)
                    warning(strcat("No input, please retry!"));
                    continue
                elseif ~length(temp_s2)==2
                    warning(strcat("Invalid input, please retry!"));
                    continue
                else
                    pos1 = temp_s2(1);
                    pos2 = temp_s2(2);
                    act(pos1:pos2)=0;
                    sn=find(act);
                end
            end
            % if error_flag==1
            %     loop_plag=0;
            %     continue
            % end
        end
end
%%  结束与标记
obj.syset.flags.read_flag_profileansy = 1;
end