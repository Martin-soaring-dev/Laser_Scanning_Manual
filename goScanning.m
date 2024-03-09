% function [X_profile, Y_profile, Z_profile] = LJ_Control(c, ip, sn, rate, x_offset, y_offset, z_offset)
function obj = goScanning(obj)
%   功能:     用于调用位置点前处理，建立和断开通讯（TCPIP和Serial通讯），以及控制激光位移传感器和3D打印机。
%   更新1:    增加对3D打印机的运动控制，可以不使用上位机直接打印：通过设置串口通讯中断，当返回值为ok时，向打印机发送指令，当范围值为wait时，等候执行再发送指令。
%   更新2:    配合重新编写的数据处理程序，能够适应LJG015和LLJG030两种测头。
%   更新3:    为了适应多种平台，扩展了偏置的维度到6轴，已适用于多轴打印机的打印于扫描。
%   2024-01-22： 
%   1.  LJ_Interpolation_V2_0()于2023-02-17 更新，增加加密扫描段标号，但是在后面的数据处理中并未用到，这里用起来
%   2.  需要重构数据类型LJ_data，从而把所有的数据全部整合起来，而不是全部散装在工作区内：
%%  依赖关系判断
if obj.syset.flags.read_flag_trajectory~=1
    error('has not getTrajectory yet!')
end
%%  调试设置
test       = obj.syset.flags.test_flag;             %全局测试标志
test_inplt = 0;             %密化函数跳过标志
%%  初始化
% c  = obj.Devinfo.inplt; %mm
% axis_mode = [1 1 1 0 0 0];
% struct_type = 3;    %机型设置：1. 112实验室；2.113实验室五轴；3.NUS平台
% 2024-01-22 结构系数写在这就行了
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
LJ_data = struct;   % 2024-01-22 重构数据格式
%  每次此前一定要记得测量偏置！！！！！！
offset = obj.Devinfo.scanner.scanneroffset;
x_offset=offset(1);
y_offset=offset(2);
z_offset=offset(3);
a_offset=offset(4);
b_offset=offset(5);
c_offset=offset(6);
%  对路径点做密化处理并校验行数是否一致
File_Type = 1;
if test_inplt
    File_Type = 0;
end
%   FileType：  0      1
%               none   .mat
switch File_Type
    case 0  %测试用
        obj.TJ_data.TJ4Scan.X_LJ = [1;    2;    3;    4;    5;    6;    7;    8;    9;    10   ];
        obj.TJ_data.TJ4Scan.Y_LJ = [10;   10;   10;   10;   10;   10;   10;   10;   10;   10   ];
        obj.TJ_data.TJ4Scan.Z_LJ = [0.6;  0.6;  0.6;  0.6;  0.6;  0.6;  0.6;  0.6;  0.6;  0.6  ];
        obj.TJ_data.TJ4Scan.F_LJ = [3000; 3000; 3000; 3000; 3000; 3000; 3000; 3000; 3000; 3000 ];
        obj.TJ_data.TJ4Scan.S_LJ = [-1;   1;    1;    1;    1;    2;    2;    2;    2;    -1   ];
    case 1  %采用.mat文件 2022-01-15 更新; 2023-02-17 更新，增加加密扫描段标号
        % 2024-01-27 Martin 预留坐标变换函数
        % p2 = Homo_coordi_trans(p1,offset1,offset2,mode)
        % [obj.TJ_data.TJ4Scan.X_LJ, obj.TJ_data.TJ4Scan.Y_LJ, obj.TJ_data.TJ4Scan.Z_LJ, obj.TJ_data.TJ4Scan.F_LJ, obj.TJ_data.TJ4Scan.S_LJ] = obj.goInterpolation();
        %   2024-01-27 Martin 插值处理
        obj = goInterpolation(obj);
end
if length(obj.TJ_data.TJ4Scan.X_LJ)~=length(obj.TJ_data.TJ4Scan.Y_LJ) || length(obj.TJ_data.TJ4Scan.Y_LJ)~=length(obj.TJ_data.TJ4Scan.Z_LJ) || length(obj.TJ_data.TJ4Scan.Z_LJ)~=length(obj.TJ_data.TJ4Scan.F_LJ) || length(obj.TJ_data.TJ4Scan.F_LJ)~=length(obj.TJ_data.TJ4Scan.S_LJ)
    error("坐标长度不一致，程序终止！")
end
%%  建立Serial通讯（3D打印机）
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
%%  建立TCP/IP通讯（激光位移传感器）
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
%%  开始控制3D打印机及激光位移传感器进行测量
L = length(obj.TJ_data.TJ4Scan.X_LJ);                                           %读取点的数量
profile   = NaN(L, 800);                                    %建立轮廓变量
X_profile = NaN(L, 800);                                    %初始化轮廓点
Y_profile = NaN(L, 800);
Z_profile = NaN(L, 800);
Current_Position = [0;0;0];                                 %设置默认当前点
T = 10;                                                     %设置默认等待时间
T2= 100 *1e-3;                                              %预计等待时间
k = 1.00;                                                   %设置等待时间系数
writeline(obj.Devinfo.printer.s,"G90");                     %使用绝对坐标模式
writeline(obj.Devinfo.printer.s,"G28");                     %先让3D打印机回零
f = waitbar(0,'Please wait...');                            %设置进度条
pause(T);                                                   %等打印机回零
waitbar_factor = 10;                                        %进度条，每循环X次更新一次（用以提升代码运行速度）
%   开始循环！
for i=1:L
    if rem(i,waitbar_factor)==1
        %   每间隔waitbar_factor次循环更新一次进度条（用以提升代码运行速度）
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
    %   2024-01-22 增加一个依据S_LJ的判断，如果为非正则跳过
    if obj.TJ_data.TJ4Scan.S_LJ(i)>0    %  只需要提取感兴趣的点
        %     2023-01-07 这里更新为LJ_G5000_v2_2，重新编写了数据处理部分，修复了之前的BUG
        try
            [coordinate_temp,profile_temp] = getProfile(obj,'P1'); %    单位 um
        catch ME
            disp(ME)
            pause(1)
            disp('retry')
            try
            [coordinate_temp,profile_temp] = getProfile(obj,'P1'); %    单位 um
            catch ME
                disp(ME)
                disp('abort!')
                obj = DC4Scanner(obj);
                obj = DC4Printer(obj);
                error('scan failed!');
            end
        end
        num_data = length(profile_temp);
        %   2024-01-22 在初始化阶段直接计算结构系数
        X_profile(i,:) = obj.TJ_data.TJ4Scan.X_LJ(i);
        Y_profile(i,:) = obj.TJ_data.TJ4Scan.Y_LJ(i)+obj.Devinfo.scanner.structure_factor*coordinate_temp*1e-3;
        Z_profile(i,:) = profile_temp*1e-3;
        %   2024-01-22 更新结束
    end
    % 2024-01-22 更新结束
    Current_Position = Target_Position;
end
% %   2022-01-18 第一次扫描（前800个点）会影响扫描结果，应当删除
% X_profile(1:800) = [];
% Y_profile(1:800) = [];
% Z_profile(1:800) = [];
time = 1;
waitbar(1,f,['Finishing！！！...The window will be closed in '],num2str(time),' second.');
pause(time)
close(f)
%%  先断开连接再处理数据
obj = DC4Scanner(obj);
obj = DC4Printer(obj);
disp('closed tcpip')
disp('closed serial port')
%%  结构体数据重构
cpmode(2);
for i = 1:length(obj.TJ_data.TJ4Scan.X_LJ)
    LJ_data(i).SN                 = i;
    LJ_data(i).Scan_Traj_X        = obj.TJ_data.TJ4Scan.X_LJ(i);
    LJ_data(i).Scan_Traj_Y        = obj.TJ_data.TJ4Scan.Y_LJ(i);
    LJ_data(i).Scan_Traj_Z        = obj.TJ_data.TJ4Scan.Z_LJ(i);
    LJ_data(i).Scan_Traj_F        = obj.TJ_data.TJ4Scan.F_LJ(i);
    LJ_data(i).Scan_Traj_S        = obj.TJ_data.TJ4Scan.S_LJ(i);
    LJ_data(i).profile_coordinate = (Y_profile(i,:)-obj.TJ_data.TJ4Scan.Y_LJ(i))/structure_factor;  %   单位mm
    LJ_data(i).profile_curve      = Z_profile(i,:);                             %   单位mm
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
%%  结束与标记
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
%     %   把结构体中的数据转为数组的demo
%     obj.TJ_data.TJ4Scan.S_LJ = [obj.LJ_data.Scan_Traj_S]';
%     LJ_data = [obj.LJ_data.SN; obj.LJ_data.Scan_Traj_X; obj.LJ_data.Scan_Traj_Y; obj.LJ_data.Scan_Traj_Z; obj.LJ_data.Scan_Traj_F; obj.LJ_data.Scan_Traj_S].';
%     clear obj.TJ_data.TJ4Scan.S_LJ LJ_data
% end
% %%  对结果进行处理和封装
% plot_flag = [0 1 0 0];
% %   plot_flag不同位数代表的绘图内容：
% %   1   投影到平面上
% %   2   散点图
% %   3   优化的散点图和灰度图
% %   4   通过散点数据拟合曲面
% version_p2 = 5;
% %   2024-01-22 散点图版本： 
% %   1   plot3       绘制散点
% %   2   scatter3    以高度为颜色绘制散点
% %   3   pcshow      点云可视化（更快更方便）
% %   4   pcview      交互功能更全（需要MATLAB 2023a及更新版本）
% %   5   ptCloud.plot使用Point Cloud Tools for MATLAB绘图
% %   2024-01-23  添加了"Point cloud tools for Matlab"工具箱，
% %               这个工具箱与MATLAB自带的"Computer Vision Toolbox"冲突
% %               1. 在startup.m中增加了提示语句
% %               2. 对于3 4的情况，增加了try catch语句，当调用"Computer Vision Toolbox"失败时，使用"Point cloud tools for Matlab"绘图
% %   2024-01-24  增加了cpmode()函数，通过控制工作路径选择使用工具箱，因此不需要再3-4的情况下做判断了
% x_profile = reshape(X_profile,[],1);
% y_profile = reshape(Y_profile,[],1);
% z_profile = reshape(Z_profile,[],1);
% %   for MSEC 2023-11-13
%     %   为MSEC论文专门生成图像，如果需要运行请手动取消下一行的注释，请记得用完了重新注释。
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
%     seg = 0.1;%精度mm
%     %   剔除无效点
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