function obj = LS_strand_model(obj,varargin)
%%  依赖关系判断
if obj.syset.flags.cacu_flag_deviation~=1
    error('deviation_calculation has not been processed yet!')
end
%%  default values
default_flag_plot = 1;      % 是否绘图
default_fit_density=1e3;    % 曲面拟合尺度
%   声明一个p为inputParser格式的。其实也可以理解为一个该格式的句柄一样的东西
IP = inputParser;
addRequired(IP,'obj');
%   接下来两个是可选参数，名字分别为’stepsize'和'OptimalityTolerance'，如果没有检测到输入将有相应的缺省值defaulth和epsilon。这些都在函数开头声明好了
addParameter(IP,'flag_plot',default_flag_plot);
addParameter(IP,'fit_density',default_fit_density);
%   利用parse函数将输入参数与上面的进行匹配
parse(IP,obj,varargin{:});
%   此时就已经生成好了一个inputParser格式的参数p，p里面含有不少东西，其中它的Results为一个结构体，是输入参数在匹配后的值，利用这个可以完成我的output的赋值
flag_plot = IP.Results.flag_plot;
fit_density=IP.Results.fit_density;
%%  处理程序
%   1. 获取基于实验数据和理论的线截面模型
[strand_model,gof,output,datainfo] = strand_data_converge();
%   保存
obj.LS_model.strand_model   = strand_model;
obj.LS_model.gof            = gof;
obj.LS_model.output         = output;
obj.LS_model.datainfo       = datainfo;

if flag_plot==1
    %   绘制模型曲面
    xl = linspace(obj.LS_model.datainfo.Hmin,obj.LS_model.datainfo.Hmax,fit_density);
    yl = linspace(obj.LS_model.datainfo.Vmin,obj.LS_model.datainfo.Vmax,fit_density);
    [XL,YL] = meshgrid(xl,yl);
    ZL = strand_model(XL,YL);
    % surf(XL,YL,ZL)
    mesh(XL,YL,ZL);
    a = strand_model.a;
end
%%  结束与标记
obj.syset.flags.read_flag_sccmload = 1;
end