function obj = LS_trajectory_comparison(obj,adjust)
%%  依赖关系判断
if obj.syset.flags.read_flag_sf~=1
    error('tilt correction has not been processed yet!')
end
%%  轨迹对比
%   初始化
if length(adjust)~=6
    error('input error')
else
    adjust = reshape(adjust,6,1);
end
%   计算轨迹变换
if obj.syset.flags.read_flag_tjcomp == 1 % 已经处理过了，需要继续乘变换矩阵
    obj.Surface.traj_comp.trans = trans_matrix(adjust,1) * obj.Surface.traj_comp.trans;
else % 还未处理，需要创建变换矩阵
    obj.Surface.traj_comp.trans = trans_matrix(adjust,1);
    %p2 = Homo_coordi_trans(p1,offset1,offset2,mode)
end
%   计算修正后的轨迹
p1 = obj.TJ_data.TJ4PT(:,6:7);
p1 = [p1,zeros(size(p1,1),1),ones(size(p1,1),1)];
p2 = (obj.Surface.traj_comp.trans*p1')';
obj.Surface.traj_comp.path = p2(:,1:3); 

%%  绘图
h = gca;
try 
    h.Name;
    %   当前有图窗，看下是不是上一次绘制的
    if h.Name ~= 'trajectory_comparison'
        % 不是上次绘制的，读取上一步绘制
        load(obj.LS_plot.surface_fitting);  % 加载上一步绘制的图像句柄（曲面图像）
        h.Name = 'trajectory_comparison'; % 更改图窗名字
    end
catch
    %   当前图窗是新建的，先关了
    close(gcf)
    %   先试试看有没有保存过句柄
    try
        %   直接读取上一次绘制的句柄，尝试一下
        load(obj.LS_plot.trajectory_comparison)
        %   成功的话，需要把上一次绘制的图像删掉
        line_handles = findobj(h, 'Type', 'Line');
        line_handle_to_delete = line_handles(1);
        delete(line_handle_to_delete);
    catch
        %   尝试失败，读取上一步绘制的句柄
        load(obj.LS_plot.surface_fitting);  % 加载上一步绘制的图像句柄（曲面图像）
        h.Name = 'trajectory_comparison'; % 更改图窗名字
    end
end
hold on
plot3(p2(:,1),p2(:,2),p2(:,3),'r-'); %   绘制路径
hold off
title('Trajectory Comparison')
view([0 0 1]) % 俯视图
% 保存绘图句柄
obj.LS_plot.trajectory_comparison = fullfile(obj.syset.path_plotmp,'trajectory_comparison.mat');
save(obj.LS_plot.trajectory_comparison, 'h');
%%  结束与标记
obj.syset.flags.read_flag_tjcomp = 1;
end
% %%  轨迹对比
% if (test_flag==1)||(plot_flag2==1)
%     offset_invalid_flag = 1;    %这个标志位用于判断手调循环的退出
%     mode_selected = 1;          %这个标志位用于判断模式选择的退出
%     finish_flag = 0;
%     %   首先选择模式，读取or手调，如果手调，则读取Gcode代码，然后直接交互式调节，并保存文档；若读取，则直接读取手调保存的文件
%     while mode_selected == 1
%         prompt0 = {'Please select a mode:';'    1 Read from file';'    2 Manual adjust ';   '    Q/q quit'};
%         for i=1:size(prompt0,1)
%             disp(cell2mat(prompt0(i)))
%         end
%         str0 = input(cell2mat(prompt0(1)),'s');
%         %   判断输入是否有效
%         if contains(str0,'Q') || contains(str0,'q') %退出
%             offset_invalid_flag = 0;
%             offset_mode = 0;
%             finish_flag = 0;
%             mode_selected = 0;
%             warning(strcat("Abandon mode selection and exit！"));
%             %   这里提供两种模式：1、手动微调；2、读取已经调整好的数据
%         elseif contains(str0,'1')%读取已经保存的文档
%             [fnamer,pnamer] = uigetfile('.mat','Select Gcode4Scan_adjust.mat File');
%             if isempty(fnamer)||isempty(pnamer)
%                 error('You did not select a file!')
%             elseif length(fnamer)==1&&fnamer==0 || length(pnamer)==1&&pnamer==0
%                 error('You did not select a file!')
%             end
%             strr = [pnamer fnamer];
%             if isempty(strr)
%                 error('You did not select a file!')
%             end
%             load(strr)
%             %   绘图
%             figure(2)
%             subplot(1,2,1)
%             gscatter(LJ_processed_data.grouped_strands(2,:),LJ_processed_data.grouped_strands(3,:),LJ_processed_data.grouped_strands(7,:));
%             hold on
%             plot(PC(:,1),PC(:,2),'b--')
%             plot(PT(:,1),PT(:,2),'b-')
%             hold off
%             title('Trajectory')
%             xlabel('X')
%             ylabel('Y')
%             axis equal
%             %   完成选择后准备退出循环
%             mode_selected = 0;
%         elseif contains(str0,'2')%手动调整并保存文件
%             %   首先读取先前生成的Gcode4Print.mat文件
%             %     [fname,pname] = uigetfile('.mat','Select Gcode4Scan File');
%             %     if isempty(fname)||isempty(pname)||fname==0||pname==0
%             %         error('You did not select a file!')
%             %     end
%             %     str3 = [pname fname];
%             %     load(str3);
%             [fname,pname] = uigetfile('.mat','Select Gcode4Scan File');
%             if isempty(fname)||isempty(pname)
%                 error('You did not select a file!')
%             elseif length(fname)==1&&fname==0 || length(pname)==1&&pname==0
%                 error('You did not select a file!')
%             end
%             str = [pname fname];
%             if isempty(str)
%                 error('You did not select a file!')
%             end
%             [TJ_X,TJ_Y,TJ_Z,TJ_F,TJ_S] = LJ_Interpolation4Traj_V2_0(c,str);
%             Trajectory_X = TJ_X(2:end);
%             Trajectory_Y = TJ_Y(2:end);
%             Trajectory_Z = TJ_Z(2:end);
%             Coordinate_system_1 = [50,50,0,0,0,0];    %格式：该坐标系在世界坐标系下的XYZ坐标、ABC旋转角度。
%             Coordinate_system_2 = [13,130,0,0,0,-90];
%             %   接着先把预先矫正的图像绘制上去再进行手动微调
%             Tt = eye(4);
%             Tti=Tt;
%             t1 = [[rotz(0),-Coordinate_system_1(1:3)'];0,0,0,1];
%             t2 = [[rotz(Coordinate_system_2(6)),[0;0;0]];0,0,0,1];
%             t3 = [[rotz(0),Coordinate_system_2(1:3)'];0,0,0,1];
%             P1 = [Trajectory_X,Trajectory_Y,Trajectory_Z,ones(size(Trajectory_Z))];
%             Tt = t3*t2*t1;
%             Tti= inv(t1)*inv(t2)*inv(t3);
%             P2 = (Tt*P1')';
%             figure(2)
%             subplot(1,2,1)
%             hold on
%             plot(P2(:,1),P2(:,2),'b')
%             hold off
%             %   交互式微调程序
%             PC = P2;
%             disp('Offset Mode List:')
%             spn_list = {1,'Translation';2,'Rotation'};
%             while offset_invalid_flag == 1
%                 for i=1:size(spn_list,1)
%                     disp([num2str(cell2mat(spn_list(i,1))),'  ',cell2mat(spn_list(i,2))])
%                 end
%                 prompt1 = 'Please Select a offset mode(Type Q/q if you want to quit, Y/y if tuning is finish): ';
%                 str1 = input(prompt1,'s');
%                 %   判断输入是否有效
%                 if contains(str1,'Q') || contains(str1,'q') %退出
%                     offset_invalid_flag = 0;
%                     offset_mode = 0;
%                     finish_flag = 0;
%                     warning(strcat("放弃调整！"));
%                 elseif contains(str1,'Y') || contains(str1,'y') %完成调整
%                     offset_invalid_flag = 0;
%                     offset_mode = 0;
%                     finish_flag = 1;
%                     disp(strcat("完成调整！"));
%                     %   完成调整后记得保存文件
%                     strs = [str(1:end-4),'_adjust',str(end-3:end)];
%                     save(strs,'offset_invalid_flag','mode_selected','finish_flag','fname','pname','prompt0','prompt1','prompt2',...
%                         'str','str0','str1','str2','strs','TJ_X','TJ_Y','TJ_Z','TJ_F','TJ_S','Trajectory_X','Trajectory_Y','Trajectory_Z',...
%                         'Coordinate_system_1','Coordinate_system_2','Tt','Tti','t1','t2','t3','t4','t5','t6','t7','P1','P2','PC','PT',...
%                         'spn_list','spn','temp_s2','offset_x','offset_y','offset_z','offset_rx','offset_ry','offset_rr')
%                 else %选择了一个模式
%                     % 判断一下输入的数值是否在序号范围内
%                     spn = str2double(str1);
%                     if isempty(find(cell2mat(spn_list(:,1))==spn)) %不在范围内，警告，并重新输入。
%                         offset_invalid_flag = 1;
%                         offset_mode = 0;
%                         warning(strcat("The offset mode number is incorrect. Please try again!"));
%                         continue
%                     else % 在范围内
%                         % 输入需要调整的数值
%                         offset_mode = spn;
%                         prompt2 = 'Please Input a Select Translation in format x,y (Type Q/q if you want to quit): ';
%                         str2 = input(prompt2,'s');
%                         if contains(str2,'Q') || contains(str2,'q') %退出
%                             offset_invalid_flag = 0;
%                             offset_mode = 0;
%                             warning(strcat("放弃调整！"));
%                             continue
%                         else
%                             temp_s2 = str2num(str2);
%                             if ~isempty(temp_s2)
%                                 switch offset_mode
%                                     case 1 %平移调整
%                                         if ~length(temp_s2)==2
%                                             warning(strcat("Input error, Please retry！"));
%                                             continue
%                                         else
%                                             offset_x = temp_s2(1);
%                                             offset_y = temp_s2(2);
%                                             offset_z = 0;
%                                         end
%                                         t4 = [[rotz(0),[offset_x;offset_y;offset_z]];0,0,0,1];
%                                         Tt = t4*Tt;
%                                         Tti= Tti+inv(t4);
%                                         PT = (t4*PC')';
%                                     case 2 %旋转调整
%                                         if ~length(temp_s2)==3
%                                             warning(strcat("Input error, Please retry！"));
%                                             continue
%                                         else
%                                             offset_rx = temp_s2(1);
%                                             offset_ry = temp_s2(2);
%                                             offset_rr = temp_s2(3);
%                                             if offset_rx==0 && offset_ry==0
%                                                 offset_rx = 0.5*(max(PC(:,1))+min(PC(:,1)));
%                                                 offset_ry = 0.5*(max(PC(:,2))+min(PC(:,2)));
%                                             end
%                                             t5 = [[rotz(0),-[offset_rx;offset_ry;0]];0,0,0,1];
%                                             t6 = [[rotz(offset_rr),[0;0;0]];0,0,0,1];
%                                             t7 = [[rotz(0),[offset_rx;offset_ry;0]];0,0,0,1];
%                                             Tt = t7*t6*t5*Tt;
%                                             Tti= Tti*inv(t5)*inv(t6)*inv(t7);
%                                             PT = (t7*t6*t5*PC')';
%                                         end
%                                     otherwise
%                                         warning(strcat("Input error, Please retry！"));
%                                         continue
%                                 end
%                                 figure(2)
%                                 subplot(1,2,1)
%                                 gscatter(LJ_processed_data.grouped_strands(2,:),LJ_processed_data.grouped_strands(3,:),LJ_processed_data.grouped_strands(7,:));
%                                 hold on
%                                 plot(PC(:,1),PC(:,2),'b--')
%                                 plot(PT(:,1),PT(:,2),'b-')
%                                 hold off
%                                 title('Trajectory')
%                                 xlabel('X')
%                                 ylabel('Y')
%                                 axis equal
%                                 PC = PT;
%                             end
%                         end
%                     end
%                 end
%             end
%             %   完成选择后准备退出循环
%             mode_selected = 0;
%         else %其他情况，这个时候要舍弃
%             mode_selected = 1;
%             warning(strcat("The offset mode number is incorrect. Please try again!"));
%             continue
%         end
%     end
% end
% if finish_flag~=1
%     return
% end