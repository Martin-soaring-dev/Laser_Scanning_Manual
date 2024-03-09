function obj = CP4Scanner(obj)
test = 1;
if obj.Devinfo.scanner.statue == 1
    warning('scanner is already online, returning')
else
    %  建立TCP/IP通讯（激光位移传感器）
    %   建立对象
    try
        obj.Devinfo.printer.statue = 1;
        obj.Devinfo.scanner.t = tcpip(obj.Devinfo.ip, 24683);
    catch
        obj = DC4Scanner(obj);
        obj = DC4Printer(obj);
        profile = [];
        coordinate = [];
        error("TCPIP对象无法建立")
    end

    set(obj.Devinfo.scanner.t, 'InputBufferSize', 3e4);

    if test
        disp('set tcpip')
    end
    %   连接对象
    try
        fopen(obj.Devinfo.scanner.t);
    catch
        obj = DC4Scanner(obj);
        obj = DC4Printer(obj);
        profile = [];
        coordinate = [];
        error("无法建立链接，请重试")
    end
    while obj.Devinfo.scanner.t.status~='open'
        pause(0.01)                     %等待通讯建立
    end
    if test
        disp('opened tcpip, sensor is online!')
    end
    obj.Devinfo.sacnner.statue=1;
end