function pc = PC_process_adv(obj,pc,n,o,m)
close
nn = length(pc);
if nn<=1
    error('点云组数不足')
elseif n<2
    error('请选择第2组及后续组变换')
end
p1 = [pc(n).pc.X,ones(size(pc(n).pc.X,1),1)];

% %   绘图before
% subplot(1,2,1)
% temp=[];
% for i=1:nn
%     temp = [temp;pc(i).pc.X];
% end
% scatter3(temp(:,1),temp(:,2),temp(:,3),5,temp(:,3),"filled");
% title('before')
% view([0 0 1])
% axis equal

%   先做变换
sn = ~isnan(p1(:,1))&~isnan(p1(:,2))&~isnan(p1(:,3));
center = mean(p1(sn,1:3));
switch m
    case 1 %绝对坐标
        trans = trans_matrix(o,1);
    case 2 %相对坐标
        trans = trans_matrix([center,0,0,0],1)*trans_matrix(o,1)*trans_matrix([-center,0,0,0],1);
end
p2 = (trans*p1')';
pc(n).pc.X = p2(:,1:3);

%   绘图 afer
% subplot(1,2,2)
for i=1:nn
    pc(i).pc.plot;
end
% scatter3(temp(:,1),temp(:,2),temp(:,3),5,temp(:,3),"filled");
hold on
plot3(center(1),center(2),center(3),'r+');
% hold off
title('after')
view([0 0 1])
% axis equal
%   接着保存变换
% %%  globalICP object 2024-01-24
% if ~exist("plot_flag")
%     plot_flag=0;
% end
% demo_flag = 0;
% % close all
% 
% % Create globalICP object
% folder_type = 2;
% switch folder_type
%     case 1
%         icp = globalICP('OutputFolder', cd, 'TempFolder', 'D:\temp');
%     case 2
%         icp = globalICP('OutputFolder', obj.syset.path_pc_out, 'TempFolder', obj.syset.path_pc_tmp);
% end
% 
% % Add point clouds to object from plain text files
% % (Added point clouds are saved as mat files, e.g. LionScan1Approx.mat)
% if demo_flag==1
%     icp.addPC('LionScan1Approx.xyz');
%     icp.addPC('LionScan2Approx.xyz');
%     icp.addPC('LionScan3Approx.xyz');
%     icp.addPC('LionScan4Approx.xyz');
%     icp.addPC('LionScan5Approx.xyz');
%     icp.addPC('LionScan6Approx.xyz');
% else
%     pc = lj2pc(obj);
%     n = length(pc);
%     for i = 1:n
%         temp_pc = pc(i).ptcCloud.X;
%         icp.addPC(temp_pc);
%     end
% end
% 
% % Plot all point clouds BEFORE ICP (each in a different random color)
% % figure; icp.plot('Color', 'random');
% % figure
% if plot_flag
%     icp.plot('Color', 'random');
%     title('BEFORE ICP'); view(0,0);
% end
% 
% % Run ICP!
% if demo_flag==1
%     icp.runICP('PlaneSearchRadius', 2);
% else
%     c = 1:-0.1:0.1;
%     for i=1:length(c)
%         try icp.runICP('PlaneSearchRadius', c(i));
%             % close
%             % icp.plot('Color', 'random');
%             % title('AFTER ICP'); view(0,0);
%         catch ME
%             icp.runICP('PlaneSearchRadius', c(i-1))
%             % close
%             % icp.plot('Color', 'random');
%             % title('AFTER ICP'); view(0,0);
%             msg = ['精度极限为',num2str(c(i-1))];
%             disp(msg)
%             break
%         end
%     end
% end
% if plot_flag
%     % Plot all point clouds AFTER ICP
%     close
%     % figure;
%     icp.plot('Color', 'random');
%     title('AFTER ICP'); view(0,0);
% end
% %%  保存
% %   保存数据
% %   (1) 把单独的点云数据保存到Laser_Scan.PC_data(i).ipc中
% merged_points = [];
% for i = 1:n
%     temp_path = cell2mat(icp.PC(i));
%     temp_pc = load(temp_path,"obj");
%     obj.PC_data(i).icp=temp_pc.obj;
%     merged_points = [merged_points;obj.PC_data(i).icp.X];
% end
% %   (2) 合并数据并保存
% %   把ICP对象保存为Laser_Scan.PC_data_merged.IPC,把点云数据合并并生成新的对象，
% %   保存在Laser_Scan.PC_data_merged.Merged_PC中
% obj.PC_data_merged.IPC=icp;
% obj.PC_data_merged.Merged_PC = pointCloud(merged_points);
% % %   (3) 更新截面数据
% % obj.LJ_data_adjusted = obj.LJ_data;
% % for i = 1:length([obj.LJ_data_adjusted])
% %
% % end
% 
% %   清除无用中间变量
% clear ME icp temp_path temp_pc path merged_points pc
% %%   绘图看看
% if plot_flag
%     figure(4)
%     scatter(obj.PC_data_merged.Merged_PC.X(:,1),obj.PC_data_merged.Merged_PC.X(:,2),5,obj.PC_data_merged.Merged_PC.X(:,3),'filled')
%     hold on
%     plot([obj.LJ_data(2:end).Scan_Traj_X]',[obj.LJ_data(2:end).Scan_Traj_Y]','r-')
%     % plot(obj.TJ_data.TJ4PT(:,6),obj.TJ_data.TJ4PT(:,7),'r-')
%     hold off
% end
end