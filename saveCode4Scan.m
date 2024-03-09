function obj = saveCode4Scan(obj)
if obj.syset.flags.read_flag_trajectory~=1
    error('trajectory has not extracted yet!')
end
%%  生成扫描Gcode
%   2022-01-15 更新：
%   结合扫描、密化的路径生成扫描路径矩阵，并把矩阵（工作区变量）保存到指定的路径下，
%   这里有两个思路：
%       （1）在这里直接进行加密处理，需要大幅修改代码，LJ_Control的代码修改较少
%       （2）不使用G代码进行传递，直接使用工作区变量进行传输，好处是减少了本文件和LJ_Control的代码量，
%           坏处是增加了手工编程的难度，未来需要扫描则必须采用DXF→MATALB→Scaner的工作流程
%       权衡利弊后选择第二种方式！
%   便于后续读取和操作。
%       数据格式：
%               参数[ x1,  x2,  x3,  x4,   x5,  x6 ]
%               直线：起X  起Y  终X  终Y   []   []   
%               圆弧：心X  心Y  经R  始θ  终θ []   
%   新建并打开文档
[pname] = uigetdir([],'Choose a Path to save GCODE');
fname = 'Gcode4Scan.mat';
if isequal(pname,0)
    error('The user has not selected any file, abort!');
else
    disp('path:');
    disp(fullfile(pname,fname));
end
str = [pname,'\',fname];
Z_Value = obj.TJ_data.TJ4ZZ+obj.Devinfo.scanner.scanneroffset(3);
F_Value = obj.Devinfo.trajectory.feed_rate(2);
Trajectory4Scan = obj.TJ_data.TJ4SC;
XO=obj.Devinfo.trajectory.start_point(1);
YO=obj.Devinfo.trajectory.start_point(2);
Trajectory4Print=obj.TJ_data.TJ4PT;
%   2024-01-27 Martin 等以后需要加五轴的时候加一个齐次坐标变换就行了
save(str,'Trajectory4Scan','Z_Value','F_Value','XO','YO','Trajectory4Print')
end