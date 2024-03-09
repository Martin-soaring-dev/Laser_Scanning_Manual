function obj = LS_process_optimization(obj,varargin)
%%  依赖关系判断
if obj.syset.flags.flag_adjusted_traj~=1
    error('strand_model has not been processed yet!')
end
%%  default values
default_flag_plot = 1;      % 是否绘图
default_flag_G05  = 0;      % 是否使用G05指令
default_k         = 1;      % 修正系数
%   声明一个p为inputParser格式的。其实也可以理解为一个该格式的句柄一样的东西
IP = inputParser;
addRequired(IP,'obj');
%   接下来两个是可选参数，名字分别为’stepsize'和'OptimalityTolerance'，如果没有检测到输入将有相应的缺省值defaulth和epsilon。这些都在函数开头声明好了
addParameter(IP,'flag_plot',default_flag_plot);
addParameter(IP,'flag_G05',default_flag_G05);
addParameter(IP,'k',default_k);
%   利用parse函数将输入参数与上面的进行匹配
parse(IP,obj,varargin{:});
%   此时就已经生成好了一个inputParser格式的参数p，p里面含有不少东西，其中它的Results为一个结构体，是输入参数在匹配后的值，利用这个可以完成我的output的赋值
flag_plot = IP.Results.flag_plot;
flag_G05  = IP.Results.flag_G05;
k         = IP.Results.k;
%%  处理程序
%%   数据离散化处理
p = obj.Devinfo.inplt_p;
sn=1;
for i=1:length(obj.LS_deviation)
    %   先把修正后的轨迹读出来
    xyz = NaN(length(obj.LS_deviation(i).deviation),4);
    for j=1:length(obj.LS_deviation(i).deviation)
        if ~isnan(obj.LS_deviation(i).deviation(j).dx); tempx=obj.LS_deviation(i).deviation(j).cx; else tempx=obj.LS_deviation(i).deviation(j).x; end
        if ~isnan(obj.LS_deviation(i).deviation(j).dy); tempy=obj.LS_deviation(i).deviation(j).cy; else tempy=obj.LS_deviation(i).deviation(j).y; end
        if ~isnan(obj.LS_deviation(i).deviation(j).dz); tempz=obj.LS_deviation(i).deviation(j).cz; else tempz=obj.LS_deviation(i).deviation(j).z; end
        xyz(j,:)=[tempx,tempy,tempz,~isnan(obj.LS_deviation(i).deviation(j).dx)];
    end
    %   开始点的离散化
    ssn=1; %序号
    snn=1; %第i组中的序号
    obj.LS_compensation(i).data(ssn).sn  = sn;
    obj.LS_compensation(i).data(ssn).ssn = ssn;
    obj.LS_compensation(i).data(ssn).snn = snn;
    obj.LS_compensation(i).data(ssn).gp  = i;
    obj.LS_compensation(i).data(ssn).x   = xyz(snn,1);
    obj.LS_compensation(i).data(ssn).y   = xyz(snn,2);
    obj.LS_compensation(i).data(ssn).z   = xyz(snn,3);
    obj.LS_compensation(i).data(ssn).act = xyz(snn,4);
    obj.LS_compensation(i).data(ssn).ss  = obj.LS_deviation(i).deviation(snn).ss;
    obj.LS_compensation(i).data(ssn).f0  = obj.LS_deviation(i).deviation(snn).ff;
    obj.LS_compensation(i).data(ssn).f1  = obj.LS_deviation(i).deviation(snn).ff+obj.LS_deviation(i).deviation(snn).df;
    obj.LS_compensation(i).data(ssn).f2  = obj.LS_deviation(i).deviation(snn).f2;
    obj.LS_compensation(i).data(ssn).ww  = obj.LS_deviation(i).deviation(snn).ww;
    obj.LS_compensation(i).data(ssn).hh  = obj.LS_deviation(i).deviation(snn).hh;
    obj.LS_compensation(i).data(ssn).dw  = obj.LS_deviation(i).deviation(snn).dw;
    obj.LS_compensation(i).data(ssn).dh  = obj.LS_deviation(i).deviation(snn).dh;
    obj.LS_compensation(i).delay         = obj.LS_deviation(i).time_delay;
    sn=sn+1;ssn=ssn+1;
    while 1
        if ssn>=length(obj.LS_deviation(i).deviation); break; end
        tempxyz = xyz-xyz(snn,:);
        distance= vecnorm(tempxyz(:,1:3)',2)';
        tempsn  = find(abs(distance-p)<=1e-3); % 这里按照精度的10倍取点
        if isempty(tempsn ); continue; end
        tempsnn = tempsn(find(tempsn>snn,1,"first"));
        if isempty(tempsnn); break; end
        snn=tempsnn;
        obj.LS_compensation(i).data(ssn).sn  = sn;
        obj.LS_compensation(i).data(ssn).ssn = ssn;
        obj.LS_compensation(i).data(ssn).snn = snn;
        obj.LS_compensation(i).data(ssn).gp  = i;
        obj.LS_compensation(i).data(ssn).x   = xyz(snn,1);
        obj.LS_compensation(i).data(ssn).y   = xyz(snn,2);
        obj.LS_compensation(i).data(ssn).z   = xyz(snn,3);
        obj.LS_compensation(i).data(ssn).act = xyz(snn,4);
        obj.LS_compensation(i).data(ssn).ss  = obj.LS_deviation(i).deviation(snn).ss;
        obj.LS_compensation(i).data(ssn).f0  = obj.LS_deviation(i).deviation(snn).ff;
        obj.LS_compensation(i).data(ssn).f1  = obj.LS_deviation(i).deviation(snn).ff+obj.LS_deviation(i).deviation(snn).df;
        obj.LS_compensation(i).data(ssn).f2  = obj.LS_deviation(i).deviation(snn).f2;
        obj.LS_compensation(i).data(ssn).ww  = obj.LS_deviation(i).deviation(snn).ww;
        obj.LS_compensation(i).data(ssn).hh  = obj.LS_deviation(i).deviation(snn).hh;
        obj.LS_compensation(i).data(ssn).dw  = obj.LS_deviation(i).deviation(snn).dw;
        obj.LS_compensation(i).data(ssn).dh  = obj.LS_deviation(i).deviation(snn).dh;
        sn=sn+1;ssn=ssn+1;
    end
end
% return
%%   生成G代码草稿
% 1         2   3   4   5   6   7   8   9   10
% cmd_num
%       G   1   X   Y   Z   E   F
%       G   4   S   P
%       G   5   E   F   I   J   P   Q   X   Y
%       G   92  X   Y   Z   E
%       M   106
%       M   107
% abs('G') = 71
% abs('M') = 77
p_on=106;
p_off=107;
max_e = 1e3;    %最大挤出量，当超过这个数值时，清零

%   按照最大尺寸初始化temp_draft_gcode
max_sn = obj.LS_compensation(end).data(end).sn;
temp_draft_gcode = NaN(max_sn+4,10);

num_int = 1;
sum_ss  = 0;
for i=1:length(obj.LS_compensation)
    %   然后先移动到第一个点
    temp_draft_gcode(num_int,1)=71;
    temp_draft_gcode(num_int,2)=0;
    temp_draft_gcode(num_int,3)=obj.LS_compensation(i).data(1).x;
    temp_draft_gcode(num_int,4)=obj.LS_compensation(i).data(1).y;
    temp_draft_gcode(num_int,5)=obj.LS_compensation(i).data(1).z;
    temp_draft_gcode(num_int,6)=obj.LS_compensation(i).data(1).ss+sum_ss; sum_ss=temp_draft_gcode(num_int,6);
    temp_draft_gcode(num_int,7)=obj.Devinfo.trajectory.feed_rate(1);
    num_int = num_int+1;
    %   然后打开气压
    temp_draft_gcode(num_int,1)=77;
    temp_draft_gcode(num_int,2)=p_on;
    num_int = num_int+1;
    try 
        temp=obj.LS_compensation(i).delay;
        %   有延迟时，等待一会，再开始移动 
        %   G04 https://marlinfw.org/docs/gcode/G004.html
        temp_draft_gcode(num_int,1)=71;
        temp_draft_gcode(num_int,2)=4;
        temp_draft_gcode(num_int,4)=obj.LS_compensation(i).delay;%第3列单位为s，第4列单位为ms
        num_int = num_int+1;
    end
    %   移动到下一个点
    for j=2:length(obj.LS_compensation(i).data)
        if flag_G05==1
            temp_draft_gcode(num_int,1)=71;
            temp_draft_gcode(num_int,2)=5;
            temp_draft_gcode(num_int,3)=obj.LS_compensation(i).data(j).ss+sum_ss; sum_ss=temp_draft_gcode(num_int,3);
            temp_draft_gcode(num_int,4)=obj.LS_compensation(i).data(j).f2;
            spx = obj.LS_deviation(i).X_Curve.sp; spy = obj.LS_deviation(i).Y_Curve.sp;
            dx  = fnval(spx,obj.LS_compensation(i).data(j-1).snn+1)-fnval(spx,obj.LS_compensation(i).data(j-1).snn-1);
            dy  = fnval(spy,obj.LS_compensation(i).data(j-1).snn+1)-fnval(spy,obj.LS_compensation(i).data(j-1).snn-1);
            dxy = [dx,dy]; dxy = dxy/norm(dxy);
            temp_draft_gcode(num_int,5)=dxy(1);
            temp_draft_gcode(num_int,6)=dxy(2);
            spx = obj.LS_deviation(i).X_Curve.sp; spy = obj.LS_deviation(i).Y_Curve.sp;
            dx  = fnval(spx,obj.LS_compensation(i).data(j).snn+1)-fnval(spx,obj.LS_compensation(i).data(j).snn-1);
            dy  = fnval(spy,obj.LS_compensation(i).data(j).snn+1)-fnval(spy,obj.LS_compensation(i).data(j).snn-1);
            dxy = [dx,dy]; dxy = dxy/norm(dxy);
            temp_draft_gcode(num_int,7)=-dxy(1);
            temp_draft_gcode(num_int,8)=-dxy(2);
            temp_draft_gcode(num_int,9)=obj.LS_compensation(i).data(j).x;
            temp_draft_gcode(num_int,10)=obj.LS_compensation(i).data(j).y;
            num_int = num_int+1;
        else
            temp_draft_gcode(num_int,1)=71;
            temp_draft_gcode(num_int,2)=1;
            temp_draft_gcode(num_int,3)=obj.LS_compensation(i).data(j).x;
            temp_draft_gcode(num_int,4)=obj.LS_compensation(i).data(j).y;
            temp_draft_gcode(num_int,5)=obj.LS_compensation(i).data(j).z;
            temp_draft_gcode(num_int,6)=obj.LS_compensation(i).data(j).ss+sum_ss; sum_ss=temp_draft_gcode(num_int,6);
            temp_draft_gcode(num_int,7)=obj.LS_compensation(i).data(j).f2;
            num_int = num_int+1;
        end
        %   当E坐标大于最大值时，置为0；
        if sum_ss>max_e
            temp_draft_gcode(num_int,1)=71;
            temp_draft_gcode(num_int,2)=92;
            temp_draft_gcode(num_int,6)=0; sum_ss=0;
            num_int = num_int+1;
        end
    end
    %   关闭气压
    temp_draft_gcode(num_int,1)=77;
    temp_draft_gcode(num_int,2)=p_off;
    num_int = num_int+1;
end
obj.PT_data.draft_gcode=temp_draft_gcode;


% %   写入G05代码草稿
% for j=1:sum(temp_curve_cps(:,9)==i)
%     % temp_draft_gcode(num_int,[1 2 4 5 6 7 8 9 10])=[71,5,temp_curve_cps(first_position+j-1,11),temp_curve_cps(first_position+j-1,3:8)];
%     %   2024-01-18 Martin:  Symbols of columns 7 and 8 in temp_draft_gcode
%     %                       (columns 5 adn 6 in temp_curve_cps) need be
%     %                       reversed as showed in cp_extract_cspline()
%     %                       row 142
%     %                       "(quiver(controlpoints(:,7),controlpoints(:,8),-controlpoints(:,5),-controlpoints(:,6),0))"
%     temp_draft_gcode(num_int,[1 2 4 5 6 7 8 9 10])=[71,5,temp_curve_cps(first_position+j-1,11),temp_curve_cps(first_position+j-1,3:4),-temp_curve_cps(first_position+j-1,5:6),temp_curve_cps(first_position+j-1,7:8)];
%     num_int = num_int+1;
% end
%%  结束与标记
obj.syset.flags.flag_adjusted_para = 1;
end