function obj = DC4Scanner(obj)
if obj.Devinfo.sacnner.statue == 0
    warning('motion control platform is already offline, returning')
else
    fclose(obj.Devinfo.scanner.t);
    delete(obj.Devinfo.scanner.t);
    obj.Devinfo.scanner.t = [];
    disp('scanner disconnected')
    obj.Devinfo.printer.statue = 0;
end
end