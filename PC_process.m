function obj = PC_process(obj,plot_flag)
%%  依赖关系判断
if obj.syset.flags.read_flag_scaner~=1
    error('has not scanned yet!')
end
%%  globalICP object 2024-01-24
if ~exist("plot_flag")
    plot_flag=0;
end
demo_flag = 0;
% close all

% Create globalICP object
folder_type = 2;
switch folder_type
    case 1
        icp = globalICP('OutputFolder', cd, 'TempFolder', 'D:\temp');
    case 2
        icp = globalICP('OutputFolder', obj.syset.path_pc_out, 'TempFolder', obj.syset.path_pc_tmp);
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
    pc = lj2pc(obj);
    n = length(pc);
    for i = 1:n
        temp_pc = pc(i).ptcCloud.X;
        icp.addPC(temp_pc);
    end
end

% Plot all point clouds BEFORE ICP (each in a different random color)
% figure; icp.plot('Color', 'random');
% figure
if plot_flag
    icp.plot('Color', 'random');
    title('BEFORE ICP'); view(0,0);
end

% Run ICP!
if demo_flag==1
    icp.runICP('PlaneSearchRadius', 2);
else
    if n>1
        c = 0.2:-0.1:0.1;
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
    else
        msg = '组数小于2不执行全局对齐操作';
        disp(msg)
    end
end
if plot_flag
    % Plot all point clouds AFTER ICP
    close
    % figure;
    icp.plot('Color', 'random');
    title('AFTER ICP'); view(0,0);
end
%%  保存
%   保存数据
%   (1) 把单独的点云数据保存到Laser_Scan.PC_data(i).ipc中
merged_points = [];
for i = 1:n
    temp_path = cell2mat(icp.PC(i));
    temp_pc = load(temp_path,"obj");
    obj.PC_data(i).icp=temp_pc.obj;
    merged_points = [merged_points;obj.PC_data(i).icp.X];
end
%   (2) 合并数据并保存
%   把ICP对象保存为Laser_Scan.PC_data_merged.IPC,把点云数据合并并生成新的对象，
%   保存在Laser_Scan.PC_data_merged.Merged_PC中
obj.PC_data_merged.IPC=icp;
obj.PC_data_merged.Merged_PC = pointCloud(merged_points);
% %   (3) 更新截面数据
% obj.LJ_data_adjusted = obj.LJ_data;
% for i = 1:length([obj.LJ_data_adjusted])
%
% end

%   清除无用中间变量
clear ME icp temp_path temp_pc path merged_points pc
%%   绘图看看
if plot_flag
    figure(4)
    scatter(obj.PC_data_merged.Merged_PC.X(:,1),obj.PC_data_merged.Merged_PC.X(:,2),5,obj.PC_data_merged.Merged_PC.X(:,3),'filled')
    hold on
    plot([obj.LJ_data(2:end).Scan_Traj_X]',[obj.LJ_data(2:end).Scan_Traj_Y]','r-')
    % plot(obj.TJ_data.TJ4PT(:,6),obj.TJ_data.TJ4PT(:,7),'r-')
    hold off
end
%%  结束与标记
obj.syset.flags.read_flag_pc = 1;
end