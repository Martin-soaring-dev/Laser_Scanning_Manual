% function [X_profile, Y_profile, Z_profile] = LJ_Control(c, ip, sn, rate, x_offset, y_offset, z_offset)
function obj = goScanning(obj)
%   ����:     ���ڵ���λ�õ�ǰ���������ͶϿ�ͨѶ��TCPIP��SerialͨѶ�����Լ����Ƽ���λ�ƴ�������3D��ӡ����
%   ����1:    ���Ӷ�3D��ӡ�����˶����ƣ����Բ�ʹ����λ��ֱ�Ӵ�ӡ��ͨ�����ô���ͨѶ�жϣ�������ֵΪokʱ�����ӡ������ָ�����ΧֵΪwaitʱ���Ⱥ�ִ���ٷ���ָ�
%   ����2:    ������±�д�����ݴ�������ܹ���ӦLJG015��LLJG030���ֲ�ͷ��
%   ����3:    Ϊ����Ӧ����ƽ̨����չ��ƫ�õ�ά�ȵ�6�ᣬ�������ڶ����ӡ���Ĵ�ӡ��ɨ�衣
%   2024-01-22�� 
%   1.  LJ_Interpolation_V2_0()��2023-02-17 ���£����Ӽ���ɨ��α�ţ������ں�������ݴ����в�δ�õ�������������
%   2.  ��Ҫ�ع���������LJ_data���Ӷ������е�����ȫ������������������ȫ��ɢװ�ڹ������ڣ�
%%  ������ϵ�ж�
if obj.syset.flags.read_flag_trajectory~=1
    error('has not getTrajectory yet!')
end
%%  ��������
test       = obj.syset.flags.test_flag;             %ȫ�ֲ��Ա�־
test_inplt = 0;             %�ܻ�����������־
%%  ��ʼ��
% c  = obj.Devinfo.inplt; %mm
% axis_mode = [1 1 1 0 0 0];
% struct_type = 3;    %�������ã�1. 112ʵ���ң�2.113ʵ�������᣻3.NUSƽ̨
% 2024-01-22 �ṹϵ��д���������
structure_factor = obj.Devinfo.scanner.structure_factor;
% switch struct_type
%     case 1
%         structure_factor = -1;
%     case 2
%         structure_factor = 1;
%     case 3
%         structure_factor = -1;
%     otherwise
%         warning('unknow device, set structure_factor as default value')
% end
LJ_data = struct;   % 2024-01-22 �ع����ݸ�ʽ
%  ÿ�δ�ǰһ��Ҫ�ǵò���ƫ�ã�����������
offset = obj.Devinfo.scanner.scanneroffset;
x_offset=offset(1);
y_offset=offset(2);
z_offset=offset(3);
a_offset=offset(4);
b_offset=offset(5);
c_offset=offset(6);
%  ��·�������ܻ�����У�������Ƿ�һ��
File_Type = 1;
if test_inplt
    File_Type = 0;
end
%   FileType��  0      1
%               none   .mat
switch File_Type
    case 0  %������
        obj.TJ_data.TJ4Scan.X_LJ = [1;    2;    3;    4;    5;    6;    7;    8;    9;    10   ];
        obj.TJ_data.TJ4Scan.Y_LJ = [10;   10;   10;   10;   10;   10;   10;   10;   10;   10   ];
        obj.TJ_data.TJ4Scan.Z_LJ = [0.6;  0.6;  0.6;  0.6;  0.6;  0.6;  0.6;  0.6;  0.6;  0.6  ];
        obj.TJ_data.TJ4Scan.F_LJ = [3000; 3000; 3000; 3000; 3000; 3000; 3000; 3000; 3000; 3000 ];
        obj.TJ_data.TJ4Scan.S_LJ = [-1;   1;    1;    1;    1;    2;    2;    2;    2;    -1   ];
    case 1  %����.mat�ļ� 2022-01-15 ����; 2023-02-17 ���£����Ӽ���ɨ��α��
        % 2024-01-27 Martin Ԥ������任����
        % p2 = Homo_coordi_trans(p1,offset1,offset2,mode)
        % [obj.TJ_data.TJ4Scan.X_LJ, obj.TJ_data.TJ4Scan.Y_LJ, obj.TJ_data.TJ4Scan.Z_LJ, obj.TJ_data.TJ4Scan.F_LJ, obj.TJ_data.TJ4Scan.S_LJ] = obj.goInterpolation();
        %   2024-01-27 Martin ��ֵ����
        obj = goInterpolation(obj);
end
if length(obj.TJ_data.TJ4Scan.X_LJ)~=length(obj.TJ_data.TJ4Scan.Y_LJ) || length(obj.TJ_data.TJ4Scan.Y_LJ)~=length(obj.TJ_data.TJ4Scan.Z_LJ) || length(obj.TJ_data.TJ4Scan.Z_LJ)~=length(obj.TJ_data.TJ4Scan.F_LJ) || length(obj.TJ_data.TJ4Scan.F_LJ)~=length(obj.TJ_data.TJ4Scan.S_LJ)
    error("���곤�Ȳ�һ�£�������ֹ��")
end
%%  ����SerialͨѶ��3D��ӡ����
try
    obj = CP4Printer(obj);
catch ME
    try
        tmtool;
    catch
        serialExplorer;
    end
    disp(ME)
    error('please clear object by tmtool manually')
end
%%  ����TCP/IPͨѶ������λ�ƴ�������
try
    obj = CP4Scanner(obj);
catch ME
    try
        tmtool;
    catch
        tcpipExplorer;
    end
    disp(ME)
    error('please clear object by tmtool manually')
end
%%  ��ʼ����3D��ӡ��������λ�ƴ��������в���
L = length(obj.TJ_data.TJ4Scan.X_LJ);                                           %��ȡ�������
profile   = NaN(L, 800);                                    %������������
X_profile = NaN(L, 800);                                    %��ʼ��������
Y_profile = NaN(L, 800);
Z_profile = NaN(L, 800);
Current_Position = [0;0;0];                                 %����Ĭ�ϵ�ǰ��
T = 10;                                                     %����Ĭ�ϵȴ�ʱ��
T2= 100 *1e-3;                                              %Ԥ�Ƶȴ�ʱ��
k = 1.00;                                                   %���õȴ�ʱ��ϵ��
writeline(obj.Devinfo.printer.s,"G90");                     %ʹ�þ�������ģʽ
writeline(obj.Devinfo.printer.s,"G28");                     %����3D��ӡ������
f = waitbar(0,'Please wait...');                            %���ý�����
pause(T);                                                   %�ȴ�ӡ������
waitbar_factor = 10;                                        %��������ÿѭ��X�θ���һ�Σ������������������ٶȣ�
%   ��ʼѭ����
for i=1:L
    if rem(i,waitbar_factor)==1
        %   ÿ���waitbar_factor��ѭ������һ�ν������������������������ٶȣ�
        waitbar(i/L,f,['Scaning...',num2str(100*i/L,'%.2f'),'% (',num2str(i),' of ',num2str(L),')']);
    end
    Target_Position = [obj.TJ_data.TJ4Scan.X_LJ(i); obj.TJ_data.TJ4Scan.Y_LJ(i); obj.TJ_data.TJ4Scan.Z_LJ(i)];
    feed_rate    = obj.TJ_data.TJ4Scan.F_LJ(i);%mm/min
    distance = sqrt(sum((Target_Position-Current_Position).^2));
    T = distance*60/feed_rate;
    cmd =       ['G01 X',num2str(Target_Position(1)+x_offset,'%.3f'),...
        ' Y',num2str(Target_Position(2)+y_offset,'%.3f'),...
        ' Z',num2str(Target_Position(3)+z_offset,'%.3f'),...
        ' F',num2str(feed_rate)];
    writeline(obj.Devinfo.printer.s,cmd);
    pause(T*k+T2);
    %   2024-01-22 ����һ������S_LJ���жϣ����Ϊ����������
    if obj.TJ_data.TJ4Scan.S_LJ(i)>0    %  ֻ��Ҫ��ȡ����Ȥ�ĵ�
        %     2023-01-07 �������ΪLJ_G5000_v2_2�����±�д�����ݴ����֣��޸���֮ǰ��BUG
        try
            [coordinate_temp,profile_temp] = getProfile(obj,'P1'); %    ��λ um
        catch ME
            disp(ME)
            pause(1)
            disp('retry')
            try
            [coordinate_temp,profile_temp] = getProfile(obj,'P1'); %    ��λ um
            catch ME
                disp(ME)
                disp('abort!')
                obj = DC4Scanner(obj);
                obj = DC4Printer(obj);
                error('scan failed!');
            end
        end
        num_data = length(profile_temp);
        %   2024-01-22 �ڳ�ʼ���׶�ֱ�Ӽ���ṹϵ��
        X_profile(i,:) = obj.TJ_data.TJ4Scan.X_LJ(i);
        Y_profile(i,:) = obj.TJ_data.TJ4Scan.Y_LJ(i)+obj.Devinfo.scanner.structure_factor*coordinate_temp*1e-3;
        Z_profile(i,:) = profile_temp*1e-3;
        %   2024-01-22 ���½���
    end
    % 2024-01-22 ���½���
    Current_Position = Target_Position;
end
% %   2022-01-18 ��һ��ɨ�裨ǰ800���㣩��Ӱ��ɨ������Ӧ��ɾ��
% X_profile(1:800) = [];
% Y_profile(1:800) = [];
% Z_profile(1:800) = [];
time = 1;
waitbar(1,f,['Finishing������...The window will be closed in '],num2str(time),' second.');
pause(time)
close(f)
%%  �ȶϿ������ٴ�������
obj = DC4Scanner(obj);
obj = DC4Printer(obj);
disp('closed tcpip')
disp('closed serial port')
%%  �ṹ�������ع�
cpmode(2);
for i = 1:length(obj.TJ_data.TJ4Scan.X_LJ)
    LJ_data(i).SN                 = i;
    LJ_data(i).Scan_Traj_X        = obj.TJ_data.TJ4Scan.X_LJ(i);
    LJ_data(i).Scan_Traj_Y        = obj.TJ_data.TJ4Scan.Y_LJ(i);
    LJ_data(i).Scan_Traj_Z        = obj.TJ_data.TJ4Scan.Z_LJ(i);
    LJ_data(i).Scan_Traj_F        = obj.TJ_data.TJ4Scan.F_LJ(i);
    LJ_data(i).Scan_Traj_S        = obj.TJ_data.TJ4Scan.S_LJ(i);
    LJ_data(i).profile_coordinate = (Y_profile(i,:)-obj.TJ_data.TJ4Scan.Y_LJ(i))/structure_factor;  %   ��λmm
    LJ_data(i).profile_curve      = Z_profile(i,:);                             %   ��λmm
end
obj.LJ_data = LJ_data;
groups = unique(obj.TJ_data.TJ4Scan.S_LJ);
groups = groups(find(groups>0));
for i=1:length(groups)
    temp_n = find(obj.TJ_data.TJ4Scan.S_LJ==groups(i));
    temp_X = X_profile(temp_n,:);
    temp_Y = Y_profile(temp_n,:);
    temp_Z = Z_profile(temp_n,:);
    temp_x = reshape(temp_X,[],1);
    temp_y = reshape(temp_Y,[],1);
    temp_z = reshape(temp_Z,[],1);
    obj.PC_data(i).pc=pointCloud([temp_x,temp_y,temp_z]);
    obj.PC_data(i).groups = groups(i);
    obj.PC_data(i).pc.plot;
end
clear LJ_data;
save(['Laser_scan_',char(datetime("today")),'.mat'],'obj')
disp(['file "Laser_scan_',char(datetime("today")),'.mat" has been saved, remember to rename if you need to generate other files.'])
% pause(1)
% close
%%  ��������
obj.syset.flags.read_flag_scaner = 1;
end
% %%   demo
% if 0
%     L=length(obj.LJ_data);
%     X_profile = NaN(L, 800);
%     Y_profile = NaN(L, 800);
%     Z_profile = NaN(L, 800);
%     for i=1:L
%         % disp(i)
%         X_profile(i,:) = obj.LJ_data(i).Scan_Traj_X*ones(1,800);
%         Y_profile(i,:) = obj.LJ_data(i).Scan_Traj_Y+obj.Devinfo.structure_factor*obj.LJ_data(i).profile_coordinate;
%         Z_profile(i,:) = obj.LJ_data(i).profile_curve;
%     end
%     %   �ѽṹ���е�����תΪ�����demo
%     obj.TJ_data.TJ4Scan.S_LJ = [obj.LJ_data.Scan_Traj_S]';
%     LJ_data = [obj.LJ_data.SN; obj.LJ_data.Scan_Traj_X; obj.LJ_data.Scan_Traj_Y; obj.LJ_data.Scan_Traj_Z; obj.LJ_data.Scan_Traj_F; obj.LJ_data.Scan_Traj_S].';
%     clear obj.TJ_data.TJ4Scan.S_LJ LJ_data
% end
% %%  �Խ�����д���ͷ�װ
% plot_flag = [0 1 0 0];
% %   plot_flag��ͬλ������Ļ�ͼ���ݣ�
% %   1   ͶӰ��ƽ����
% %   2   ɢ��ͼ
% %   3   �Ż���ɢ��ͼ�ͻҶ�ͼ
% %   4   ͨ��ɢ�������������
% version_p2 = 5;
% %   2024-01-22 ɢ��ͼ�汾�� 
% %   1   plot3       ����ɢ��
% %   2   scatter3    �Ը߶�Ϊ��ɫ����ɢ��
% %   3   pcshow      ���ƿ��ӻ�����������㣩
% %   4   pcview      �������ܸ�ȫ����ҪMATLAB 2023a�����°汾��
% %   5   ptCloud.plotʹ��Point Cloud Tools for MATLAB��ͼ
% %   2024-01-23  �����"Point cloud tools for Matlab"�����䣬
% %               �����������MATLAB�Դ���"Computer Vision Toolbox"��ͻ
% %               1. ��startup.m����������ʾ���
% %               2. ����3 4�������������try catch��䣬������"Computer Vision Toolbox"ʧ��ʱ��ʹ��"Point cloud tools for Matlab"��ͼ
% %   2024-01-24  ������cpmode()������ͨ�����ƹ���·��ѡ��ʹ�ù����䣬��˲���Ҫ��3-4����������ж���
% x_profile = reshape(X_profile,[],1);
% y_profile = reshape(Y_profile,[],1);
% z_profile = reshape(Z_profile,[],1);
% %   for MSEC 2023-11-13
%     %   ΪMSEC����ר������ͼ�������Ҫ�������ֶ�ȡ����һ�е�ע�ͣ���ǵ�����������ע�͡�
%     flag_MESC = 0;
%     if flag_MESC ~=0
%         switch flag_MESC
%             case 1
%                 x_profile = reshape(X_profile(1:542,:),[],1);
%                 y_profile = reshape(Y_profile(1:542,:),[],1);
%                 z_profile = reshape(Z_profile(1:542,:),[],1);
%                 z_profile = z_profile - min(z_profile);
%         end
%     end
% if plot_flag(1)==1
%     figure(1)
%     scatter(x_profile,y_profile,8,z_profile,'filled')
%     xlabel('X [mm]','FontSize',12,'FontName','Times New Roman')
%     ylabel('Y [mm]','FontSize',12,'FontName','Times New Roman')
%     set(gca,'FontName','Times New Roman')
% %     grid on
%     colorbar
%     axis equal
% end
% if plot_flag(2)==1
%     figure(2)
%     switch version_p2
%         case 1
%             %   plot3
%             plot3(x_profile,y_profile,z_profile,'b.','MarkerSize',0.5)
%             xlabel('X [mm]','FontSize',12,'FontName','Times New Roman')
%             ylabel('Y [mm]','FontSize',12,'FontName','Times New Roman')
%             zlabel('Z [mm]','FontSize',12,'FontName','Times New Roman')
%             axis equal
%             f2 = gca;
%             set(f2,'FontName','Times New Roman')
%         case 2
%             %   scatter3
%             scatter3(x_profile,y_profile,z_profile,1,z_profile,"filled")
%             xlabel('X [mm]','FontSize',12,'FontName','Times New Roman')
%             ylabel('Y [mm]','FontSize',12,'FontName','Times New Roman')
%             zlabel('Z [mm]','FontSize',12,'FontName','Times New Roman')
%             axis equal
%             f2 = gca;
%             set(f2,'FontName','Times New Roman')
%         case 3
%             %   pointcloud 2024-01-22
%             for i = 1:2
%                 switch i
%                     case 1
%                         cpmode(1);  %    Use Computer Vision Toolbox
%                     case 2
%                         ptCloud = pointCloud([x_profile,y_profile,z_profile]);
%                         try pcshow(ptCloud)
%                         catch ME1
%                             disp('There is a conflict between "Computer Vision Toolbox" and "Point cloud tools for Matlab"')
%                             disp('Now trying "Point cloud tools for Matlab" toolbox')
%                             try ptCloud.plot;
%                                 close(2)
%                             catch M2
%                             end
%                         end
%                 end
%             end
%         case 4
%             %   pointcloud 2024-01-22
%             close(2)
%             cpmode(1);  %    Use Computer Vision Toolbox
%             ptCloud = pointCloud([x_profile,y_profile,z_profile]);
%             try pcviewer(ptCloud);
%             catch ME1
%                 disp('There is a conflict between "Computer Vision Toolbox" and "Point cloud tools for Matlab"')
%                 disp('Now trying "Point cloud tools for Matlab" toolbox')
%                 try ptCloud.plot;
%                 catch M2
%                 end
%             end
%         case 5
%             %   Use Point Cloud Tools for MATLAB
%             cpmode(2);  %    Use Point Cloud Tools for MATLAB
%             ptCloud = pointCloud([x_profile,y_profile,z_profile]);
%             ptCloud.plot;
%     end
% end
% if plot_flag(3)==1
%     Temp = z_profile;
%     Temp(find(Temp<-4))=-4;
%     Temp(find(Temp>4))=4;
%     a = round(y_profile*1000+1);
%     b = round(x_profile/c+1);
%     z = Temp+4;
%     a_list = unique(a);
%     b_list = unique(b);
%     a_length = length(a_list);
%     b_length = length(b_list);
%     A = zeros (length(a_list),length(b_list));
%     for i=1:length(a)
%         a_pos = a_length-find(a_list==a(i))+1;
%         b_pos = find(b_list==b(i));
%         A(a_pos,b_pos)=z(i);
%     end
%     % A=A/max(max(A));
%     A=mat2gray(A);
%     % for i = 1:length(X_profile)
%     %     a = round(Y_profile(i)*1000+1);
%     %     b = round(X_profile(i)/c+1);
%     %     A(a,b)=round(Z_profile(i)*255/8);
%     % end
%     figure(3)
%     plot3(b,a,z,'b.','MarkerSize',0.5)
%     axis equal
%     figure(4)
%     imshow(A)
% end
% if plot_flag(4)==1
%     figure(5)
%     seg = 0.1;%����mm
%     %   �޳���Ч��
%     snxyz = ~isnan(x_profile) & ~isnan(y_profile) & ~isnan(z_profile);
%     xlin = linspace(min(x_profile),max(x_profile),round((max(x_profile)-min(x_profile))/seg));
%     ylin = linspace(min(y_profile),max(y_profile),round((max(y_profile)-min(y_profile))/seg));
%     [X,Y] = meshgrid(xlin,ylin);
%     Z = griddata(x_profile(snxyz),y_profile(snxyz),z_profile(snxyz),X,Y, 'cubic');
%     %     meshc(X,Y,Z);
%     surfc(X,Y,Z,'EdgeColor','none');
%     axis equal
%     colorbar
%     xlabel('X [mm]','FontSize',12,'FontName','Times New Roman')
%     ylabel('Y [mm]','FontSize',12,'FontName','Times New Roman')
%     zlabel('Z [mm]','FontSize',12,'FontName','Times New Roman')
%     set(gca,'FontName','Times New Roman')
% end