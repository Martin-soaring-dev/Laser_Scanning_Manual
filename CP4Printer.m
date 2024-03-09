%   2024-01-26 Martin 用于连接3D打印机
function obj = CP4Printer(obj)
if obj.Devinfo.printer.statue == 1;
    warning('montion control platform is already online, returning')
else
    %%  建立Serial通讯（3D打印机）
    %   列出所有连接的端口号
    spl = serialportlist;
    %   交互式串口通讯
    serial_connection = 0;
    while ~isempty(spl)
        %   列出所有串口，询问退出，或者选择一个端口尝试连接
        disp('Serial Port List:')
        spn_list = 1:length(spl);
        for i=1:length(spl)
            disp([char(num2str(i)),' ',char(spl(i))])
        end
        spn_invalid_flag = 1;
        while spn_invalid_flag == 1
            prompt = 'Please Select a Port and Try to Connect(Type Q/q if you want to quit): ';
            str = input(prompt,'s');
            %   判断输入是否有效
            if contains(str,'Q') || contains(str,'q') %退出
                spn_invalid_flag = 0;
                serial_connection = 0;
                spl=[];
                warning(strcat("放弃建立通讯！"));
            else %选择了一个端口
                % 判断一下输入的数值是否在列表序号范围内
                spn = str2double(str);
                if isempty(find(spn_list==spn)) %不在范围内，警告，并重新输入。
                    spn_invalid_flag = 1;
                    serial_connection = 0;
                    warning(strcat("The serial port number is incorrect. Please try again!"));
                    continue
                else % 在范围内
                    % 选择波特率
                    rate_list = [9600,14400,19200,28800,115200,128000,250000,256000,1000000];
                    disp('Baudrate List:')
                    for i=1:length(rate_list)
                        disp([num2str(i),' ',num2str(rate_list(i))])
                    end
                    input_invalid_flag = 1;
                    while input_invalid_flag==1
                        str_rate = input('Please Select a Baudrate for Connection: ','s');
                        if isempty(str_rate) %输入为空
                            input_invalid_flag = 1;
                            warning('Please Select a Baudrate number!')
                            continue
                        else %有输入
                            rate_num = str2double(str_rate);
                            if isempty(find([1:length(rate_list)],rate_num)) %不在范围内，警告，并重新输入。
                                input_invalid_flag = 1;
                                warning('Baudrate number is incorrect. Please try again!')
                                continue
                            else %在范围内
                                rate = rate_list(rate_num);
                                input_invalid_flag = 0;
                            end
                        end
                    end
                    % 确定了波特率后尝试建立连接
                    try
                        % 成功建立了连接
                        spn_invalid_flag = 0;
                        serial_connection = 1;
                        obj.Devinfo.printer.s = serialport(spl(spn),rate);
                    catch
                        % 出现失败后，清理s，警告，在列表里面把当前端口删除，未成功连接，跳出循环
                        clear obj.Devinfo.printer.s
                        warning(strcat("无法建立",spl(spn),"通讯，尝试连接其他端口"));
                        serial_connection = 0;
                        spn_invalid_flag = 1;
                        spl(spn)=[];
                        break
                    end
                    % 若建立连接，检查一下连接的设备对不对
                    try
                        %                 configureCallback(s,"terminator",@LJ_scom_input);
                        writeline(obj.Devinfo.printer.s,'M999')
                        pause(0.1)
                        t0=cputime;
                        while obj.Devinfo.printer.s.NumBytesAvailable==0 && cputime-t0<=1000
                        end
                        if cputime-t0>=1000
                            error('timeout')
                        else
                            temp = readline(obj.Devinfo.printer.s);
                            if contains(temp,'ok')
                                % ok
                                serial_connection = 1;
                                spn_invalid_flag = 0;
                                spl=[];
                            else
                                temp = readline(obj.Devinfo.printer.s);
                                if contains(temp,'ok')
                                    % ok
                                    spn_invalid_flag = 0;
                                    serial_connection = 1;
                                    spl=[];
                                else
                                    disp(temp)
                                    error('无法连接');
                                end
                            end
                        end
                    catch
                        clear obj.Devinfo.printer.s
                        warning('连接不成功!')
                        serial_connection = 0;
                        spn_invalid_flag = 1;
                        spl(spn)=[];
                        break
                    end
                end
            end
        end
    end
    %   给出连接结果
    switch serial_connection
        case 1
            % disp('成功建立串口通讯!')
            disp('serial port connected, motion platform is online!')
            obj.Devinfo.printer.statue = 1;
        case 0
            clear obj.Devinfo.printer.s
            obj.Devinfo.printer.statue = 0;
            error('无法建立串口通讯!')
    end
end
end