%   断开连接
function obj = DC4Printer(obj)
if obj.Devinfo.printer.statue == 0
    warning('motion control platform is already offline, returning')
else
    clear obj.Devinfo.printer.s
    % obj.Devinfo.printer.s = [];
    disp('closed serial port')
    obj.Devinfo.printer.statue = 0;
end
