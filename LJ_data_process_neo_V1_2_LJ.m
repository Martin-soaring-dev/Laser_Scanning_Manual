% function [LJ_processed_data] = LJ_data_process_V1_2(type,num)
%   用于处理扫描得到的数据
%   测试：LJ_data_2023-01-14-120Degree.mat
%   LJ_data_process_V1_0(0,20) %这是个特殊情况，线条顶端有下凹的部分，需要特别处理
%   LJ_data_process_V1_0(0,24) %这是个特殊情况，程序错误，已经修正
%   LJ_data_process_V1_0(0,200)
%   LJ_data_process_V1_0(0,780)
%   LJ_data_process_V1_0(0,820)
%   type=1;
%   num=1;
%   test_flag=0;
%   Updated on 2023-12-09:
%       1. Modified trajecory are fitted as Cubic Spline by csaps().
%       2. Control Points are extracted from spline and saved in My_Curve.
%       3. G05 is added to generate Gcode.
%       4. Gcode generating is modularized as a function.
%   Updated on 2024-01-23:
%       1.  Changed data to "Laser_Scan_yyyy-yy-mm-Prameter.mat", which
%           contains Laser_Scan (struct).
%       2.  (1) Modify Point Cloud; 
%           (2) Change to Points and fit a surface, then to profiles.
%       3.

%%   初始化
test_flag = 0;
plot_flag2 = 1;     %绘图标志位
plot_flag3 = 0;     %优化参数绘图标志位
test_d_cmd_flag=0;  %G05代码测试
set_width = 1.7;
set_height= 0.6;
LJ_processed_data = struct;
if ~exist('num')
    if type ~= 0
        warning('num not define! num set to default value 1.')
    end
    num = 1;
end

%   for MSEC 2023-11-13
%   为MSEC论文专门生成图像，如果需要运行请手动取消下一行的注释，请记得用完了重新注释。
global flag_MSEC
flag_MSEC = 1;
%%   读取数据文件
[fname,pname] = uigetfile('.mat','Choose a Laser_Scan File in .mat format');
if isequal(fname,0)
    %     disp('none');
    error('no file selected')
else
    disp(fullfile(pname,fname));
end
str1 = [pname,'\',fname];
load(str1);
%%  globalICP object 2024-01-24
demo_flag = 0;
close all

% Create globalICP object
folder_type = 2;
switch folder_type
    case 1
        icp = globalICP('OutputFolder', cd, 'TempFolder', 'D:\temp');
    case 2
        load('Config.mat','path');
        icp = globalICP('OutputFolder', [cd,'\temp\tp4op'], 'TempFolder', [cd,'\temp\tp4tp']);
end

% Add point clouds to object from plain text files
% (Added point clouds are saved as mat files, e.g. LionScan1Approx.mat)
if demo_flag==1
    icp.addPC('LionScan1Approx.xyz');
    icp.addPC('LionScan2Approx.xyz');
    icp.addPC('LionScan3Approx.xyz');
    icp.addPC('LionScan4Approx.xyz');
    icp.addPC('LionScan5Approx.xyz');
    icp.addPC('LionScan6Approx.xyz');
else
    pc = lj2pc(Laser_Scan);
    n = length(pc);
    for i = 1:n
        temp_pc = pc(i).ptcCloud.X;
        icp.addPC(temp_pc);
    end
end

% Plot all point clouds BEFORE ICP (each in a different random color)
% figure; icp.plot('Color', 'random');
% figure
icp.plot('Color', 'random');
title('BEFORE ICP'); view(0,0);

% Run ICP!
if demo_flag==1
    icp.runICP('PlaneSearchRadius', 2);
else
    c = 1:-0.1:0.1;
    for i=1:length(c)
        try icp.runICP('PlaneSearchRadius', c(i));
            % close
            % icp.plot('Color', 'random');
            % title('AFTER ICP'); view(0,0);
        catch ME
            icp.runICP('PlaneSearchRadius', c(i-1))
            % close
            % icp.plot('Color', 'random');
            % title('AFTER ICP'); view(0,0);
            msg = ['精度极限为',num2str(c(i-1))];
            disp(msg)
            break
        end
    end
end

% Plot all point clouds AFTER ICP
close
% figure; 
icp.plot('Color', 'random');
title('AFTER ICP'); view(0,0);

%   保存数据
%   (1) 把单独的点云数据保存到Laser_Scan.PC_data(i).ipc中
merged_points = [];
for i = 1:n
    temp_path = cell2mat(icp.PC(i));
    load(temp_path,"obj");
    Laser_Scan.PC_data(i).icp=obj;
    merged_points = [merged_points;Laser_Scan.PC_data(i).icp.X];
end
%   (2) 合并数据并保存
%   把ICP对象保存为Laser_Scan.PC_data_merged.IPC,把点云数据合并并生成新的对象，
%   保存在Laser_Scan.PC_data_merged.Merged_PC中
Laser_Scan.PC_data_merged.IPC=icp;
Laser_Scan.PC_data_merged.Merged_PC = pointCloud(merged_points);
% %   (3) 更新截面数据
% Laser_Scan.LJ_data_adjusted = Laser_Scan.LJ_data;
% for i = 1:length([Laser_Scan.LJ_data_adjusted])
% 
% end

%   清除无用中间变量
clear ME icp obj temp_path temp_pc path merged_points pc
%   绘图看看
figure(4)
scatter(Laser_Scan.PC_data_merged.Merged_PC.X(:,1),Laser_Scan.PC_data_merged.Merged_PC.X(:,2),5,Laser_Scan.PC_data_merged.Merged_PC.X(:,3),'filled')
hold on
plot([Laser_Scan.LJ_data(2:end).Scan_Traj_X]',[Laser_Scan.LJ_data(2:end).Scan_Traj_Y]','r-')
hold off
%%  平面拟合
figure(5)
%%  曲面拟合
figure(5)
fit_type = 2;
fit_mode = 1;
seg = 0.1;          %使用时fit mode = 1;拟合精度mm
num = 1000;         %使用时fit mode = 2;拟合精度网格数量
temp = [Laser_Scan.PC_data_merged.Merged_PC.X];
x_profile = temp(:,1);
y_profile = temp(:,2);
z_profile = temp(:,3);
clear temp
%   剔除无效点
snxyz = ~isnan(x_profile) & ~isnan(y_profile) & ~isnan(z_profile);
switch fit_type
    case 1
        %   方法1：曲面插值
        switch fit_mode
            case 1 % 给定精度
                xlin = linspace(min(x_profile),max(x_profile),round((max(x_profile)-min(x_profile))/seg));
                ylin = linspace(min(y_profile),max(y_profile),round((max(y_profile)-min(y_profile))/seg));
            case 2 % 给定数量
                xlin = linspace(min(x_profile),max(x_profile),round(num));
                ylin = linspace(min(y_profile),max(y_profile),round(num));
        end
        [X,Y] = meshgrid(xlin,ylin);
        Z = griddata(x_profile(snxyz),y_profile(snxyz),z_profile(snxyz),X,Y, 'cubic');
        %     meshc(X,Y,Z);
        surfc(X,Y,Z,'EdgeColor','none');
        axis equal
        colorbar
        xlabel('X [mm]','FontSize',12,'FontName','Times New Roman')
        ylabel('Y [mm]','FontSize',12,'FontName','Times New Roman')
        zlabel('Z [mm]','FontSize',12,'FontName','Times New Roman')
        set(gca,'FontName','Times New Roman')
    case 2
        %   方法2：曲面拟合
        example = 0;
        if example
            %   例子，由ChatGPT生成：
            % 假设你有点云数据点保存在变量 points 中，每个点由三个坐标组成
            % points 应该是一个 N×3 的矩阵，其中 N 是点的数量
            %   我们可以这样设置points:
            points = [x_profile(snxyz), y_profile(snxyz), z_profile(snxyz)];
            % 拟合点云数据
            F = scatteredInterpolant(points(:,1), points(:,2), points(:,3), 'natural', 'none');
            % F = fit([points(:,1), points(:,2)], points(:,3), 'smoothingspline');
            % 定义拟合曲面的网格范围
            [X,Y] = meshgrid(min(points(:,1)):0.1:max(points(:,1)), min(points(:,2)):0.1:max(points(:,2)));
            % 计算拟合曲面的 Z 值
            Z = F(X,Y);
            % 显示拟合结果，设置 EdgeColor 参数为 'none' 隐藏网格边界
            surf(X,Y,Z,'EdgeColor','none');
            xlabel('X');
            ylabel('Y');
            zlabel('Z');
            title('Fitted Surface');
        else
            F = scatteredInterpolant(x_profile(snxyz), y_profile(snxyz), z_profile(snxyz), 'natural', 'none');
            Laser_Scan.Surface = F;
            if 1
                [X,Y] = meshgrid(min(points(:,1)):0.1:max(points(:,1)), min(points(:,2)):0.1:max(points(:,2)));
                Z = F(X,Y);
                surf(X,Y,Z,'EdgeColor','none');
                xlabel('X');
                ylabel('Y');
                zlabel('Z');
                title('Fitted Surface');
            end
        end
    case 3
        %   方法3：平面拟合（用于姿态矫正）
        %   例子，由ChatGPT生成：
        % 假设你有点云数据点保存在变量 points 中，每个点由三个坐标组成
        % points 应该是一个 N×3 的矩阵，其中 N 是点的数量
        points = [x_profile(snxyz), y_profile(snxyz), z_profile(snxyz)];
        % 使用 fit 函数拟合成平面
        fitresult = fit([points(:,1), points(:,2)], points(:,3), 'poly11');
        % fitresult = fit([points(:,1), points(:,2)], points(:,3), 'poly23');
        % 显示拟合结果
        % plot(fitresult);
        % hold on
        % plot3(points(:,1),points(:,2),points(:,3),'b.');
        % hold off
        subplot(2,2,1)
        scatter3(points(:,1),points(:,2),points(:,3)-fitresult(points(:,1),points(:,2)),3,points(:,3)-fitresult(points(:,1),points(:,2)),"filled")
        colorbar
        xlabel('X');
        ylabel('Y');
        zlabel('Z');
        title('Fitted Plane');
        view([0 0 1])

        subplot(2,2,2)
        scatter3(points(:,1),points(:,2),points(:,3)-fitresult(points(:,1),points(:,2)),3,points(:,3)-fitresult(points(:,1),points(:,2)),"filled")
        colorbar
        xlabel('X');
        ylabel('Y');
        zlabel('Z');
        title('Fitted Plane');
        view([1 0 0])

        subplot(2,2,3)
        scatter3(points(:,1),points(:,2),points(:,3)-fitresult(points(:,1),points(:,2)),3,points(:,3)-fitresult(points(:,1),points(:,2)),"filled")
        colorbar
        xlabel('X');
        ylabel('Y');
        zlabel('Z');
        title('Fitted Plane');
        view([0 1 0])

        subplot(2,2,4)
        plot(fitresult);
        hold on
        scatter3(points(:,1),points(:,2),points(:,3),3,points(:,3)-fitresult(points(:,1),points(:,2)),"filled")
        hold off
        colorbar
        xlabel('X');
        ylabel('Y');
        zlabel('Z');
        title('Fitted Plane');
        view([1 1 1])

end
%%  数据处理
%   确定循环参数
switch type
    case 0
        if length(X_profile)>=num
            start_num = num;
            end_num   = num;
        else
            error('Imported data error!')
        end
    case 1
        if length(X_profile)>=1
            start_num = 1;
            end_num   = size(X_profile,1);
        else
            error('Imported data error!')
        end
end

%   松弛系数，防止由于线条顶端出现的下凹导致的数据错误。单位mm
rf = 1e-2;
%

%   开始处理的循环
plotb = 2;
plota = 2;
profile_data = struct;
if test_flag
    figure(1)
end
for i = start_num:end_num %对每个截面进行处理
    profile_data(i).SN=start_num+i-1;
    x_temp = X_profile(i,:);
    y_temp = Y_profile(i,:);
    z_temp = Z_profile(i,:);
    sn_nan = isnan(x_temp) | isnan(y_temp) | isnan(x_temp);
    x_temp(sn_nan)=[];
    y_temp(sn_nan)=[];
    z_temp(sn_nan)=[];
    if test_flag
        subplot(plota,plotb,1)
        plot(y_temp,z_temp,'b.');
    end
    %   第一次线性拟合
    p1 = polyfit(y_temp,z_temp,1);
    f1 = polyval(p1,y_temp);
    e = z_temp - f1;
    sn= find(e<=mean(e)+std(e)&e>=mean(e)-std(e));
    y1 = y_temp(sn);
    z1 = z_temp(sn);
    if test_flag
        subplot(plota,plotb,2)
        plot(y1,e(sn))
    end
    if test_flag
        subplot(plota,plotb,1)
        hold on
        plot(y_temp,f1)
        hold off
    end
    %   第二次线性拟合
    p2 = polyfit(y1,z1,1);
    f2 = polyval(p2,y1);
    e = z1 - f2;
    sn= find(e<=mean(e)+std(e)&e>=mean(e)-std(e));
    y2 = y1(sn);
    z2 = z1(sn);
    if test_flag
        subplot(plota,plotb,2)
        hold on
        plot(y2,e(sn))
        hold off
    end
    if test_flag
        subplot(plota,plotb,1)
        hold on
        plot(y1,f2)
        hold off
    end
    %   第三次线性拟合
    p3 = polyfit(y2,z2,1);
    f3 = polyval(p3,y2);
    e = z2 - f3;
    sn= find(e<=mean(e)+std(e)&e>=mean(e)-std(e));
    y3 = y2(sn);
    z3 = z2(sn);
    if test_flag
        subplot(plota,plotb,2)
        hold on
        plot(y3,e(sn))
        hold off
    end
    if test_flag
        subplot(plota,plotb,1)
        hold on
        plot(y2,f3)
        hold off
    end
    %   保存修正后的曲线
    z_tempf = z_temp-1.0*(polyval(p3,y_temp)-mean(z3));
    profile_data(i).profile.x = x_temp;
    profile_data(i).profile.y = y_temp;
    profile_data(i).profile.z = z_temp;
    profile_data(i).profile.zf= z_tempf;
    profile_data(i).profile.s = S_LJ;
    %   绘制修正后的曲线
    if test_flag
        subplot(plota,plotb,1)
        hold on
        plot(y_temp,z_tempf,'og-')
        title(['截面倾角矫正,k=',num2str(p3(1)),',b=',num2str(p3(2))])
        legend({'截面数据','一次拟合','二次拟合','三次拟合','矫正结果'})
        hold off
        %     axis equal
        subplot(plota,plotb,2)
        hold on
        title('取样部分的拟合偏差')
        legend({'一次拟合','二次拟合','三次拟合'})
        hold off
    end

    %   分区判断
    %   （1）对数据z求导，得到导数z'的标准差std，并且获取>std和<-std范围内的数据序列snn
    %   （2）求snn的符号signsn=[0,sign(snn)]
    %   （3）求解signsn的突变点(z'符号改变的点)，包括上升z'↑和下降z'↓
    %   （4）对于所有的上升↑点，查找在这个点之前，是否存在-std<z'<std，在这个点之后是否存在下降↓点，下降点之后是否存在-std<z'<std，如果都满足，则在该范围内存在一个线条的截面
    %       按照 是否存在线条截面，起始点，终止点的格式来写入strand_info的每一行
    %   （5）取出线条截面局部数据，并获取①线条截面中心点，②线宽，③线高
    %   先完成（1），并绘图
    if test_flag
        subplot(plota,plotb,3)
    end
    dz = diff(z_tempf);
    if test_flag
        plot(y_temp(1:end-1),dz,y_temp(1:end-1),ones(size(y_temp(1:end-1)))*max(std(dz),5e-3),y_temp(1:end-1),-ones(size(y_temp(1:end-1)))*max(std(dz),5e-3))
        title('轮廓高度z变化率dz')
        legend({'dz','std(z)','-std(z)'})
        subplot(plota,plotb,4)
    end
    %   完成（2）
    snp = find(dz>=max(std(dz),rf));
    snm = find(dz<=-max(std(dz),rf));
    snn = find((dz>=max(std(dz),rf)|dz<=-max(std(dz),rf))&(z_tempf(1:end-1)>=mean(z3(1:end-1))+std(z_tempf(1:end-1))));
    signsn=[0,sign(dz(snn))];
    %   完成（3）
    signsd=diff(signsn);
    point_u = find(signsd>0);
    point_d = find(signsd<0);
    %   完成（4）
    %     num_group = length(point_edge);
    %   strands_info结构：
    %   列：对应每一个线条截面
    %   行：
    %       第1行：是否为完整截面
    %       第2行：起始位置
    %       第3行：终止位置
    %       第4行：中心点X坐标
    %       第5行：中心点Y坐标
    %       第6行：中心点Z坐标
    %       第7行：线宽
    %       第8行：线高
    %       第9行：扫描序列
    strands_info = zeros(9,length(point_u));
    for j = 1:length(point_u)
        %   2023-02-17 在循环时，先把扫描序列信息写入
        strands_info(9,j)=S_LJ(i);
        look_start = 1;
        %   ①判断在这个点之前，是否存在-std<z'<std
        look_end = snn(point_u(j));
        j_temp_1 = find(dz(look_start:look_end)<max(std(dz),5e-3)&dz(look_start:look_end)>-max(std(dz),5e-3));
        if isempty(j_temp_1)
            if test_flag
                disp('上升段不完整，舍弃')
            end
            strands_info(1,j)=0;
            continue
        else
            strands_info(2,j)=max(j_temp_1);
        end
        %   ②判断在这个点之后是否存在下降↓点
        j_temp_2 = find(point_d>point_u(j));
        if isempty(j_temp_2)
            if test_flag
                disp('不存在下降段，舍弃')
            end
            strands_info(1,j)=0;
            continue
        else
            if length(j_temp_2)>1
                j_temp_2(2:end)=[];%只留point_u(j)右边最近的
            end
            %   ③判断在这个下降点之后是否存在-std<z'<std
            look_start = snn(point_d(j_temp_2));
            if j+1<=length(point_u)
                look_end   = snn(point_u(j+1));
            else
                look_end   = length(dz);
            end
            %   寻找的点需要满足一下几点：a)dz在限定范围内,b)z_tempf也在范围内
            tempfm = z_tempf(1:end-1);
            j_temp_3 = find(dz(look_start:look_end)<max(std(dz),5e-3)&dz(look_start:look_end)>-max(std(dz),5e-3)&tempfm(look_start:look_end)<mean(z_tempf)+std(z_tempf));
            if isempty(j_temp_3)
                if test_flag
                    disp('下降段不完整，舍弃')
                end
                strands_info(1,j)=0;
                continue
            else
                strands_info(1,j)=1;
                strands_info(3,j)=min(j_temp_3)+look_start;
            end
        end
    end
    %   绘图
    if test_flag
        plot(y_temp(snp),z_tempf(snp),'ro')
        hold on
        plot(y_temp(snm),z_tempf(snm),'r^')
        plot(y_temp(snn(point_d)),z_tempf(snn(point_d)),'bv')
        plot(y_temp(snn(point_u)),z_tempf(snn(point_u)),'bv')
        if 0
            snsn = j;
            hold off
            plot(y_temp((look_start:look_end)),dz(look_start:look_end),'k.')
            hold on
            plot(y_temp(strands_info(2,snsn): strands_info(3,snsn)),dz(strands_info(2,snsn): strands_info(3,snsn)),'r.')
            %         plot(y_temp(j_temp_3+look_start),dz(j_temp_3+look_start),'r^')
            hold off
        end
        if sum(strands_info(1,:))>0
            for j=1:length(strands_info(1,:))
                if strands_info(1,j)==1
                    plot(y_temp(strands_info(2,j):strands_info(3,j)),z_tempf(strands_info(2,j):strands_info(3,j)),'b-')
                end
            end
        end
        hold off
        title(['序号:',num2str(i),',特征点↑：',num2str(point_u),', 特征点↓：',num2str(point_d),', 线条数量为：',num2str(sum(strands_info(1,:)))])
        legend({'dz>std(dz)的点','dz<-std(dz)的点','斜率突变↑点','斜率突变↓点','取样的曲线'})
    end
    %   计算线条截面的参数后需要进行保存
    %   行：
    %       第1行：是否为完整截面
    %       第2行：起始位置
    %       第3行：终止位置
    %       第4行：中心点X坐标
    %       第5行：中心点Y坐标
    %       第6行：中心点Z坐标
    %       第7行：线宽
    %       第8行：线高
    %       第9行：扫描序列
    if sum(strands_info(1,:))>0
        for j=1:length(strands_info(1,:))
            if strands_info(1,j)==1
                strands_info(4,j)=mean(x_temp(strands_info(2,j):strands_info(3,j)));
                strands_info(5,j)=mean(y_temp(strands_info(2,j):strands_info(3,j)));
                strands_info(6,j)=mean(z_temp(strands_info(2,j):strands_info(3,j)));
                strands_info(7,j)=max(y_temp(strands_info(2,j):strands_info(3,j)))-min(y_temp(strands_info(2,j):strands_info(3,j)));
                strands_info(8,j)=max(z_tempf(strands_info(2,j):strands_info(3,j)))-min(z_tempf(strands_info(2,j):strands_info(3,j)));
            end
        end
    end
    profile_data(i).strands_info = strands_info;
    if test_flag
        pause(0.08)
    end
end
if type==0
    return
end
LJ_processed_data.profile_data = profile_data;
clear profile_data
%% 轨迹分组
%   【mean shift聚类算法的MATLAB程序】 https://www.cnblogs.com/kailugaji/archive/2019/10/10/11646167.html
%   看了一下，MATLAB本身的dbscan函数就很好用
ls = 0;
for i = 1:length(LJ_processed_data.profile_data)
    [a,b]=size(LJ_processed_data.profile_data(i).strands_info);
    ls = ls+b;
end
strands_infos = zeros(6,ls);
sl = 1;
for i = 1:length(LJ_processed_data.profile_data)
    [a,b]=size(LJ_processed_data.profile_data(i).strands_info);
    if b>0
        temp = LJ_processed_data.profile_data(i).strands_info;
        for j = 1:b
            strands_infos(1,sl) = temp(4,j);
            strands_infos(2,sl) = temp(5,j);
            strands_infos(3,sl) = temp(6,j);
            strands_infos(4,sl) = temp(7,j);
            strands_infos(5,sl) = temp(8,j);
            strands_infos(6,sl) = temp(9,j);
            sl = sl+1;
        end
    end
end
strands_infos = [1:length(strands_infos);strands_infos];%   第一列为序号，便于在上一步寻找数据。
% strands_infos(:,find(strands_infos(2,:)==0))=[];
%   (1) 得到所有点所属的扫描序列
sn_scan = unique(strands_infos(7,:));
sn_scan(sn_scan==+-1)=[];
strands_infoss = struct;
strands_groups = struct;
%   这两个参数是dbscan聚类算法中的参数，具体看help
epsilon=3;
minpts=50;

for i = 1:length(sn_scan)
    %   (2) 按照扫描序列处理数据点
    %   首先先获取数据点
    strands_infos_temp = strands_infos(:,strands_infos(7,:)==sn_scan(i));
    strands_infoss(i).strands_infos = strands_infos_temp;
    %   接着对数据点进行聚类
    temp_scan = [strands_infos_temp(2,:)',strands_infos_temp(3,:)'];                    % 得到扫描序列下所有点的XY坐标
    labels = dbscan(temp_scan,epsilon,minpts);                                          % 进行聚类计算
    labelsname = unique(labels);                                                        % 计算类别种类，并剔除噪点(-1)
    labelsname(labelsname==-1)=[];
    for j = 1:length(labelsname)
        labelsname(j,2)=sum(labels==labelsname(j));                                     % 计算个类别的点的数量
    end
    reserved_group = labelsname(:,2)==max(labelsname(:,2));                             % 确认最多点的类别
    strands_groups(i).group_num = sn_scan(i);                                           % 保存扫描序号
    strands_groups(i).infos = strands_infos_temp(:,labels==labelsname(reserved_group)); % 保存主要类别的点
    strands_groups(i).infos(7,:)=i;
end
%   最后把得到的数据汇总
grouped_strands = [];
for i = 1:length(strands_groups)
    grouped_strands = [grouped_strands,strands_groups(i).infos];
end
% if test_flag
%     figure(3)
%     gscatter(grouped_strands(2,:),grouped_strands(3,:),grouped_strands(6,:));
% end
LJ_processed_data.grouped_strands = grouped_strands;
clear grouped_strands
%%  绘图
if (test_flag==1)||(plot_flag2==1)
    figure(2)
    subplot(1,2,1)
    %     plot3(strands_infos(2,:),strands_infos(3,:),strands_infos(4,:),'k.')
    gscatter(LJ_processed_data.grouped_strands(2,:),LJ_processed_data.grouped_strands(3,:),LJ_processed_data.grouped_strands(7,:));
    title('Trajectory')
    xlabel('X')
    ylabel('Y')
    %     zlabel('Z')
    axis equal
    subplot(2,2,2)
    %     plot(strands_infos(1,:),strands_infos(5,:),'k--')
    plot(LJ_processed_data.grouped_strands(1,:),LJ_processed_data.grouped_strands(5,:),'k--')
    hold on
    %     plot(strands_infos(1,:),smooth(strands_infos(5,:)),'r-')
    plot(LJ_processed_data.grouped_strands(1,:),smooth(LJ_processed_data.grouped_strands(5,:)),'r-')
    tta1 = 30;
    dta1 = 2;
    %   这里手动矫正了一下，如果有需要的话请自己取消注释并调整数值
    % plot(LJ_processed_data.grouped_strands(1,1:240),smooth(LJ_processed_data.grouped_strands(5,1:240))*cosd(tta1-dta1),'b.')
    % plot(LJ_processed_data.grouped_strands(1,240:740),smooth(LJ_processed_data.grouped_strands(5,240:740))*cosd(tta1+dta1),'b.')
    % plot(LJ_processed_data.grouped_strands(1,740:end),smooth(LJ_processed_data.grouped_strands(5,740:end))*cosd(0),'b.')
    hold off
    title('Strand Width')
    xlabel('序号')
    ylabel('W [mm]')
    legend({'origin','smooth'})
    subplot(2,2,4)
    %     plot(strands_infos(1,:),strands_infos(6,:),'k--')
    plot(LJ_processed_data.grouped_strands(1,:),LJ_processed_data.grouped_strands(6,:),'k--')
    hold on
    %     plot(strands_infos(1,:),smooth(strands_infos(6,:)),'r-')
    plot(LJ_processed_data.grouped_strands(1,:),smooth(LJ_processed_data.grouped_strands(6,:)),'r-')
    hold off
    title('Strand Height')
    xlabel('序号')
    ylabel('H [mm]')
    legend({'origin','smooth'})
    %   for MSEC 2023-11-13
    %   为MSEC论文专门生成图像，如果需要运行请手动取消下一行的注释，请记得用完了重新注释。
    %     flag_MSEC = 1;
    if flag_MSEC ~= 0
        switch flag_MSEC
            case 1
                %   手动选择数据范围：
                sn0 = 001;
                sn1 = 450;
                sn2 = sn1;
                sn3 = sn1;
                %         sn2 = 520;
                %         sn3 = 980;
                srt1 = 0.010;
                srt2 = 0.200;
            case 2
        end
        figure(2)
        subplot(3,1,1)
        gscatter(LJ_processed_data.grouped_strands(2,[sn0:sn1,sn2:sn3]),LJ_processed_data.grouped_strands(3,[sn0:sn1,sn2:sn3]),LJ_processed_data.grouped_strands(7,[sn0:sn1,sn2:sn3]));
        title('Actual trajectory','FontSize',12,'FontName','Times New Roman')
        xlabel('X [mm]','FontSize',12,'FontName','Times New Roman')
        ylabel('Y [mm]','FontSize',12,'FontName','Times New Roman')
        grid on
        subplot(3,1,2)
        plot(LJ_processed_data.grouped_strands(1,[sn0:sn1,sn2:sn3]),smooth(LJ_processed_data.grouped_strands(5,[sn0:sn1,sn2:sn3]),srt1),'k.')
        title('Strand Width','FontSize',12,'FontName','Times New Roman')
        xlabel('Serial Number','FontSize',12,'FontName','Times New Roman')
        ylabel('W [mm]','FontSize',12,'FontName','Times New Roman')
        grid on
        %         legend(''},'FontSize',12,'FontName','Times New Roman')
        subplot(3,1,3)
        plot(LJ_processed_data.grouped_strands(1,[sn0:sn1,sn2:sn3]),smooth(LJ_processed_data.grouped_strands(6,[sn0:sn1,sn2:sn3]),srt2),'k.')
        title('Strand Height','FontSize',12,'FontName','Times New Roman')
        xlabel('Serial Number','FontSize',12,'FontName','Times New Roman')
        ylabel('H [mm]','FontSize',12,'FontName','Times New Roman')
        grid on
        %         legend({'origin','smooth'})
        % 2023-11-14 这么画图好看一点
        subplot(2,1,1)
        gscatter(LJ_processed_data.grouped_strands(2,[sn0:sn1,sn2:sn3]),LJ_processed_data.grouped_strands(3,[sn0:sn1,sn2:sn3]),LJ_processed_data.grouped_strands(7,[sn0:sn1,sn2:sn3]));
        title('Actual trajectory','FontSize',12,'FontName','Times New Roman')
        xlabel('X [mm]','FontSize',12,'FontName','Times New Roman')
        ylabel('Y [mm]','FontSize',12,'FontName','Times New Roman')
        grid on
        set(gca,'FontName','Times New Roman')

        subplot(2,1,2)
        title('Strand Features','FontSize',12)
        xlabel('X [mm]','FontSize',12)
        yyaxis left; % 激活左y轴
        plot(LJ_processed_data.grouped_strands(1,[sn0:sn1,sn2:sn3]),smooth(LJ_processed_data.grouped_strands(5,[sn0:sn1,sn2:sn3]),srt1),'k-')
        ylabel('W [mm]','FontSize',12)
        yyaxis right; % 激活右y轴
        plot(LJ_processed_data.grouped_strands(1,[sn0:sn1,sn2:sn3]),smooth(LJ_processed_data.grouped_strands(6,[sn0:sn1,sn2:sn3]),srt2),'b--')
        ylabel('H [mm]','FontSize',12)

        legend({'Strand Width','Strand Height'},'FontSize',12)
        grid on
        set(gca,'FontName','Times New Roman')
    end
end
% return
%%  轨迹对比
if (test_flag==1)||(plot_flag2==1)
    offset_invalid_flag = 1;    %这个标志位用于判断手调循环的退出
    mode_selected = 1;          %这个标志位用于判断模式选择的退出
    finish_flag = 0;
    %   首先选择模式，读取or手调，如果手调，则读取Gcode代码，然后直接交互式调节，并保存文档；若读取，则直接读取手调保存的文件
    while mode_selected == 1
        prompt0 = {'Please select a mode:';'    1 Read from file';'    2 Manual adjust ';   '    Q/q quit'};
        for i=1:size(prompt0,1)
            disp(cell2mat(prompt0(i)))
        end
        str0 = input(cell2mat(prompt0(1)),'s');
        %   判断输入是否有效
        if contains(str0,'Q') || contains(str0,'q') %退出
            offset_invalid_flag = 0;
            offset_mode = 0;
            finish_flag = 0;
            mode_selected = 0;
            warning(strcat("Abandon mode selection and exit！"));
            %   这里提供两种模式：1、手动微调；2、读取已经调整好的数据
        elseif contains(str0,'1')%读取已经保存的文档
            [fnamer,pnamer] = uigetfile('.mat','Select Gcode4Scan_adjust.mat File');
            if isempty(fnamer)||isempty(pnamer)
                error('You did not select a file!')
            elseif length(fnamer)==1&&fnamer==0 || length(pnamer)==1&&pnamer==0
                error('You did not select a file!')
            end
            strr = [pnamer fnamer];
            if isempty(strr)
                error('You did not select a file!')
            end
            load(strr)
            %   绘图
            figure(2)
            subplot(1,2,1)
            gscatter(LJ_processed_data.grouped_strands(2,:),LJ_processed_data.grouped_strands(3,:),LJ_processed_data.grouped_strands(7,:));
            hold on
            plot(PC(:,1),PC(:,2),'b--')
            plot(PT(:,1),PT(:,2),'b-')
            hold off
            title('Trajectory')
            xlabel('X')
            ylabel('Y')
            axis equal
            %   完成选择后准备退出循环
            mode_selected = 0;
        elseif contains(str0,'2')%手动调整并保存文件
            %   首先读取先前生成的Gcode4Print.mat文件
            %     [fname,pname] = uigetfile('.mat','Select Gcode4Scan File');
            %     if isempty(fname)||isempty(pname)||fname==0||pname==0
            %         error('You did not select a file!')
            %     end
            %     str3 = [pname fname];
            %     load(str3);
            [fname,pname] = uigetfile('.mat','Select Gcode4Scan File');
            if isempty(fname)||isempty(pname)
                error('You did not select a file!')
            elseif length(fname)==1&&fname==0 || length(pname)==1&&pname==0
                error('You did not select a file!')
            end
            str = [pname fname];
            if isempty(str)
                error('You did not select a file!')
            end
            [TJ_X,TJ_Y,TJ_Z,TJ_F,TJ_S] = LJ_Interpolation4Traj_V2_0(c,str);
            Trajectory_X = TJ_X(2:end);
            Trajectory_Y = TJ_Y(2:end);
            Trajectory_Z = TJ_Z(2:end);
            Coordinate_system_1 = [50,50,0,0,0,0];    %格式：该坐标系在世界坐标系下的XYZ坐标、ABC旋转角度。
            Coordinate_system_2 = [13,130,0,0,0,-90];
            %   接着先把预先矫正的图像绘制上去再进行手动微调
            Tt = eye(4);
            Tti=Tt;
            t1 = [[rotz(0),-Coordinate_system_1(1:3)'];0,0,0,1];
            t2 = [[rotz(Coordinate_system_2(6)),[0;0;0]];0,0,0,1];
            t3 = [[rotz(0),Coordinate_system_2(1:3)'];0,0,0,1];
            P1 = [Trajectory_X,Trajectory_Y,Trajectory_Z,ones(size(Trajectory_Z))];
            Tt = t3*t2*t1;
            Tti= inv(t1)*inv(t2)*inv(t3);
            P2 = (Tt*P1')';
            figure(2)
            subplot(1,2,1)
            hold on
            plot(P2(:,1),P2(:,2),'b')
            hold off
            %   交互式微调程序
            PC = P2;
            disp('Offset Mode List:')
            spn_list = {1,'Translation';2,'Rotation'};
            while offset_invalid_flag == 1
                for i=1:size(spn_list,1)
                    disp([num2str(cell2mat(spn_list(i,1))),'  ',cell2mat(spn_list(i,2))])
                end
                prompt1 = 'Please Select a offset mode(Type Q/q if you want to quit, Y/y if tuning is finish): ';
                str1 = input(prompt1,'s');
                %   判断输入是否有效
                if contains(str1,'Q') || contains(str1,'q') %退出
                    offset_invalid_flag = 0;
                    offset_mode = 0;
                    finish_flag = 0;
                    warning(strcat("放弃调整！"));
                elseif contains(str1,'Y') || contains(str1,'y') %完成调整
                    offset_invalid_flag = 0;
                    offset_mode = 0;
                    finish_flag = 1;
                    disp(strcat("完成调整！"));
                    %   完成调整后记得保存文件
                    strs = [str(1:end-4),'_adjust',str(end-3:end)];
                    save(strs,'offset_invalid_flag','mode_selected','finish_flag','fname','pname','prompt0','prompt1','prompt2',...
                        'str','str0','str1','str2','strs','TJ_X','TJ_Y','TJ_Z','TJ_F','TJ_S','Trajectory_X','Trajectory_Y','Trajectory_Z',...
                        'Coordinate_system_1','Coordinate_system_2','Tt','Tti','t1','t2','t3','t4','t5','t6','t7','P1','P2','PC','PT',...
                        'spn_list','spn','temp_s2','offset_x','offset_y','offset_z','offset_rx','offset_ry','offset_rr')
                else %选择了一个模式
                    % 判断一下输入的数值是否在序号范围内
                    spn = str2double(str1);
                    if isempty(find(cell2mat(spn_list(:,1))==spn)) %不在范围内，警告，并重新输入。
                        offset_invalid_flag = 1;
                        offset_mode = 0;
                        warning(strcat("The offset mode number is incorrect. Please try again!"));
                        continue
                    else % 在范围内
                        % 输入需要调整的数值
                        offset_mode = spn;
                        prompt2 = 'Please Input a Select Translation in format x,y (Type Q/q if you want to quit): ';
                        str2 = input(prompt2,'s');
                        if contains(str2,'Q') || contains(str2,'q') %退出
                            offset_invalid_flag = 0;
                            offset_mode = 0;
                            warning(strcat("放弃调整！"));
                            continue
                        else
                            temp_s2 = str2num(str2);
                            if ~isempty(temp_s2)
                                switch offset_mode
                                    case 1 %平移调整
                                        if ~length(temp_s2)==2
                                            warning(strcat("Input error, Please retry！"));
                                            continue
                                        else
                                            offset_x = temp_s2(1);
                                            offset_y = temp_s2(2);
                                            offset_z = 0;
                                        end
                                        t4 = [[rotz(0),[offset_x;offset_y;offset_z]];0,0,0,1];
                                        Tt = t4*Tt;
                                        Tti= Tti+inv(t4);
                                        PT = (t4*PC')';
                                    case 2 %旋转调整
                                        if ~length(temp_s2)==3
                                            warning(strcat("Input error, Please retry！"));
                                            continue
                                        else
                                            offset_rx = temp_s2(1);
                                            offset_ry = temp_s2(2);
                                            offset_rr = temp_s2(3);
                                            if offset_rx==0 && offset_ry==0
                                                offset_rx = 0.5*(max(PC(:,1))+min(PC(:,1)));
                                                offset_ry = 0.5*(max(PC(:,2))+min(PC(:,2)));
                                            end
                                            t5 = [[rotz(0),-[offset_rx;offset_ry;0]];0,0,0,1];
                                            t6 = [[rotz(offset_rr),[0;0;0]];0,0,0,1];
                                            t7 = [[rotz(0),[offset_rx;offset_ry;0]];0,0,0,1];
                                            Tt = t7*t6*t5*Tt;
                                            Tti= Tti*inv(t5)*inv(t6)*inv(t7);
                                            PT = (t7*t6*t5*PC')';
                                        end
                                    otherwise
                                        warning(strcat("Input error, Please retry！"));
                                        continue
                                end
                                figure(2)
                                subplot(1,2,1)
                                gscatter(LJ_processed_data.grouped_strands(2,:),LJ_processed_data.grouped_strands(3,:),LJ_processed_data.grouped_strands(7,:));
                                hold on
                                plot(PC(:,1),PC(:,2),'b--')
                                plot(PT(:,1),PT(:,2),'b-')
                                hold off
                                title('Trajectory')
                                xlabel('X')
                                ylabel('Y')
                                axis equal
                                PC = PT;
                            end
                        end
                    end
                end
            end
            %   完成选择后准备退出循环
            mode_selected = 0;
        else %其他情况，这个时候要舍弃
            mode_selected = 1;
            warning(strcat("The offset mode number is incorrect. Please try again!"));
            continue
        end
    end
end
if finish_flag~=1
    return
end
%%  计算偏差
%   根据上一步，已经得到了理想轨迹PC，第一列X，第二列Y、第三列Z、第四列1
%   理想轨迹点变量为:PC，
%       第1列：轨迹点X坐标
%       第2列：轨迹点Y坐标
%       第3列：轨迹点Z坐标
%   同时可以参考TJ_S(2:end)，列向量，作为分组依据
%   实际轨迹点变量为:LJ_processed_data.grouped_strands
%       第1行：序号
%       第2行：中心点X坐标
%       第3行：中心点Y坐标
%       第4行：中心点Z坐标
%       第5行：线宽
%       第6行：线高
%       第7行：分组
if (test_flag==1)||(plot_flag2==1)
    Pthe = [PC,TJ_S(2:end),NaN(size(PC,1),8),TJ_F(2:end)];
    Pexp = LJ_processed_data.grouped_strands;
    rmin = 0;
    rmax = 100;
    rstep= 1e-2;
    for i =1:size(Pexp,2)
        tempe = Pexp(:,i)';
        distv = tempe(2:4)-PC(:,1:3);
        dists = sqrt(distv(:,1).^2+distv(:,2).^2+distv(:,3).^2);
        %   计算并保存距离数据点最近的理论点的位置
        mindn = find(dists==min(dists));
        if length(mindn)>1
            mindn = mindn(1);
        end
        tempe(8) = mindn;
        %   保存距离数值
        mindis= dists(tempe(8));
        tempe(9) = mindis;
        %   如果误差太大，则需要舍弃，否则会错误
        if tempe(9)>rmax
            continue
        end
        %   接下来要做一些组别判断，如果不是同一组的，则需要舍弃
        %         if tempe(7)~=Pthe(tempe(8),5)
        %             continue
        %         end
        Pexp(8,i)=tempe(8);
        Pexp(9,i)=tempe(9);
        %   如果是NaN可以写入，如果已经写入，但是写入的误差比现在计算的小，也可以写入，反之则不写入，进入下一轮循环
        EV = Pthe(tempe(8),6);
        if ~isnan(EV)
            if EV>=tempe(9)
                continue
            end
        end
        Pthe(tempe(8),6)=tempe(9);
        Pthe(tempe(8),7:9)=distv(tempe(8),:);
        Pthe(tempe(8),10)=tempe(5);
        Pthe(tempe(8),11)=tempe(5)-set_width;
        Pthe(tempe(8),12)=tempe(6);
        Pthe(tempe(8),13)=tempe(6)-set_height;
    end
    LJ_processed_data.Pthe = Pthe;
    clear Pthe
end
%   说明 Pthe
%   列序号 1   2   3   4   5      6        7   8   9   10    11        12     13       14
%   列项目 X   Y   Z   1   组别   轨迹误差  vx  vy  vz  线宽  线宽误差   线高   线高误差  进给速率

%%  绘图2
if (test_flag==1)||(plot_flag2==1)
    figure(3)
    subplot(2,2,1)
    %     plot3(strands_infos(2,:),strands_infos(3,:),strands_infos(4,:),'k.')
    xulie = ~isnan(LJ_processed_data.Pthe(:,6));
    scatter3(LJ_processed_data.Pthe(xulie,1),LJ_processed_data.Pthe(xulie,2),LJ_processed_data.Pthe(xulie,3),10,LJ_processed_data.Pthe(xulie,6),'fill');
    hold on
    quiver3(LJ_processed_data.Pthe(xulie,1),LJ_processed_data.Pthe(xulie,2),LJ_processed_data.Pthe(xulie,3),LJ_processed_data.Pthe(xulie,7),LJ_processed_data.Pthe(xulie,8),LJ_processed_data.Pthe(xulie,9))
    hold off
    title('Trajectory Error 3D')
    xlabel('X [mm]')
    ylabel('Y [mm]')
    zlabel('Z [mm]')
    legend({'Error Value','Error Vector'})
    colorbar
    axis equal
    set(gca,'FontName','Times New Roman')

    subplot(2,2,2)
    xulie = ~isnan(LJ_processed_data.Pthe(:,6));
    scatter(LJ_processed_data.Pthe(xulie,1),LJ_processed_data.Pthe(xulie,2),10,LJ_processed_data.Pthe(xulie,6),'fill');
    hold on
    quiver(LJ_processed_data.Pthe(xulie,1),LJ_processed_data.Pthe(xulie,2),LJ_processed_data.Pthe(xulie,7),LJ_processed_data.Pthe(xulie,8))
    hold off
    title('Trajectory Error')
    xlabel('X [mm]')
    ylabel('Y [mm]')
    zlabel('Z [mm]')
    legend({'Error Value','Error Vector'})
    colorbar
    axis equal
    set(gca,'FontName','Times New Roman')

    subplot(2,2,3)
    scatter3(LJ_processed_data.Pthe(xulie,1),LJ_processed_data.Pthe(xulie,2),LJ_processed_data.Pthe(xulie,3),10,LJ_processed_data.Pthe(xulie,11),'fill');
    title('Strand Width Error')
    xlabel('X [mm]')
    ylabel('Y [mm]')
    zlabel('Z [mm]')
    view([0 0 1])
    legend({'Strand Width Value'})
    colorbar
    axis equal
    set(gca,'FontName','Times New Roman')


    subplot(2,2,4)
    scatter3(LJ_processed_data.Pthe(xulie,1),LJ_processed_data.Pthe(xulie,2),LJ_processed_data.Pthe(xulie,3),10,LJ_processed_data.Pthe(xulie,13),'fill');
    title('Strand Height Error')
    xlabel('X [mm]')
    ylabel('Y [mm]')
    zlabel('Z [mm]')
    view([0 0 1])
    legend({'Strand Height Value'})
    colorbar
    axis equal
    set(gca,'FontName','Times New Roman')
    %   for MSEC 2023-11-13
    %   为MSEC论文专门生成图像，如果需要运行请手动取消下一行的注释，请记得用完了重新注释。
    %     flag_MSEC = 1;
    %   这里不用坐调整，重点是后面拟合后的数据，那才是重点
    if (0)%flag_MSEC ~=0
        switch flag_MSEC
            case 1
                sn5 = 1;
                sn6 = 630;
                sn7 = sn6;
                sn8 = sn6;
                figure(3)
                subplot(2,2,1)
                %     plot3(strands_infos(2,:),strands_infos(3,:),strands_infos(4,:),'k.')
                xulie0 = ~isnan(LJ_processed_data.Pthe(:,6));
                xulie1 = zeros(size(xulie));
                xulie1([sn5:sn6,sn7:sn8])=1;
                xulie = logical(xulie0 .* xulie1);
                %                 xulie = ~isnan(LJ_processed_data.Pthe([sn0:sn1,sn2:sn3],6));
                scatter3(LJ_processed_data.Pthe(xulie,1),LJ_processed_data.Pthe(xulie,2),LJ_processed_data.Pthe(xulie,3),10,LJ_processed_data.Pthe(xulie,6),'fill');
                hold on
                quiver3(LJ_processed_data.Pthe(xulie,1),LJ_processed_data.Pthe(xulie,2),LJ_processed_data.Pthe(xulie,3),LJ_processed_data.Pthe(xulie,7),LJ_processed_data.Pthe(xulie,8),LJ_processed_data.Pthe(xulie,9))
                hold off
                title('Trajectory Error 3D')
                xlabel('X [mm]')
                ylabel('Y [mm]')
                zlabel('Z [mm]')
                legend({'Error Value','Error Vector'})
                colorbar
                axis equal
                set(gca,'FontName','Times New Roman')

                subplot(2,2,2)
                xulie = ~isnan(LJ_processed_data.Pthe(:,6));
                xulie0 = ~isnan(LJ_processed_data.Pthe(:,6));
                xulie1 = zeros(size(xulie));
                xulie1([sn5:sn6,sn7:sn8])=1;
                xulie = logical(xulie0 .* xulie1);
                scatter(LJ_processed_data.Pthe(xulie,1),LJ_processed_data.Pthe(xulie,2),10,LJ_processed_data.Pthe(xulie,6),'fill');
                hold on
                quiver(LJ_processed_data.Pthe(xulie,1),LJ_processed_data.Pthe(xulie,2),LJ_processed_data.Pthe(xulie,7),LJ_processed_data.Pthe(xulie,8))
                hold off
                title('Trajectory Error')
                xlabel('X [mm]')
                ylabel('Y [mm]')
                zlabel('Z [mm]')
                legend({'Error Value','Error Vector'})
                colorbar
                axis equal
                set(gca,'FontName','Times New Roman')

                subplot(2,2,3)
                scatter3(LJ_processed_data.Pthe(xulie,1),LJ_processed_data.Pthe(xulie,2),LJ_processed_data.Pthe(xulie,3),10,LJ_processed_data.Pthe(xulie,11),'fill');
                title('Strand Width Error')
                xlabel('X [mm]')
                ylabel('Y [mm]')
                zlabel('Z [mm]')
                view([0 0 1])
                legend({'Strand Width Value'})
                colorbar
                axis equal
                set(gca,'FontName','Times New Roman')


                subplot(2,2,4)
                scatter3(LJ_processed_data.Pthe(xulie,1),LJ_processed_data.Pthe(xulie,2),LJ_processed_data.Pthe(xulie,3),10,LJ_processed_data.Pthe(xulie,13),'fill');
                title('Strand Height Error')
                xlabel('X [mm]')
                ylabel('Y [mm]')
                zlabel('Z [mm]')
                view([0 0 1])
                legend({'Strand Height Value'})
                colorbar
                axis equal
                set(gca,'FontName','Times New Roman')
            case 2
        end
    end
end
%%  把没有误差值的点插补出来数值，否则很多点没有数据，就没法生成修正代码
%   说明 LJ_processed_data.Pthe
%       列序号 1   2   3   4   5      6        7   8   9   10    11        12     13       14
%       列项目 X   Y   Z   1   组别   轨迹误差  vx  vy  vz  线宽  线宽误差   线高   线高误差  进给速率
%   error_data数据格式：
%       列序号 1   2   3   4   5      6        7   8   9   10    11        12     13        14
%       列项目 X   Y   Z   1   组别   轨迹误差  vx  vy  vz  线宽  线宽误差   线高   线高误差   F
%   2023-03-15 增加了下面的项目
%       列序号 15      16      17      18      19      20
%       列项目 fitedT  fitedvx fitedvy fitedvz fitedW  fiteddW
if (test_flag==1)||(plot_flag2==1)
    error_data = nan(size(LJ_processed_data.Pthe,1),20);
    error_data(:,1:size(LJ_processed_data.Pthe,2)) = LJ_processed_data.Pthe;
    group_list = unique(error_data(:,5));%  列出数据中的组别，然后按照组别进行优化
    group_list(group_list==-1)=[];%剔除不需要的点-1
    for i=group_list'
        %   对每一组数据做处理
        gi = error_data(:,5)==i;
        tempg = error_data(gi,:);
        %   把每组前面和后面为NaN的轨迹误差数值向量、线宽、线高设置为0，以便于后续计算
        inanlist = find(~isnan(tempg(:,6)));
        if length(inanlist)>0
            if inanlist(1)>1
                tempg(1:inanlist(1)-1,6)=0;
                tempg(1:inanlist(1)-1,7:9)=0;
                tempg(1:inanlist(1)-1,10)=0;
                tempg(1:inanlist(1)-1,12)=0;
            end
            if inanlist(end)<size(tempg,1)
                tempg(inanlist(end)+1:end,6)=0;
                tempg(inanlist(end)+1:end,7:9)=0;
                tempg(inanlist(end)+1:end,10)=0;
                tempg(inanlist(end)+1:end,12)=0;
            end
        end
        %   2023-03-15 新增数据插补方式
        fit_method = 2;
        switch fit_method
            case 1
                %   然后再分组计算相应数值
                x_a = tempg(:,1)+tempg(:,7);
                y_a = tempg(:,2)+tempg(:,8);
                z_a = tempg(:,3)+tempg(:,9);
                tempg(:,7)=smooth(x_a-tempg(:,1));
                tempg(:,8)=smooth(y_a-tempg(:,2));
                tempg(:,9)=smooth(z_a-tempg(:,3));
                tempg(:,6)=sqrt(tempg(:,7).^2+tempg(:,8).^2+0*tempg(:,9).^2);
                tempg(:,10)=smooth(tempg(:,10));
                tempg(:,11)=tempg(:,10)-set_width;
                tempg(:,12)=smooth(tempg(:,12));
                tempg(:,13)=tempg(:,12)-set_height;
                %tempg(:,13)不变
            case 2
                %   2023-03-15 新增了数据插补的方式
                %   (1) 使用每一组内的非NaN数据，采用平滑样条曲线'smoothingspline'拟合出曲线方程temp_f；
                %       获取理想轨迹、计算实际轨迹
                x_t = tempg(:,1);
                y_t = tempg(:,2);
                z_t = tempg(:,3);
                x_a = tempg(:,1)+tempg(:,7);
                y_a = tempg(:,2)+tempg(:,8);
                z_a = tempg(:,3)+tempg(:,9);
                s_n = [1:length(x_t)]';
                %       计算拟合方程
                %                 temp_f = fit(x_a(inanlist),y_a(inanlist),'smoothingspline');
                temp_fx = fit(s_n(inanlist),x_a(inanlist),'smoothingspline');
                temp_fy = fit(s_n(inanlist),y_a(inanlist),'smoothingspline');
                %   (2) 使用理想X坐标(inanlist(1)~inanlist(end)，避免数据集外部数据的干扰)，通过拟合的方程temp_f获得Y坐标，Y=temp_f(X)
                %       拟合数据
                s_l = s_n(inanlist(1):inanlist(end));
                x_l = temp_fx(s_l);
                y_l = temp_fy(s_l);
                %       替换x_a, y_a中的内容
                x_a(inanlist(1):inanlist(end)) = x_l;
                y_a(inanlist(1):inanlist(end)) = y_l;
                %   (3) 然后获取误差并写入
                %       计算轨迹点切向向量
                vx_a = (x_a(3:end)-x_a(1:end-2));
                vy_a = (y_a(3:end)-y_a(1:end-2));
                vz_a = (z_a(3:end)-z_a(1:end-2));
                %       扩充至与点的数量一致
                vx_a = [vx_a(1);vx_a;vx_a(end)];
                vy_a = [vy_a(1);vy_a;vy_a(end)];
                vz_a = [vz_a(1);vz_a;vz_a(end)];
                %      保存轨迹偏差误差和偏差大小
                tempg(:,7)=x_a-x_t;
                tempg(:,8)=y_a-y_t;
                tempg(:,9)=smooth(z_a-z_t);
                for j=1:size(tempg,1)
                    tempg(j,6)=norm(tempg(j,7:8));
                    %       计算修正的线宽
                    %       cos(theta) = vx/norm([vx,vy]);
                    %       W修正 = W获取 * cos(theta)
                    tempg(j,19)=tempg(j,10)*abs(vx_a(j))/ norm(vx_a(j),vy_a(j));
                end
                tempg(:,10)=smooth(tempg(:,10));
                tempg(:,11)=tempg(:,10)-set_width;
                tempg(:,20)=tempg(:,19)-set_width;
                tempg(:,12)=smooth(tempg(:,12));
                tempg(:,13)=tempg(:,12)-set_height;
        end
        error_data(gi,:) = tempg;
    end
    %   最后把组别为-1的删除
    error_data(error_data(:,5)==-1,:)=[];
    LJ_processed_data.error_data = error_data;
    clear error_data
end
%%  绘图3
if (test_flag==1)||(plot_flag2==1)
    xulie2 = ~isnan(LJ_processed_data.error_data(:,6));
    figure(4)
    subplot(2,2,1)
    %     plot3(strands_infos(2,:),strands_infos(3,:),strands_infos(4,:),'k.')
    scatter3(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,3),10,LJ_processed_data.error_data(xulie2,6),'fill');
    hold on
    quiver3(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,3),LJ_processed_data.error_data(xulie2,7),LJ_processed_data.error_data(xulie2,8),LJ_processed_data.error_data(xulie2,9)-mean(LJ_processed_data.error_data(xulie2,9)))
    hold off
    title('Trajectory Error 3D')
    xlabel('X [mm]')
    ylabel('Y [mm]')
    zlabel('Z [mm]')
    legend({'Error Value','Error Vector'})
    colorbar
    axis equal

    subplot(2,2,2)
    xulie2 = ~isnan(LJ_processed_data.error_data(:,6));
    scatter(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),20,LJ_processed_data.error_data(xulie2,6),'fill');
    hold on
    quiver(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,7),LJ_processed_data.error_data(xulie2,8))
    hold off
    title('Trajectory Error')
    xlabel('X [mm]')
    ylabel('Y [mm]')
    zlabel('Z [mm]')
    legend({'Error Value','Error Vector'})
    colorbar
    axis equal

    subplot(2,2,3)
    scatter3(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,3),10,LJ_processed_data.error_data(xulie2,11),'fill');
    title('Strand Width Error')
    xlabel('X [mm]')
    ylabel('Y [mm]')
    zlabel('Z [mm]')
    view([0 0 1])
    legend({'Strand Width Value'})
    colorbar
    axis equal


    subplot(2,2,4)
    scatter3(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,3),10,LJ_processed_data.error_data(xulie2,13),'fill');
    title('Strand Height Error')
    xlabel('X [mm]')
    ylabel('Y [mm]')
    zlabel('Z [mm]')
    view([0 0 1])
    legend({'Strand Height Value'})
    colorbar
    axis equal

end
if (test_flag==1)||(plot_flag2==1)
    figure(5)
    subplot(1,2,1)
    %     plot3(strands_infos(2,:),strands_infos(3,:),strands_infos(4,:),'k.')
    gscatter(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,5));
    title('Trajectory')
    xlabel('X')
    ylabel('Y')
    %     zlabel('Z')
    axis equal
    subplot(2,2,2)
    %     plot(strands_infos(1,:),strands_infos(5,:),'k--')
    plot(LJ_processed_data.error_data(xulie2,19),'k--')
    hold on
    %     plot(strands_infos(1,:),smooth(strands_infos(5,:)),'r-')
    plot(smooth(LJ_processed_data.error_data(xulie2,19)),'r-')
    hold off
    title('Strand Width')
    xlabel('序号')
    ylabel('W [mm]')
    legend({'origin','smooth'})
    subplot(2,2,4)
    %     plot(strands_infos(1,:),strands_infos(6,:),'k--')
    plot(LJ_processed_data.error_data(xulie2,12),'k--')
    hold on
    %     plot(strands_infos(1,:),smooth(strands_infos(6,:)),'r-')
    plot(smooth(LJ_processed_data.error_data(xulie2,12)),'r-')
    hold off
    title('Strand Height')
    xlabel('序号')
    ylabel('H [mm]')
    legend({'origin','smooth'})
end
%   for MSEC 2023-11-13
%   为MSEC论文专门生成图像，如果需要运行请手动取消下一行的注释，请记得用完了重新注释。
%     flag_MSEC = 1;
if flag_MSEC ~=0
    switch flag_MSEC
        case 1
            sn5 = 1;
            sn6 = 602;
            sn7 = sn6;
            sn8 = sn6;
            %             xulie2 = ~isnan(LJ_processed_data.error_data(:,6));
            xulie0 = ~isnan(LJ_processed_data.error_data(:,6));
            xulie1 = zeros(size(xulie0));
            xulie1([sn5:sn6,sn7:sn8])=1;
            xulie2 = logical(xulie0 .* xulie1);
            figure(4)
            subplot(2,2,1)
            %     plot3(strands_infos(2,:),strands_infos(3,:),strands_infos(4,:),'k.')
            scatter3(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,3),10,LJ_processed_data.error_data(xulie2,6),'fill');
            hold on
            quiver3(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,3),LJ_processed_data.error_data(xulie2,7),LJ_processed_data.error_data(xulie2,8),LJ_processed_data.error_data(xulie2,9)-mean(LJ_processed_data.error_data(xulie2,9)))
            hold off
            title('Trajectory Error 3D')
            xlabel('X [mm]','FontSize',12)
            ylabel('Y [mm]','FontSize',12)
            zlabel('Z [mm]','FontSize',12)
            legend({'Error Value','Error Vector'},'FontSize',12)
            colorbar
            axis equal
            grid on
            set(gca,'FontName','Times New Roman')

            subplot(2,2,2)
            %             xulie2 = ~isnan(LJ_processed_data.error_data(:,6));
            xulie0 = ~isnan(LJ_processed_data.error_data(:,6));
            xulie1 = zeros(size(xulie0));
            xulie1([sn5:sn6,sn7:sn8])=1;
            xulie2 = logical(xulie0 .* xulie1);
            scatter(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),20,LJ_processed_data.error_data(xulie2,6),'fill');
            hold on
            quiver(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,7),LJ_processed_data.error_data(xulie2,8))
            hold off
            title('Trajectory Error','FontSize',12)
            xlabel('X [mm]','FontSize',12)
            ylabel('Y [mm]','FontSize',12)
            zlabel('Z [mm]','FontSize',12)
            legend({'Error Value','Error Vector'},'FontSize',12)
            colorbar
            axis equal
            grid on
            set(gca,'FontName','Times New Roman')

            subplot(2,2,3)
            scatter3(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,3),10,LJ_processed_data.error_data(xulie2,11),'fill');
            title('Strand Width Error','FontSize',12)
            xlabel('X [mm]','FontSize',12)
            ylabel('Y [mm]','FontSize',12)
            zlabel('Z [mm]','FontSize',12)
            view([0 0 1])
            legend({'Strand Width Value'},'FontSize',12)
            colorbar
            axis equal
            grid on
            set(gca,'FontName','Times New Roman')


            subplot(2,2,4)
            scatter3(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,3),10,LJ_processed_data.error_data(xulie2,13),'fill');
            title('Strand Height Error','FontSize',12)
            xlabel('X [mm]','FontSize',12)
            ylabel('Y [mm]','FontSize',12)
            zlabel('Z [mm]','FontSize',12)
            view([0 0 1])
            legend({'Strand Height Value'},'FontSize',12)
            colorbar
            axis equal
            grid on
            set(gca,'FontName','Times New Roman')

            figure(5)
            subplot(3,1,1)
            %     plot3(strands_infos(2,:),strands_infos(3,:),strands_infos(4,:),'k.')
            gscatter(LJ_processed_data.error_data(xulie2,1)-min(LJ_processed_data.error_data(xulie2,1)),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,5));
            title('Trajectory','FontSize',12)
            xlabel('X [mm]','FontSize',12)
            ylabel('Y [mm]','FontSize',12)
            %     zlabel('Z')
            %             axis equal
            grid on
            set(gca,'FontName','Times New Roman')

            subplot(3,1,2)
            %     plot(strands_infos(1,:),strands_infos(5,:),'k--')
            %             plot(LJ_processed_data.error_data(xulie2,19),'k--')
            %             hold on
            %     plot(strands_infos(1,:),smooth(strands_infos(5,:)),'r-')
            plot([1:length(LJ_processed_data.error_data(xulie2,19))]*1e-1*cosd(30),smooth(LJ_processed_data.error_data(xulie2,19)),'k.')
            %             hold off
            title('Strand Width','FontSize',12)
            xlabel('X [mm]','FontSize',12)
            ylabel('W [mm]','FontSize',12)
            legend({'origin','smooth'},'FontSize',12)
            grid on
            set(gca,'FontName','Times New Roman')

            subplot(3,1,3)
            %     plot(strands_infos(1,:),strands_infos(6,:),'k--')
            %             plot(LJ_processed_data.error_data(xulie2,12),'k--')
            %             hold on
            %     plot(strands_infos(1,:),smooth(strands_infos(6,:)),'r-')
            plot([1:length(LJ_processed_data.error_data(xulie2,12))]*1e-1*cosd(30),smooth(LJ_processed_data.error_data(xulie2,12)),'k.')
            %             hold off
            title('Strand Height','FontSize',12)
            xlabel('X [mm]','FontSize',12)
            ylabel('H [mm]','FontSize',12)
            legend({'origin','smooth'},'FontSize',12)
            grid on
            set(gca,'FontName','Times New Roman')

            subplot(2,1,1)
            gscatter(LJ_processed_data.error_data(xulie2,1)-min(LJ_processed_data.error_data(xulie2,1)),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,5));
            title('Trajectory','FontSize',12)
            xlabel('X [mm]','FontSize',12)
            ylabel('Y [mm]','FontSize',12)
            grid on
            set(gca,'FontName','Times New Roman')

            subplot(2,1,2)
            title('Strand Features','FontSize',12)
            xlabel('X [mm]','FontSize',12)
            yyaxis left; % 激活左y轴
            plot([1:length(LJ_processed_data.error_data(xulie2,19))]*1e-1*cosd(30),smooth(LJ_processed_data.error_data(xulie2,19)),'k-')
            ylabel('W [mm]','FontSize',12)
            yyaxis right; % 激活右y轴
            plot([1:length(LJ_processed_data.error_data(xulie2,12))]*1e-1*cosd(30),smooth(LJ_processed_data.error_data(xulie2,12)),'b--')
            ylabel('H [mm]','FontSize',12)

            legend({'Strand Width','Strand Height'},'FontSize',12)
            grid on
            set(gca,'FontName','Times New Roman')
        case 2
            sn5 = 1;
            sn6 = 602;
            sn7 = sn6;
            sn8 = sn6;
            %             xulie2 = ~isnan(LJ_processed_data.error_data(:,6));
            xulie0 = ~isnan(LJ_processed_data.error_data(:,6));
            xulie1 = zeros(size(xulie0));
            xulie1([sn5:sn6,sn7:sn8])=1;
            xulie2 = logical(xulie0 .* xulie1);
            figure(4)
            subplot(2,2,1)
            %     plot3(strands_infos(2,:),strands_infos(3,:),strands_infos(4,:),'k.')
            scatter3(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,3),10,LJ_processed_data.error_data(xulie2,6),'fill');
            hold on
            quiver3(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,3),LJ_processed_data.error_data(xulie2,7),LJ_processed_data.error_data(xulie2,8),LJ_processed_data.error_data(xulie2,9)-mean(LJ_processed_data.error_data(xulie2,9)))
            hold off
            title('Trajectory Error 3D')
            xlabel('X [mm]','FontSize',12)
            ylabel('Y [mm]','FontSize',12)
            zlabel('Z [mm]','FontSize',12)
            legend({'Error Value','Error Vector'},'FontSize',12)
            colorbar
            axis equal
            grid on
            set(gca,'FontName','Times New Roman')

            subplot(2,2,2)
            %             xulie2 = ~isnan(LJ_processed_data.error_data(:,6));
            xulie0 = ~isnan(LJ_processed_data.error_data(:,6));
            xulie1 = zeros(size(xulie0));
            xulie1([sn5:sn6,sn7:sn8])=1;
            xulie2 = logical(xulie0 .* xulie1);
            scatter(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),20,LJ_processed_data.error_data(xulie2,6),'fill');
            hold on
            quiver(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,7),LJ_processed_data.error_data(xulie2,8))
            hold off
            title('Trajectory Error','FontSize',12)
            xlabel('X [mm]','FontSize',12)
            ylabel('Y [mm]','FontSize',12)
            zlabel('Z [mm]','FontSize',12)
            legend({'Error Value','Error Vector'},'FontSize',12)
            colorbar
            axis equal
            grid on
            set(gca,'FontName','Times New Roman')

            subplot(2,2,3)
            scatter3(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,3),10,LJ_processed_data.error_data(xulie2,11),'fill');
            title('Strand Width Error','FontSize',12)
            xlabel('X [mm]','FontSize',12)
            ylabel('Y [mm]','FontSize',12)
            zlabel('Z [mm]','FontSize',12)
            view([0 0 1])
            legend({'Strand Width Value'},'FontSize',12)
            colorbar
            axis equal
            grid on
            set(gca,'FontName','Times New Roman')


            subplot(2,2,4)
            scatter3(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,3),10,LJ_processed_data.error_data(xulie2,13),'fill');
            title('Strand Height Error','FontSize',12)
            xlabel('X [mm]','FontSize',12)
            ylabel('Y [mm]','FontSize',12)
            zlabel('Z [mm]','FontSize',12)
            view([0 0 1])
            legend({'Strand Height Value'},'FontSize',12)
            colorbar
            axis equal
            grid on
            set(gca,'FontName','Times New Roman')

            figure(5)
            subplot(3,1,1)
            %     plot3(strands_infos(2,:),strands_infos(3,:),strands_infos(4,:),'k.')
            gscatter(LJ_processed_data.error_data(xulie2,1)-min(LJ_processed_data.error_data(xulie2,1)),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,5));
            title('Trajectory','FontSize',12)
            xlabel('X [mm]','FontSize',12)
            ylabel('Y [mm]','FontSize',12)
            %     zlabel('Z')
            %             axis equal
            grid on
            set(gca,'FontName','Times New Roman')

            subplot(3,1,2)
            %     plot(strands_infos(1,:),strands_infos(5,:),'k--')
            %             plot(LJ_processed_data.error_data(xulie2,19),'k--')
            %             hold on
            %     plot(strands_infos(1,:),smooth(strands_infos(5,:)),'r-')
            plot([1:length(LJ_processed_data.error_data(xulie2,19))]*1e-1*cosd(30),smooth(LJ_processed_data.error_data(xulie2,19)),'k.')
            %             hold off
            title('Strand Width','FontSize',12)
            xlabel('X [mm]','FontSize',12)
            ylabel('W [mm]','FontSize',12)
            legend({'origin','smooth'},'FontSize',12)
            grid on
            set(gca,'FontName','Times New Roman')

            subplot(3,1,3)
            %     plot(strands_infos(1,:),strands_infos(6,:),'k--')
            %             plot(LJ_processed_data.error_data(xulie2,12),'k--')
            %             hold on
            %     plot(strands_infos(1,:),smooth(strands_infos(6,:)),'r-')
            plot([1:length(LJ_processed_data.error_data(xulie2,12))]*1e-1*cosd(30),smooth(LJ_processed_data.error_data(xulie2,12)),'k.')
            %             hold off
            title('Strand Height','FontSize',12)
            xlabel('X [mm]','FontSize',12)
            ylabel('H [mm]','FontSize',12)
            legend({'origin','smooth'},'FontSize',12)
            grid on
            set(gca,'FontName','Times New Roman')

            subplot(2,1,1)
            gscatter(LJ_processed_data.error_data(xulie2,1)-min(LJ_processed_data.error_data(xulie2,1)),LJ_processed_data.error_data(xulie2,2),LJ_processed_data.error_data(xulie2,5));
            title('Trajectory','FontSize',12)
            xlabel('X [mm]','FontSize',12)
            ylabel('Y [mm]','FontSize',12)
            grid on
            set(gca,'FontName','Times New Roman')

            subplot(2,1,2)
            title('Strand Features','FontSize',12)
            xlabel('X [mm]','FontSize',12)
            yyaxis left; % 激活左y轴
            plot([1:length(LJ_processed_data.error_data(xulie2,19))]*1e-1*cosd(30),smooth(LJ_processed_data.error_data(xulie2,19)),'k-')
            ylabel('W [mm]','FontSize',12)
            yyaxis right; % 激活右y轴
            plot([1:length(LJ_processed_data.error_data(xulie2,12))]*1e-1*cosd(30),smooth(LJ_processed_data.error_data(xulie2,12)),'b--')
            ylabel('H [mm]','FontSize',12)

            legend({'Strand Width','Strand Height'},'FontSize',12)
            grid on
            set(gca,'FontName','Times New Roman')
    end
end
%%  轨迹的调整
%   误差数据为LJ_processed_data.error_data；修正后的数据为adjusted_data
%   LJ_processed_data.error_data数据格式：
%       列序号 1   2   3   4   5      6        7   8   9   10    11        12     13        14
%       列项目 X   Y   Z   1   组别   轨迹误差  vx  vy  vz  线宽  线宽误差   线高   线高误差   F
%   adjusted_data数据格式
%       列序号 1   2   3   4   5      6    7          8      9        10      11
%       列项目 X   Y   Z   1   组别   线宽  线宽误差   线高   线高误差  F     df
%       列序号 12       13
%       列项目 喷嘴内径 挤出速率
adjusted_data = zeros(size(LJ_processed_data.error_data,1),11);
%   轨迹矫正
%   思路，原轨迹-误差向量
adjusted_data(:,1) = LJ_processed_data.error_data(:,1)-LJ_processed_data.error_data(:,7);
adjusted_data(:,2) = LJ_processed_data.error_data(:,2)-LJ_processed_data.error_data(:,8);
adjusted_data(:,3) = LJ_processed_data.error_data(:,3)-LJ_processed_data.error_data(:,9)*0;
adjusted_data(:,4) = LJ_processed_data.error_data(:,4);
adjusted_data(:,5) = LJ_processed_data.error_data(:,5);
adjusted_data(:,6) = LJ_processed_data.error_data(:,10);
adjusted_data(:,7) = LJ_processed_data.error_data(:,11);
adjusted_data(:,8) = LJ_processed_data.error_data(:,12);
adjusted_data(:,9) = LJ_processed_data.error_data(:,13);
adjusted_data(:,10)= LJ_processed_data.error_data(:,14);
%   2023-03-08
%   增加喷嘴内径D_LJ[mm]和挤出速率E_LJ[mm/s]，这两个变量是在处理数据前手动添加到.mat文件中的，如果缺失了，需要自己手动定义一下
adjusted_data(:,11)= NaN;
adjusted_data(:,12)= E_LJ;
adjusted_data(:,13)= D_LJ;
tansf_traj = (inv(Tt)*adjusted_data(:,1:4)')';  % 把扫描仪坐标系下的坐标点做坐标变换，从而得到喷嘴坐标系下的轨迹
tranf_trajo= (inv(Tt)*LJ_processed_data.error_data(:,1:4)')';

LJ_processed_data.adjusted_data = adjusted_data;
clear adjusted_data

if (test_flag==1)||(plot_flag2==1)
    %   绘图
    %   先把矫正后的轨迹列出来
    figure(6)
    plot(TJ_X(2:end),TJ_Y(2:end),'k--')
    axis equal
    hold on
    plot(LJ_processed_data.error_data(:,1),LJ_processed_data.error_data(:,2),'k--')
    plot(LJ_processed_data.error_data(:,1)+LJ_processed_data.error_data(:,7),LJ_processed_data.error_data(:,2)+LJ_processed_data.error_data(:,8),'r-.')
    %     plot(tranf_trajo(:,1),tranf_trajo(:,2),'r.')
    plot(LJ_processed_data.adjusted_data(:,1),LJ_processed_data.adjusted_data(:,2),'b-')
    plot(tansf_traj(:,1),tansf_traj(:,2),'b-')
    hold off
    if test_flag~=1
        legendlist = {'Ideal' 'Tans.Ideal' 'Actural' 'Adjusted' 'Transformed'};
    end
    legend(legendlist);
    axis equal
    title('Adjusted Trajectory')
    xlabel('X [mm]')
    ylabel('Y [mm]')
    %   for MSEC 2023-11-13
    %   为MSEC论文专门生成图像，如果需要运行请手动取消下一行的注释，请记得用完了重新注释。
    %     flag_MSEC = 1;
    if flag_MSEC ~=0
        switch flag_MSEC
            case 1
                figure(6)
                %                 plot(TJ_X(xulie2),TJ_Y(xulie2),'k--')
                %                 axis equal
                %                 hold on
                plot(LJ_processed_data.error_data(xulie2,1),LJ_processed_data.error_data(xulie2,2),'k--')
                hold on
                plot(LJ_processed_data.error_data(xulie2,1)+LJ_processed_data.error_data(xulie2,7),LJ_processed_data.error_data(xulie2,2)+LJ_processed_data.error_data(xulie2,8),'r-.')
                %     plot(tranf_trajo(:,1),tranf_trajo(:,2),'r.')
                plot(LJ_processed_data.adjusted_data(xulie2,1),LJ_processed_data.adjusted_data(xulie2,2),'b-')
                %                 plot(tansf_traj(xulie2,1),tansf_traj(xulie2,2),'b-')
                hold off
                if test_flag~=1
                    legendlist = {'Target' 'Actural' 'Adjusted'};
                end
                legend(legendlist);
                axis equal
                title('Adjusted Trajectory')
                xlabel('X [mm]')
                ylabel('Y [mm]')
        end
    end
    %     zlabel('Z [mm]')
end
%%  优化移动速度
%   LJ_processed_data.adjusted_data数据格式
%       列序号 1   2   3   4   5      6    7          8      9        10      11
%       列项目 X   Y   Z   1   组别   线宽  线宽误差   线高   线高误差  F     df
%       列序号 12       13      14
%       列项目 喷嘴内径 挤出速率 F2
%   0. 初始化、交互式确定喷嘴内径和挤出速率。
%   参数确定这一步不需要，只需要在原始数据中做相应调整即可。
%   初始化这个参数
fit_density = 1e4;
%   1. 获取基于实验数据和理论的线截面模型
%   调试的时候可以运行下面这个
%   debug_adjust_data=1;
%   调试完成后可以运行下面这个
%   clear('debug_adjust_data')
if ~exist('debug_adjust_data')
    [strand_model,gof,output,datainfo] = strand_data_converge();
elseif debug_adjust_data==0
    [strand_model,gof,output,datainfo] = strand_data_converge();
end
LJ_processed_data.model.strand_model = strand_model;
LJ_processed_data.model.gof = gof;
LJ_processed_data.model.output = output;
LJ_processed_data.model.datainfo = datainfo;
%   绘制模型曲面
xl = linspace(LJ_processed_data.model.datainfo.Hmin,LJ_processed_data.model.datainfo.Hmax,fit_density);
yl = linspace(LJ_processed_data.model.datainfo.Vmin,LJ_processed_data.model.datainfo.Vmax,fit_density);
[XL,YL] = meshgrid(xl,yl);
ZL = strand_model(XL,YL);
a = strand_model.a;
%   2. 对于线条数据，查询工艺曲面对工艺参数做调整
for i = 1:size(LJ_processed_data.adjusted_data,1)
    %     disp(mod(100*i/size(LJ_processed_data.adjusted_data,1),1))
    if mod(100*i/size(LJ_processed_data.adjusted_data,1),1)<1e-1
        disp([num2str(100*i/size(LJ_processed_data.adjusted_data,1)),'%'])
    end
    %   如果是需要做启停段补偿的数据，则不做速度调整
    if LJ_processed_data.adjusted_data(i,6)>1e-3
        AV = (LJ_processed_data.adjusted_data(i,10))/LJ_processed_data.adjusted_data(i,12)/60;
        AH = (LJ_processed_data.adjusted_data(i,8)-LJ_processed_data.adjusted_data(i,9))/LJ_processed_data.adjusted_data(i,13);
        %   ！！！！如果需要修正的话，需要在这里调节
        AV = AV-a;
        %         AH = AH-strand_model.c;
        %   结束
        ASW= (LJ_processed_data.adjusted_data(i,6))/LJ_processed_data.adjusted_data(i,13);
        TSW= (LJ_processed_data.adjusted_data(i,6)-LJ_processed_data.adjusted_data(i,7)-0*mean(LJ_processed_data.adjusted_data(:,7)))/LJ_processed_data.adjusted_data(i,13);
        ASH= LJ_processed_data.adjusted_data(i,8)/LJ_processed_data.adjusted_data(i,13);
        %   如果不在实验数据的范围内，则应禁止操作，并跳过该点
        if AV<LJ_processed_data.model.datainfo.Vmin || AV>LJ_processed_data.model.datainfo.Vmax ||...
                AH<LJ_processed_data.model.datainfo.Hmin || AH>LJ_processed_data.model.datainfo.Hmax
            msg = '不在实验数据的范围内，禁止操作，并跳过该点';
            warning(msg)
            %             continue
            xl2 = linspace(min(LJ_processed_data.model.datainfo.Hmin,AH),max(LJ_processed_data.model.datainfo.Hmax,AH),fit_density);
            yl2 = linspace(min(LJ_processed_data.model.datainfo.Vmin,AV),max(LJ_processed_data.model.datainfo.Vmax,AV),fit_density);
            [XL2,YL2] = meshgrid(xl2,yl2);
            TXL = XL2;
            TYL = YL2;
            TZL = strand_model(XL2,YL2);
        else
            TXL = XL;
            TYL = YL;
            TZL = ZL;
        end
        %   进行线宽的调整
        %   判断实际线宽是否在模型范围内
        if ASW<min(min(TZL)) || ASW>max(max(TZL))
            % 不在范围内，警告并做调整
            msg = ['第',num2str(i),'个数据的线宽(',num2str(LJ_processed_data.adjusted_data(i,6)),'mm),不在模型接受范围[',num2str(min(min(TZL))),',',num2str(max(max(TZL))),']内，将其置为模型极值！'];
            warning(msg)
            if ASW<min(min(TZL))
                ASW = min(min(TZL));
            elseif ASW<max(max(TZL))
                ASW = max(max(TZL));
            end
        end
        %   在模型曲面上寻找符合实际线宽的数据点
        Z_sn = find(abs(TZL-ASW)<=1e-3);
        Xsolu = TXL(Z_sn);
        Ysolu = TYL(Z_sn);
        Zsolu = TZL(Z_sn);
        %   绘图
        if plot_flag3==1
            figure(6)
            plot(strand_model)
            xlabel('H/a_0')
            ylabel('V/U')
            zlabel('W')
            hold on
            plot3(Xsolu,Ysolu,Zsolu,'r.')
            %             plot3(ASH,AV,strand_model(ASH,AV),'y.','MarkerSize',50)
            plot3(AH,AV,strand_model(AH,AV),'y.','MarkerSize',50)
            hold off
            view([0 0 1])
        end
        %   找到参数范围内距离实际点最近的点
        %         distv= [Xsolu-ASH,Ysolu-AV,Zsolu-ASW];
        distv= [Xsolu-AH,Ysolu-AV,Zsolu-ASW];
        dist = sqrt(distv(:,1).^2+distv(:,2).^2+distv(:,3).^2);
        distp= find(dist==min(dist));
        xm = Xsolu(distp);
        ym = Ysolu(distp);
        zm = Zsolu(distp);
        %   绘图
        if plot_flag3==1
            hold on
            plot3(xm,ym,zm,'g.','MarkerSize',50)
            hold off
        end
        %   查找目标值对应的曲线
        Z_sn2 = find(abs(TZL-TSW)<=1e-3);
        if isempty(Z_sn2)
            warning('找不到调整点，舍弃')
            continue
        end
        Xsolu2 = TXL(Z_sn2);
        Ysolu2 = TYL(Z_sn2);
        Zsolu2 = TZL(Z_sn2);
        %   绘图
        if plot_flag3==1
            hold on
            plot3(Xsolu2,Ysolu2,Zsolu2,'g.')
            hold off
        end
        %   按照只调整UH找到上一步结果中符合结果的点
        distv2=Xsolu2-xm;
        dist2 =abs(distv2);
        distp2=find(dist2 == min(dist2) );
        if length(distp2)>1
            distp2(2:end)=[];
        end
        Xsolu3 = Xsolu2(distp2);
        Ysolu3 = Ysolu2(distp2);
        Zsolu3 = Zsolu2(distp2);
        %   绘图
        if plot_flag3==1
            hold on
            plot3(Xsolu3,Ysolu3,Zsolu3,'r.','MarkerSize',50)
            quiver3(xm,ym,zm,Xsolu3-xm,Ysolu3-ym,Zsolu3-zm,'r')
            hold off
            title(['i=',num2str(i),',实际线宽:',num2str(LJ_processed_data.adjusted_data(i,6)),'mm,理想线宽:',num2str(LJ_processed_data.adjusted_data(i,6)-LJ_processed_data.adjusted_data(i,7)-mean(LJ_processed_data.adjusted_data(:,7))),'mm.'])
            pause(0.005)
        end
        %   把速度的变化量记录下来
        LJ_processed_data.adjusted_data(i,11) = 60*LJ_processed_data.adjusted_data(i,12)*(Ysolu3-ym);
    end
end
%   计算调整后的速度，并记录
temp = round(LJ_processed_data.adjusted_data(:,10) + LJ_processed_data.adjusted_data(:,11));
temp(temp<0)=NaN;
LJ_processed_data.adjusted_data(:,14) = temp;
clear temp
%   速度调整完毕，记录数据
LJ_processed_data.adjusted_data = LJ_processed_data.adjusted_data;
tansf_traj(:,5)=LJ_processed_data.adjusted_data(:,14);
LJ_processed_data.tansf_traj = tansf_traj;
clear tansf_traj
%%  绘图4
%   绘制对比图
if plot_flag2 == 1
    figure(7)
    subplot(1,2,1)
    temp = LJ_processed_data.adjusted_data(:,10) + LJ_processed_data.adjusted_data(:,11);
    temp(temp<0)=NaN;
    scatter(LJ_processed_data.adjusted_data(:,1),LJ_processed_data.adjusted_data(:,2),50,temp,'fill')
    hold on
    plot(LJ_processed_data.error_data(:,1),LJ_processed_data.error_data(:,2),'b--')
    plot(LJ_processed_data.adjusted_data(:,1),LJ_processed_data.adjusted_data(:,2),'r-')
    hold off
    axis equal
    colorbar
    xlabel('x [mm]')
    ylabel('y [mm]')
    title('Adjusted Trajectory and Feedrates')
    subplot(1,2,2)
    scatter(LJ_processed_data.error_data(:,1),LJ_processed_data.error_data(:,2),50,LJ_processed_data.error_data(:,14),'fill')
    hold on
    plot(LJ_processed_data.error_data(:,1),LJ_processed_data.error_data(:,2),'r--')
    hold off
    axis equal
    colorbar
    xlabel('x [mm]')
    ylabel('y [mm]')
    title('Original Trajectory and Feedrates')
end
%%  拟合样条曲线并生成G代码序列
test_d_cmd_flag=1;  %G05代码测试
%   Addred on 2023-12-09
%   LJ_processed_data.adjusted_data数据格式
%       列序号 1   2   3   4   5      6    7          8      9        10      11
%       列项目 X   Y   Z   1   组别   线宽  线宽误差   线高   线高误差  F     df
%       列序号 12       13      14
%       列项目 喷嘴内径 挤出速率 F2
%   首先，确认分组数量
curve_group = unique(LJ_processed_data.adjusted_data(:,5));
curve_num   = length(curve_group);
curve_cps   = [];
draft_gcode = [];
temp_curve_fitting = struct('curve_model',[]);
flag_dwell  = 0;
p_on        = 106;
p_off       = 107;
%   然后，拟合并提取控制点，保存在curve_cps中
%列数: 1       2       3       4       5       6       7       8       9
%解释: P1_x    P1_y    P2_x    P2_y    P3_x    P3_y    P4_x    P4_y    group
%列数: 10      11      12      13      
%解释: F_1     F_2     P1_z    P4_z
for i=1:curve_num
    %   找第i组的序号
    sn_curve_points = find(LJ_processed_data.adjusted_data(:,5)==curve_group(i));
    %   拟合第i组的轨迹
    temp_spline = cp_extract_cspline(LJ_processed_data.adjusted_data(sn_curve_points,1),LJ_processed_data.adjusted_data(sn_curve_points,2),0.97);
    %   计算第i组是否有延迟
    temp_dwell  = find(isnan(LJ_processed_data.adjusted_data(sn_curve_points,14)));
    %   如果有延迟，则计算一下需要停留的时间
    temp_t = [];
    if ~isempty(temp_dwell)
        %   先找到第一组延迟，剔除杂点
        temp_label  = dbscan(temp_dwell,1,1);
        temp_dwell(temp_label~=1)=[];
        %   二次判断
        if ~isempty(temp_dwell)
            flag_dwell = 1;
            %   先把坐标点和速度找到
            temp_x = LJ_processed_data.adjusted_data(sn_curve_points,1);
            temp_y = LJ_processed_data.adjusted_data(sn_curve_points,2);
            temp_z = LJ_processed_data.adjusted_data(sn_curve_points,3);
            temp_f = LJ_processed_data.adjusted_data(sn_curve_points,10);
            temp_f2= LJ_processed_data.adjusted_data(sn_curve_points,14);
            %   这里通过均值滤波，找到加速完成的节点，然后该节点之前的部分平移到起点，中间的部分做一下填充
            num_filt = 20;
            test_temp = NaN(length(temp_f2)-num_filt,1);
            for j = 1:length(temp_f2)-num_filt
                test_temp(j) = temp_f2(j+round(num_filt/2),1)-mean(temp_f2(j:j+num_filt,1));
            end
            %   做个简单的测试
            if test_d_cmd_flag ==1
                figure(2)
                subplot(3,1,1)
                plot(temp_f2)
                subplot(3,1,2)
                plot(test_temp)
                subplot(3,1,3)
                semilogy(abs(test_temp))
            end
            %   计算偏移量，并作置换
            slide = find(log10(test_temp)<=1,1,'First');
            temp_f0 = temp_f(temp_dwell);
            temp_f2(1:slide-temp_dwell(end))=temp_f2(temp_dwell(end)+1:slide);
            temp_f2(slide-temp_dwell(end)+1:slide)=temp_f0;
            clear temp_f0
            %   然后计算延迟区经历的时间
            temp_xx = temp_x(temp_dwell);
            temp_yy = temp_y(temp_dwell);
            temp_zz = temp_z(temp_dwell);
            temp_ff = temp_f(temp_dwell);
            temp_t = sum( ...
                    ( ...
                    (temp_xx(2:end)-temp_xx(1:end-1)).^2+ ...
                    (temp_yy(2:end)-temp_yy(1:end-1)).^2+ ...
                    (temp_zz(2:end)-temp_zz(1:end-1)).^2 ...
                    ).^0.5.* ...
                    60.*1000./temp_ff(2:end) ...
                    ); %ms
        end
    end
    if flag_dwell ~= 1
        temp_x = LJ_processed_data.adjusted_data(sn_curve_points,1);
        temp_f2= LJ_processed_data.adjusted_data(sn_curve_points,14);
    end
    %   拟合第i组的速度
    temp_fcurve = cp_extract_cspline(temp_x,temp_f2,0.90);
    %   拟合高度信息
    temp_zcurve = cp_extract_cspline(temp_x,temp_z,0.90);
    %   保存数据
    temp_curve_cps = [  temp_spline.controlpoints,...
                        ones(size(temp_spline.controlpoints,1),1)*curve_group(i),...
                        temp_fcurve.curve_model(temp_spline.controlpoints(:,1)),...
                        temp_fcurve.curve_model(temp_spline.controlpoints(:,7)),...
                        temp_zcurve.curve_model(temp_spline.controlpoints(:,1)),...
                        temp_zcurve.curve_model(temp_spline.controlpoints(:,7))];
    %   结束
    curve_cps = [curve_cps;temp_curve_cps];
    eval(['temp_curve_fitting.curve_model.curve_',num2str(i),' = temp_spline.curve_model;']);
    eval(['temp_curve_fitting.curve_model.fcurve_',num2str(i),' = temp_fcurve.curve_model;']);
    eval(['temp_curve_fitting.curve_model.dwell_',num2str(i),'.sn = temp_dwell;']);
    eval(['temp_curve_fitting.curve_model.dwell_',num2str(i),'.t = temp_t;']);
    % end
    %   接着，生成G代码草稿
    % 1         2   3   4   5   6   7   8   9
    % cmd_num
    %       G   1   X   Y   Z   E   F
    %       G   4   S   P
    %       G   5   E   F   I   J   P   Q   X   Y
    %       M   106
    %       M   107
    % abs('G') = 71
    % abs('M') = 77
    %   按照最大尺寸初始化temp_draft_gcode
    temp_draft_gcode = NaN(size(temp_curve_cps,1)+4,10);
    num_int = 1;
    % for i=1:curve_num
    %   先找到第一个点在什么地方
    first_position = find(temp_curve_cps(:,9)==i,1,'first');
    %   然后先移动到第一个点
    temp_draft_gcode(num_int,[1:5,7])=[71,0,temp_curve_cps(first_position,[1:2,12]),3000];
    num_int = num_int+1;
    %   然后打开气压
    temp_draft_gcode(num_int,1:2)=[77,p_on];
    num_int = num_int+1;
    if flag_dwell == 1
        %   有延迟时，等待一会，再开始移动
        temp_draft_gcode(num_int,1:3)=[71,4,temp_t];
        num_int = num_int+1;
        flag_dwell = 0;
    end
    %   写入G05代码草稿
    for j=1:sum(temp_curve_cps(:,9)==i)
        % temp_draft_gcode(num_int,[1 2 4 5 6 7 8 9 10])=[71,5,temp_curve_cps(first_position+j-1,11),temp_curve_cps(first_position+j-1,3:8)];
        %   2024-01-18 Martin:  Symbols of columns 7 and 8 in temp_draft_gcode
        %                       (columns 5 adn 6 in temp_curve_cps) need be
        %                       reversed as showed in cp_extract_cspline()
        %                       row 142
        %                       "(quiver(controlpoints(:,7),controlpoints(:,8),-controlpoints(:,5),-controlpoints(:,6),0))"
        temp_draft_gcode(num_int,[1 2 4 5 6 7 8 9 10])=[71,5,temp_curve_cps(first_position+j-1,11),temp_curve_cps(first_position+j-1,3:4),-temp_curve_cps(first_position+j-1,5:6),temp_curve_cps(first_position+j-1,7:8)];
        num_int = num_int+1;
    end
    %   然后打开气压
    temp_draft_gcode(num_int,1:2)=[77,p_off];
    num_int = num_int+1;
    temp_draft_gcode(isnan(temp_draft_gcode(:,1)),:)=[];
    draft_gcode = [draft_gcode;temp_draft_gcode];
end
%   保存和清理
temp_curve_fitting.curve_cps = curve_cps;
temp_curve_fitting.draft_gcode = draft_gcode;
LJ_processed_data.curve_fitting = temp_curve_fitting;
clear curve_cps temp_curve_cps temp_draft_gcode draft_gcode temp_curve_fitting
%%  绘制和测试代码正确性
if test_d_cmd_flag ==1
    sn_g_cmd = find(LJ_processed_data.curve_fitting.draft_gcode(:,1)==71);
    draft_g_cmd = LJ_processed_data.curve_fitting.draft_gcode(sn_g_cmd,:);
    num_t = 5;
    % t  = linspace(0,1,5)';
    pc = [0 0];
    tp = [0 0];
    cf = 0;
    tf = 0;
    tpp = [];
    tff = [];
    figure(1)
    % hold on
    for i=1:size(draft_g_cmd,1)
        % disp(i)
        switch draft_g_cmd(i,2)
            case {0,1}
                t  = linspace(0,1,num_t*10)';
                tp = draft_g_cmd(i,3:4);
                tf = draft_g_cmd(i,7);
                if isnan(tf)
                    error('f is error')
                end
                ttp= (1-t)*pc+t*tp;
                ttf= (1-t)*cf+t*tf;
                % scatter(ttp(:,1),ttp(:,2),5,'filled')
                tpp=[tpp;ttp];
                tff=[tff;ttf];
                if size(tpp,1)~=size(tff,1)
                    error(['i=',num2str(i)])
                end
                pc = tp;
                cf = tf;
            case 4

            case 5
                t  = linspace(0,1,num_t)';
                tf = draft_g_cmd(i,4);
                if isnan(tf)
                    error('f is error')
                end
                p1 = draft_g_cmd(i,5:6);
                p2 = draft_g_cmd(i,7:8);
                tp = draft_g_cmd(i,9:10);
                ttp = zeros(length(t),2);
                for j=1:length(t)
                    [ttp(j,1),ttp(j,2)]=eval_cubic_spline([pc;pc+p1;tp-p2;tp],t(j),3);
                end
                ttf= (1-t)*cf+t*tf;
                % scatter(ttp(:,1),ttp(:,2),5,'filled')
                tpp=[tpp;ttp];
                tff=[tff;ttf];
                if size(tpp,1)~=size(tff,1)
                    error(['i=',num2str(i)])
                end
                pc = tp;
                cf = tf;
            otherwise
                disp(skip)
        end
        % plot(tpp(:,1),tpp(:,2),'ro')
        % pause(0.5)
    end
    for i = 1:size(tpp,1)
        if rem(i,round(length(tff)*0.01))==0
            scatter(tpp(1:i,1),tpp(1:i,2),10,tff(1:i),'filled')
            pause(0.05)
        end
    end
    % hold off
    axis equal
end
%%  生成打印Gcode 子程序 G05
code_prefix = {...
    'G28;';...
    'G0 F3000;';...
    'G0 Z3.000;'...
    };
code_behind = {...
    'M107;';...
    'G91;';...
    'G0 F3000;';...
    'G0 Z2;';...
    'G90;';...
    'G00 X0 Y0;'...
    };
code_interl = {...
    };
gcode_gen_g05(LJ_processed_data.curve_fitting.draft_gcode,code_prefix,code_behind,code_interl);
%%  生成打印Gcode
%   LJ_processed_data.adjusted_data数据格式
%       列序号 1   2   3   4   5      6    7          8      9        10      11
%       列项目 X   Y   Z   1   组别   线宽  线宽误差   线高   线高误差  F     df
%       列序号 12       13      14
%       列项目 喷嘴内径 挤出速率 F2
%   初始化
offset = [  0.000;...
    0.000;...
    0.000;...
    0.000;...
    0.000;...
    0.000;...
    ];
X_Offset=offset(1);
Y_Offset=offset(2);
Z_Offset=offset(3);
A_Offset=offset(4);
B_Offset=offset(5);
C_Offset=offset(6);
Flag_Air_Target= 0;                         %目标气压状态
Flag_Air_Current = Flag_Air_Target;         %当前气压状态
Target_Position = zeros(1,2);               %目标位置
%   新建并打开文档
[pname2] = uigetdir([],'Choose a Path to save GCODE');
fname2 = 'Gcode4Print.gcode';
% fname5 = 'Gcode4Print.mat';
if isequal(fname,0)
    error('User selected Cancel');
else
    disp(fullfile(pname2,fname2));
end
str = [pname2,'\',fname2];
fid = fopen(str,'w');
%   前置代码
fprintf(fid,'%s \n','G28;');
fprintf(fid,'%s \n','G0 F3000;');
fprintf(fid,'%s \n','G0 Z3.000;');
% fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G0 X',XO,' Y',YO,' Z',LO,' F',FO,';');
% %   2022-01-20 这里应该把F的数值改为整数
% fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G0 X',XO,' Y',YO,' Z',LO,' F',FO,';');
%   2023-03-10 这里变量为*_LJ(1)
fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G0 X',X_LJ(1),' Y',Y_LJ(1),' Z',Z_LJ(1),' F',F_LJ(1),';');
fprintf(fid,'%s \n','G92 X0 Y0 Z0 E0;');
Current_Position = [0, 0, 0, 0, 0, 0];
%   No.     1   2   3   4   5   6
%   Name    X   Y   Z   E   F   P
%   开始循环
%   2023-03-10 因为数据处理中删除了前置点，所以应该先把喷嘴移动到第一个点
% if isnan(LJ_processed_data.adjusted_data(1,14))
%     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G0 X',LJ_processed_data.adjusted_data(1,1),' Y',LJ_processed_data.adjusted_data(1,2),' Z',LJ_processed_data.adjusted_data(1,3),' F',F_LJ(1),';');
% else
%     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G0 X',LJ_processed_data.adjusted_data(1,1),' Y',LJ_processed_data.adjusted_data(1,2),' Z',LJ_processed_data.adjusted_data(1,3),' F',LJ_processed_data.adjusted_data(1,14),';');
% end
%   2023-04-05 修改了这个部分，这里带入的应该是喷嘴坐标系下的坐标
if isnan(LJ_processed_data.adjusted_data(1,14))
    fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G0 X',LJ_processed_data.tansf_traj(1,1),' Y',LJ_processed_data.tansf_traj(1,2),' Z',LJ_processed_data.tansf_traj(1,3),' F',F_LJ(1),';');
else
    fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G0 X',LJ_processed_data.tansf_traj(1,1),' Y',LJ_processed_data.tansf_traj(1,2),' Z',LJ_processed_data.tansf_traj(1,3),' F',LJ_processed_data.adjusted_data(1,14),';');
end
%   2023-04-05 END
for i = 1:size(LJ_processed_data.adjusted_data,1)
    %   2023-03-10 如果移动速度为NaN需要跳过当前位置
    if isnan(LJ_processed_data.adjusted_data(i,14))
        warning(['第',num2str(i),'个点移动速率为NaN，跳过！'])
        continue
    end
    %Part1：初始化
    %     Flag_Air_Target = 1;
    %   2022-01-15 这里修改了一下
    Target_Position = Current_Position;%2023-03-06 初始化Target_Position
    %     Flag_Air_Target = Trajectory4Print(i,13);
    %   2023-03-10 修改了Flag_Air_Target的判别方法
    if LJ_processed_data.adjusted_data(i,5)<1
        %   目标点分组为杂点
        Flag_Air_Target = 0;
    elseif LJ_processed_data.adjusted_data(i,5)==Current_Position(6)
        %   目标点分组与当前点一致
        Flag_Air_Target = 1;
    else
        %   目标点分组与当前点不同
        Flag_Air_Target = 0;
    end
    %     Target_Position(1:2) = [Trajectory4Print(i,6),Trajectory4Print(i,7)];
    %   2023-03-10 修改这部分代码
    %     Target_Position(1:3) = LJ_processed_data.adjusted_data(i,1:3);
    %   2023-04-05 修改了这个部分，这里带入的应该是喷嘴坐标系下的坐标
    Target_Position(1:3) = LJ_processed_data.tansf_traj(i,1:3);
    %   2023-04-05 修改结束
    Target_Position(5) = LJ_processed_data.adjusted_data(i,14);
    Target_Position(6) = LJ_processed_data.adjusted_data(i,5);
    %     Line_Type = Trajectory4Print(i,2);
    %   2023-03-10 修正后的轨迹都为直线，因此直接定义Line_Type=1
    Line_Type=1;
    %     %   这部分确定气压开关状态是否改变，若改变则进行操作。
    %     try
    %         temp_air = Trajectory4Airpressure(find(...
    %             (Trajectory4Airpressure(i,6)==Target_Position(1))&...
    %             (Trajectory4Airpressure(i,7)==Target_Position(2))...
    %             ));
    %     catch
    %         Flag_Air_Target = 0;
    %     end
    %   2022-01-15 气压状态根据Trajectory4Print第13列的标志位确定，因此不需要这一段了
    %Part2：气压工作状态确定
    Flage_Change_Air = ~isequal(Flag_Air_Target,Flag_Air_Current);
    if Flage_Change_Air == 1
        switch Flag_Air_Target
            case 1
                fprintf(fid,'%s \n','M106;');
            case 0
                fprintf(fid,'%s \n','M107;');
            otherwise
                error('气压数据错误')
        end
    end
    Flag_Air_Current = Flag_Air_Target;
    %Part3：点位写入
    %   这部分需要判断线型，若为直线，直接写G01，若是弧线，判断G02还是G03，然后写入
    switch Line_Type
        case 1 %直线
            %             fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G01 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' Z',0,' F',FO,';');
            %             %   2022-01-20 这里应该把F的数值改为整数
            %             fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%u%s \n','G01 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' Z',0,' F',FO,';');
            %   2023-03-06 增加挤出量计算
            Target_Position(4) = Current_Position(4) + norm(Target_Position(1:3)-Current_Position(1:3));
            fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s \n','G01 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' Z',0,' E',Target_Position(4),' F',Target_Position(5),';');
            %   2023-03-10 修正后的线条只有直线，因此把弧线部分注释掉
            %         case 2 %弧线
            %             isG02 = sign(Trajectory4Print(i,12)-Trajectory4Print(i,11));
            %             R = Trajectory4Print(i,10);
            %             %   2023-03-06 增加挤出量计算（半径R×角度变化量=弧长=挤出增加量）
            %             Target_Position(4) = Current_Position(4) + R * deg2rad(abs(Trajectory4Print(i,12)-Trajectory4Print(i,11)));
            %             switch isG02
            %                 case 1
            %                     %                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G02 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' F',FO,';');
            %                     %                     %   2022-01-20 这里应该把F的数值改为整数
            %                     %                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%u%s \n','G02 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',0,' F',FO,';');
            %                     %   2023-03-06 增加挤出量计算
            %                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s \n','G02 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' E',Target_Position(4),' F',FO,';');
            %                 case -1
            %                     %                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G03 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' F',FO,';');
            %                     %                     %   2022-01-20 这里应该把F的数值改为整数
            %                     %                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%u%s \n','G03 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' F',FO,';');
            %                     %   2023-03-06 增加挤出量计算
            %                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s \n','G03 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' E',Target_Position(4),' F',FO,';');
            %                 otherwise
            %                     warn(['弧线错误，跳过第',num2str(i),'行'])
            %                     continue
            %             end
        otherwise
            warn(['线型未知，跳过第',num2str(i),'行'])
            continue
    end
    Current_Position = Target_Position;
end
%   后置代码
fprintf(fid,'%s \n','M107;');
fprintf(fid,'%s \n','G91;');
fprintf(fid,'%s \n','G0 F3000;');
fprintf(fid,'%s \n','G0 Z2;');
fprintf(fid,'%s \n','G90;');
fprintf(fid,'%s \n','G00 X0 Y0;');
%   关闭文件
fclose(fid);
%%  生成打印Gcode - G05样条插补
gcode_gen_g05(temp_curve_fitting);
%%  结束
return
%%  dbscan练习
epsilon=3;
minpts=50;
for i = 1:length(x)g
    x = strands_infos(2,1:i)';
    y = strands_infos(3,1:i)';
    labels = dbscan([x,y],epsilon,minpts);
    gscatter(x,y,labels);
    pause(0.01)
end