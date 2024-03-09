function obj = saveCode4Print(obj)
%%  依赖关系判断
if obj.syset.flags.read_flag_trajectory~=1
    error('trajectory has not extracted yet!')
end
%%  生成打印Gcode
%   初始化
Flag_Air_Target= 0;                         %目标气压状态
Flag_Air_Current = Flag_Air_Target;         %当前气压状态
Target_Position = zeros(1,2);               %目标位置
%   新建并打开文档
[pname] = uigetdir([],'Choose a Path to save GCODE');
fname = 'Gcode4Print.gcode';
if isequal(pname,0)
    error('The user has not selected any file, abort!');
else
    disp('path:');
    disp(fullfile(pname,fname));
end
str = [pname,'\',fname];
fid = fopen(str,'w');
%   写入数据
for i=1:length(obj.TJ_data.Code4Print)
    temp_cmd = cell2mat(obj.TJ_data.Code4Print(i));
    fprintf(fid,'%s \n',temp_cmd);
end
%   关闭文件
fclose(fid);
end