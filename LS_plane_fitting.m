function obj = LS_plane_fitting(obj,plot_flag)
%%  依赖关系判断
if obj.syset.flags.read_flag_pc~=1
    error('point cloud has not been processed yet!')
end
%%  拟合
if ~exist("plot_flag")
    plot_flag=0;
end
seg = 0.1;          %使用时fit mode = 1;拟合精度mm
num = 1000;         %使用时fit mode = 2;拟合精度网格数量

temp = [obj.PC_data_merged.Merged_PC.X];

x_profile = temp(:,1);
y_profile = temp(:,2);
z_profile = temp(:,3);
clear temp
%   剔除无效点
snxyz = ~isnan(x_profile) & ~isnan(y_profile) & ~isnan(z_profile);
%   平面拟合（用于姿态矫正）
%   例子，由ChatGPT生成：
% 假设你有点云数据点保存在变量 points 中，每个点由三个坐标组成
% points 应该是一个 N×3 的矩阵，其中 N 是点的数量
points = [x_profile(snxyz), y_profile(snxyz), z_profile(snxyz)];
% 使用 fit 函数拟合成平面
fitresult = fit([points(:,1), points(:,2)], points(:,3), 'poly11');
% fitresult = fit([points(:,1), points(:,2)], points(:,3), 'poly23');

%   保存数据
obj.Surface.plane_eq = fitresult;

%% 显示拟合结果
if plot_flag
    subplot(2,2,1)
    scatter(points(:,1),points(:,2),3,points(:,3)-fitresult(points(:,1),points(:,2)),"filled")
    colorbar
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    title('Fitted Plane');
    % view([0 0 1])

    subplot(2,2,2)
    scatter(points(:,1),points(:,3)-fitresult(points(:,1),points(:,2)),3,points(:,3)-fitresult(points(:,1),points(:,2)),"filled")
    colorbar
    xlabel('X');
    ylabel('Z');
    % zlabel('Z');
    title('Fitted Plane');
    % view([1 0 0])

    subplot(2,2,3)
    scatter(points(:,2),points(:,3)-fitresult(points(:,1),points(:,2)),3,points(:,3)-fitresult(points(:,1),points(:,2)),"filled")
    colorbar
    xlabel('Y');
    ylabel('Z');
    % zlabel('Z');
    title('Fitted Plane');
    % view([0 1 0])

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
%%  结束与标记
obj.syset.flags.read_flag_pf = 1;
end