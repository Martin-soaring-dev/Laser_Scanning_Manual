function [coordinate,profile]=getProfile(obj,a)
% ����:  �����ӳ���. ����ָ��a, ͨ��ȫ��TCP/IP����tʵ�ֶԼ���������������ͨѶ����ȡ����. 
% �﷨:
%   [coordinate,profile]=LJ_G5000_v2_2(a)
%       a:          ָ��: 
%                       'Pk': �������, ��:LJ_G5000('P1')
%                       'Ma': �������, ��:LJ_G5000('M12345678')
%                       'Q1': ͨѶģʽ, ��:LJ_G5000('Q1')
%                       'R0': ����ģʽ, ��:LJ_G5000('R0')
%                       '  ': ���ö�ȡ, ��:
%       coordinate: ����������(X), ��λum
%       profile:    ����������(Z), ��λum

%%  LJ-G0015 Ethernet Communication & Control
%   !arp -a     %�鿴���б���IP
%   !netstat    %�鿴����״̬������ȡPORT
% t = tcpclient('192.168.0.101',80);
% t = tcpserver('192.168.0.101',80);
test = 0;
test_flag=0;
test_plot = 0;
test_M_Code = 0;
subfunction=1;
% global t
%%  Ĭ������
% a = 'P1';
% ip = '192.168.0.101';
%%  ����
%   ('192.168.0.101','P1')
%   LJ_G5000('192.168.0.101','M12345678')
%   LJ_G5000('192.168.0.101','Q1')
%   LJ_G5000('192.168.0.101','R0')
%%  ָ���ʽ���ο��ֲᣩ
%   �������    Pk  08 00 07 1e xx 00 00 00     xx: 01-headA, 02-headB, 03-����
%   �������    Ma  08 00 07 1a xx 00 00 00     xx: 8bit 00000001 ... 11111111
%   ͨѶģʽ    Q1  04 00 07 06
%   ����ģʽ    R0  08 00 07 04 00 00 00 00
%   ���ö�ȡ
%%  IP����
% ip = '192.168.0.101';
%%  ǰ����
switch a(1)
    case 'P'
        if length(a)~=2
            error('ָ���ʽ����')
        end
        switch a(2)
            case '1'
                cmd = ['08' '00' '07' '1E' '00' '00' '00' '00'];
            case '2'
                cmd = ['08' '00' '07' '1E' '01' '00' '00' '00'];
            otherwise
                error('ָ��Ŵ���')
        end
    case 'M'
        if length(a)~=9
            error('ָ���ʽ����')
        end
        num_out = 0;%2022-01-18 ��Ҫ����Ĳ���ֵ����
        for i=2:9
            if a(i)~='0'&&a(i)~='1'
                error('ָ��Ŵ���')
            end
            num_out = num_out + str2double(a(i));%2022-01-18 �ۼ���Ҫ����Ĳ���ֵ
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
            error('ָ���ʽ����')
        end
        switch a(2)
            case '1'
                cmd = ['04' '00' '07' '06'];
            otherwise
                error('ָ��Ŵ���')
        end
    case 'R'
        if length(a)~=2
            error('ָ���ʽ����')
        end
        switch a(2)
            case '0'
                cmd = ['08' '00' '07' '04' '00' '00' '00' '00'];
        end
    otherwise
        error('ָ��������')
end
cmd_temp=[];
for i=1:length(cmd)/2
    cmd_temp(i)=hex2dec(cmd(2*i-1:2*i));
end
%%  �ο���http://blog.sina.com.cn/s/blog_66eaee8f01017tca.html
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
%     warning("TCPIP�����޷�����")
%     fclose(t);
%     delete(t);
%     clear t
%     profile = [];
%     return
% end
% set(t, 'InputBufferSize', 3e4);
% if test
%     disp('tcpip�������')
% end
%%  2. Connect the object
% Next, you open the connection to the server. If the server is not present
% or is not accepting connections you would get an error here.
% try
%     fopen(t);
% catch
%     warning("�޷���������, ������")
%     fclose(t);
%     delete(t);
%     clear t
%     profile = [];
%     return
% end
% if test
%     disp('tcpip�Ѵ�')
% end
%%  3.Write and read data
% the functions fprintf, fscanf , fwrite ,and fread.
% To ask a Web server to send a Web page, you use the GET command.
% You can ask for a text file from the RFC Editor Web site using 'GET
% (path/filename)' .
% ;fprintf(t, 'GET /rfc/rfc793.txt')
fprintf(obj.Devinfo.scanner.t,cmd_temp);
if test
    disp('tcpipָ���ѷ���')
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
        num_target = 24 + 800 * 4; %2022-01-18 ����3224, ͷ24λ��������Ϣ, ����800*4λ, һ��3224λ;
    case 'M'
        num_target = 20 + num_out * 8;%2022-01-18 ͷ20λ��������Ϣ, ����һ��num_out*8λ, ��Ҫ��������ֵȷ��
end
while num_data<num_target
    %     pause(0.01)
    num_data = get(obj.Devinfo.scanner.t,"BytesAvailable");
end
if test
    disp('���ջ����Ѷ�ȡ')
end
switch a(1)
    case 'P'
        if num_data>0
            A = fread(obj.Devinfo.scanner.t,num_data);
            if test
                disp('�����ѽ���')
            end
            %             if num_data~=3224
            if num_data~=num_target % 2022-01-18 ͳһ��ʽ
                error("���ݳ��ֶ�ʧ, �����³��ԣ�")
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
                disp('�����ѽ���')
            end
            %             if num_data~=3224
            if num_data~=num_target % 2022-01-18 ͳһ��ʽ
                error("���ݳ��ֶ�ʧ, �����³��ԣ�")
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
                        warning(['out',num2str(i),' ״̬Ϊ��Evaluation Standby��']);
                        data_out(i) = 0;
                        continue
                    case out_alarm
                        warning(['out',num2str(i),' ״6̬Ϊ��Alarm��']);
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
                disp('��������')
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