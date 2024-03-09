function obj = loadDXF(obj)
[fname,pname] = uigetfile('.dxf','Choose a Path File in .DXF format');
if isequal(fname,0)
    disp('none');
else
    disp(fullfile(pname,fname));
end
str = [pname,'\',fname];
try
    dxf = DXFtool(str);
    %   2024-01-26 保存dxf到类中
    obj.TJ_data.dxf = dxf;
    obj.syset.flags.read_flag_dxf = 1;
catch ME
    obj.syset.flags.read_flag_dxf = 0;
    disp('load failed')
    error(ME)
end
end