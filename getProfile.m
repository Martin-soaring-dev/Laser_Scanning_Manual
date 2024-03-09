function [coordinate,profile]=getProfile(obj,a)
% 功能:  用作子程序. 输入指令a, 通过全局TCP/IP对象t实现对激光轮廓传感器的通讯并获取数据. 
% 语法:
%   [coordinate,profile]=LJ_G5000_v2_2(a)
%       a:          指令: 
%                       'Pk': 轮廓输出, 如:LJ_G5000('P1')
%                       'Ma': 测量输出, 如:LJ_G5000('M12345678')
%                       'Q1': 通讯模式, 如:LJ_G5000('Q1')
%                       'R0': 测量模式, 如:LJ_G5000('R0')
%                       '  ': 设置读取, 如:
%       coordinate: 轮廓横坐标(X), 单位um
%       profile:    轮廓纵坐标(Z), 单位um

%%  LJ-G0015 Ethernet Communication & Control
%   !arp -a     %查看所有本地IP
%   !netstat    %查看连接状态——获取PORT
% t = tcpclient('192.168.0.101',80);
% t = tcpserver('192.168.0.101',80);
test = 0;
test_flag=0;
test_plot = 0;
test_M_Code = 0;
subfunction=1;
% global t
%%  默认例子
% a = 'P1';
% ip = '192.168.0.101';
%%  例子
%   ('192.168.0.101','P1')
%   LJ_G5000('192.168.0.101','M12345678')
%   LJ_G5000('192.168.0.101','Q1')
%   LJ_G5000('192.168.0.101','R0')
%%  指令格式（参考手册）
%   轮廓输出    Pk  08 00 07 1e xx 00 00 00     xx: 01-headA, 02-headB, 03-计算
%   测量输出    Ma  08 00 07 1a xx 00 00 00     xx: 8bit 00000001 ... 11111111
%   通讯模式    Q1  04 00 07 06
%   测量模式    R0  08 00 07 04 00 00 00 00
%   设置读取
%%  IP设置
% ip = '192.168.0.101';
%%  前处理
switch a(1)
    case 'P'
        if length(a)~=2
            error('指令格式错误')
        end
        switch a(2)
            case '1'
                cmd = ['08' '00' '07' '1E' '00' '00' '00' '00'];
            case '2'
                cmd = ['08' '00' '07' '1E' '01' '00' '00' '00'];
            otherwise
                error('指令号错误')
        end
    case 'M'
        if length(a)~=9
            error('指令格式错误')
        end
        num_out = 0;%2022-01-18 需要输出的测量值数量
        for i=2:9
            if a(i)~='0'&&a(i)~='1'
                error('指令号错误')
            end
            num_out = num_out + str2double(a(i));%2022-01-18 累加需要输出的测量值
        end
        cmd_temp = dec2hex(bin2dec(a(2:9)));
        switch length(cmd_temp)
            case 1
                cmd_temp = ['0',cmd_temp];
            case 2
                cmd_temp = [cmd_temp];
        end
        cmd = ['08' '00' '07' '1A' cmd_temp '00' '00' '00'];
    case 'Q'
        if length(a)~=2
            error('指令格式错误')
        end
        switch a(2)
            case '1'
                cmd = ['04' '00' '07' '06'];
            otherwise
                error('指令号错误')
        end
    case 'R'
        if length(a)~=2
            error('指令格式错误')
        end
        switch a(2)
            case '0'
                cmd = ['08' '00' '07' '04' '00' '00' '00' '00'];
        end
    otherwise
        error('指令代码错误')
end
cmd_temp=[];
for i=1:length(cmd)/2
    cmd_temp(i)=hex2dec(cmd(2*i-1:2*i));
end
%%  参考：http://blog.sina.com.cn/s/blog_66eaee8f01017tca.html
%%  1. Create and configure an instrument object
% TCP/IP object in the MATLAB workspace. Port 80is the standard port for Web
% servers.
% t = tcpip('www.rfc-editor.org', 80);
% By default, the TCP/IP object has an InputBufferSizeof 512 ,whichmeansit
% can only read 512 bytes at a time. The MathWorks Web page data is much
% greater than 512 bytes, so you need to set a larger value for this property.
% set(t, 'InputBufferSize', 30000);
% try
%     t = tcpip(ip, 24683);
% catch
%     warning("TCPIP对象无法建立")
%     fclose(t);
%     delete(t);
%     clear t
%     profile = [];
%     return
% end
% set(t, 'InputBufferSize', 3e4);
% if test
%     disp('tcpip设置完毕')
% end
%%  2. Connect the object
% Next, you open the connection to the server. If the server is not present
% or is not accepting connections you would get an error here.
% try
%     fopen(t);
% catch
%     warning("无法建立链接, 请重试")
%     fclose(t);
%     delete(t);
%     clear t
%     profile = [];
%     return
% end
% if test
%     disp('tcpip已打开')
% end
%%  3.Write and read data
% the functions fprintf, fscanf , fwrite ,and fread.
% To ask a Web server to send a Web page, you use the GET command.
% You can ask for a text file from the RFC Editor Web site using 'GET
% (path/filename)' .
% ;fprintf(t, 'GET /rfc/rfc793.txt')
fprintf(obj.Devinfo.scanner.t,cmd_temp);
if test
    disp('tcpip指令已发送')
end
% The server receives the command and sends back the Web page. You can
% see if any data was sent back by looking at the BytesAvailable property
% of the object.
% get(t, 'BytesAvailable')
% Now you can start to read the Web page data. By default,fscanf reads one
% line at a time. You can read lines of data until the BytesAvailable value is
% 0 . Note that you will not see a rendered web page; the HTML file data will
% scroll by on the screen.
% while (get(t, 'BytesAvailable') > 0)
% A = fscanf(t),
% end
% while (get(t, 'BytesAvailable') > 0)
%     A = fscanf(t)
% % end
% pause(1)
% t
num_data=0;
switch a(1)
    case 'P'
        num_target = 24 + 800 * 4; %2022-01-18 就是3224, 头24位是数据信息, 数据800*4位, 一共3224位;
    case 'M'
        num_target = 20 + num_out * 8;%2022-01-18 头20位是数据信息, 数据一共num_out*8位, 需要根据输入值确定
end
while num_data<num_target
    %     pause(0.01)
    num_data = get(obj.Devinfo.scanner.t,"BytesAvailable");
end
if test
    disp('接收缓存已读取')
end
switch a(1)
    case 'P'
        if num_data>0
            A = fread(obj.Devinfo.scanner.t,num_data);
            if test
                disp('数据已接收')
            end
            %             if num_data~=3224
            if num_data~=num_target % 2022-01-18 统一形式
                error("数据出现丢失, 请重新尝试！")
            end
            try
                [coordinate,profile] = LJ_G5000_P_cmd(obj,A,test_flag);
            catch ME
                disp(ME)
                error('scan failed! abort!');
            end
        end
        
    case 'M'
        if num_data>0
            A = fread(obj.Devinfo.scanner.t,num_data);
            if test
                disp('数据已接收')
            end
            %             if num_data~=3224
            if num_data~=num_target % 2022-01-18 统一形式
                error("数据出现丢失, 请重新尝试！")
            end
            for i=1:5
                for j=1:4
                    temp = dec2hex(A(j+4*(i-1)));
                    temp_length = length(temp);
                    switch temp_length
                        case 1
                            temp = ['0',temp];
                        case 2
                            temp = [temp];
                    end
                    eval(['temp_',num2str(j),' = temp;'])
                end
                if subfunction==0
                    disp([temp_1,temp_2,temp_3,temp_4])
                end
            end
            data_out = zeros (num_out,1);
            symb_out = ones  (num_out,1);
            for i=1:num_out
                for j=1:4
                    temp = dec2bin(A(12+j+8*i));
                    temp_length = length(temp);
                    if test && test_M_Code
                        disp(['12+j+8*i=',num2str(12+j+8*i)])
                    end
                    switch temp_length
                        case 1
                            temp = ['0000000',temp];
                        case 2
                            temp = ['000000',temp];
                        case 3
                            temp = ['00000',temp];
                        case 4
                            temp = ['0000',temp];
                        case 5
                            temp = ['000',temp];
                        case 6
                            temp = ['00',temp];
                        case 7
                            temp = ['0',temp];
                        case 8
                            temp = [temp];
                    end
                    eval(['temp_',num2str(j),' = temp;'])
                end
                temp_0 = [temp_4,temp_3,temp_2,temp_1];
                out_standby = dec2bin(hex2dec('8000000'));
                out_alarm   = dec2bin(hex2dec('7FFFFFF'));
                switch temp_0
                    case out_standby
                        warning(['out',num2str(i),' 状态为：Evaluation Standby！']);
                        data_out(i) = 0;
                        continue
                    case out_alarm
                        warning(['out',num2str(i),' 状6态为：Alarm！']);
                        data_out(i) = 0;
                        continue
                end
                switch temp_0(1)
                    case '0'
                        symb_out(i)=+0;
                    case '1'
                        symb_out(i)=-1;
                end
                temp_0(1:17)=[];
                data_out(i) = bin2dec(temp_0);
            end
            profile=32768*symb_out+data_out;
            if test&&test_M_Code
                for i = 1:num_out
                    disp(['out',num2str(i),'=',num2str(profile(i))])
                end
                disp('结果已输出')
            end
        end
    otherwise
        temp = fread(obj.Devinfo.scanner.t,obj.Devinfo.scanner.t.BytesAvailable);
        temp = [];
end
% %%  4. Disconnect and clean up
% % If you want to do more communication, you can continue to read and write
% % data here. If you are done with the object, close it and delete it.
% fclose(t);
% delete(t);
% clear t
%%  return
return