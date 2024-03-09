function obj = goInterpolation(obj)
test = 0;
test_plot = 0; 

% [fname,pname] = uigetfile('.mat','Select Gcode4Scan File');
% if isempty(fname)||isempty(pname)
%     error('You did not select a file!')
% elseif length(fname)==1&&fname==0 || length(pname)==1&&pname==0
%     error('You did not select a file!')
% end
% if ~exist('obj.Devinfo.inplt')
%     %     c = sqrt(3);
%     obj.Devinfo.inplt = 0.1;
% end
% if isequal(fname,0)
%     disp('none');
% else
%     disp(fullfile(pname,fname));
% end
% str = [pname fname];
% if isempty(str)
%     error('You did not select a file!')
% end
% load(str);
% fid = fopen(str,'r');
% text = fscanf(fid,'%c');
% fclose(fid);
% text(find(text==' '))=[];
%   数据提取
XO=obj.Devinfo.trajectory.start_point(1);
YO=obj.Devinfo.trajectory.start_point(2);
XP=obj.Devinfo.trajectory.start_point(3);       % 打印起始点X，设计时第一段必须过该点
YP=obj.Devinfo.trajectory.start_point(4);       % 打印起始点Y，设计时第一段必须过该点
XA=obj.Devinfo.trajectory.start_point(5);
YA=obj.Devinfo.trajectory.start_point(6);
XS=obj.Devinfo.trajectory.start_point(7);       % 扫描起始点X，设计时第一段必须过该点
YS=obj.Devinfo.trajectory.start_point(8);       % 扫描起始点X，设计时第一段必须过该点
F0=obj.Devinfo.trajectory.feed_rate(1);         % 空行程速率
F1=obj.Devinfo.trajectory.feed_rate(2);         % 打印速率
F2=obj.Devinfo.trajectory.feed_rate(3);         % 扫描速率
LO=obj.Devinfo.trajectory.layer_height;         % 层高
X_Offset=obj.Devinfo.scanner.scanneroffset(1);  % 扫描仪相对于打印机的偏置 X平移   mm
Y_Offset=obj.Devinfo.scanner.scanneroffset(2);  % 扫描仪相对于打印机的偏置 Y平移   mm
Z_Offset=obj.Devinfo.scanner.scanneroffset(3);  % 扫描仪相对于打印机的偏置 Z平移   mm
A_Offset=obj.Devinfo.scanner.scanneroffset(4);  % 扫描仪相对于打印机的偏置 绕X旋转 rad
B_Offset=obj.Devinfo.scanner.scanneroffset(5);  % 扫描仪相对于打印机的偏置 绕Y旋转 rad
C_Offset=obj.Devinfo.scanner.scanneroffset(6);  % 扫描仪相对于打印机的偏置 绕Z旋转 rad
Z_Value=obj.TJ_data.TJ4ZZ;
F_Value=obj.TJ_data.TJ4FF;
Trajectory4Scan = obj.TJ_data.TJ4SC;

XP = [Trajectory4Scan(1,4);Trajectory4Scan(:,6)]+XO;
YP = [Trajectory4Scan(1,5);Trajectory4Scan(:,7)]+YO;
ZP = Z_Value * ones(size(XP));
FP = F_Value * ones(size(XP));
SP = Trajectory4Scan(:,13) ;  % 2022-01-15 之前的定义是分隔符，现在用于判断是否要密化的标志
LP = Trajectory4Scan(:, 2) ;  % 2022-01-15 定位线形状 1：直线 2：圆弧；由于DXF文件的原因，这里添加
% for i =1:length(XP)                             %还没考虑到没写参数的情况
%     x_LJ(i,1) = str2num(text(XP(i)+1:YP(i)-1));
%     y_LJ(i,1) = str2num(text(YP(i)+1:ZP(i)-1));
%     z_LJ(i,1) = str2num(text(ZP(i)+1:FP(i)-1));
%     f_LJ(i,1) = str2num(text(FP(i)+1:SP(i)-1));
% end
x_LJ = XP;
y_LJ = YP;
z_LJ = ZP;
f_LJ = FP;
s_LJ = SP;
l_LJ = LP;
%   首先读取第一个点作为当前点
current_position =[x_LJ(1);y_LJ(1);z_LJ(1)];
current_speed = f_LJ(1);
group_label   = s_LJ(1);
%   初始化输出变量
X_LJ = [];
Y_LJ = [];
Z_LJ = [];
F_LJ = [];
%   2023-02-16 这里需要记录一下加密分组label，用于后续处理
S_LJ = [];
%   从第2个点（第1个线段的终点）开始循环
for i=2:length(XP)
    %   2022-02-16 若d_LJ(i-1)为1，则给group_label+1
    if s_LJ(i-1)==1
        group_label=group_label+1;
    end
    X_LJ =  [X_LJ;current_position(1)];
    Y_LJ =  [Y_LJ;current_position(2)];
    Z_LJ =  [Z_LJ;current_position(3)];
    F_LJ =  [F_LJ;current_speed];
    %   2023-02-16 增加加密分组label
    S_LJ =  [S_LJ;group_label];
    target_positon = [x_LJ(i);y_LJ(i);z_LJ(i)];
    target_speed = f_LJ(i);
    move_vector = target_positon-current_position;
    distance = norm(move_vector);
    move_vector = target_positon-current_position;
    %     if move_vector(1)==0 && move_vector(2)~=0
    %     %仅仅Y向移动时，跳过密化
    %    2022-01-15 若没有密化标志，则不进行加密处理
    if s_LJ(i-1)==0
        %         X_LJ =  [X_LJ;current_position(1)];
        %         Y_LJ =  [Y_LJ;current_position(2)];
        %         Z_LJ =  [Z_LJ;current_position(3)];
        %         F_LJ =  [F_LJ;current_speed];
        %         2022-01-18 若没有标志，则直接跳过，不需要写入终点，否则会引入中间点
        if test_plot
            subplot(1,2,2)
            hold on
            plot(current_position(1),current_position(2),'b.')
            axis equal
            hold off
        end
    else                                                    %其他情况，正常插补
        switch l_LJ(i-1)
            case 1  %   直线密化
                num_Interpo = floor(distance/obj.Devinfo.inplt);
                if rem(distance,obj.Devinfo.inplt)==0
                    num_Interpo=num_Interpo-1;
                end
                for j=1:num_Interpo
                    Interpolation_positon = current_position + j * obj.Devinfo.inplt * (target_positon-current_position)/distance;
                    X_LJ =  [X_LJ;Interpolation_positon(1)];
                    Y_LJ =  [Y_LJ;Interpolation_positon(2)];
                    Z_LJ =  [Z_LJ;Interpolation_positon(3)];
                    F_LJ =  [F_LJ;target_speed];
                    %   2023-02-16 增加加密分组label
                    S_LJ =  [S_LJ;group_label];
                    if test_plot
                        subplot(1,2,2)
                        hold on
                        plot(Interpolation_positon(1),Interpolation_positon(2),'b.')
                        axis equal
                        hold off
                    end
                end
                
            case 2  %   二维圆弧密化
                X_C = Trajectory4Scan(i-1,8);
                Y_C = Trajectory4Scan(i-1,9);
                R_C = Trajectory4Scan(i-1,10);   
                Phi1= Trajectory4Scan(i-1,11);%角度制
                Phi2= Trajectory4Scan(i-1,12);%角度制
                %   按照劣弧计算Phi1到Phi2的方向
                if Phi1 < Phi2
                    if (Phi1>=0) && (Phi1<180)
                        if (Phi2>=Phi1) && (Phi2<Phi1+180)
                            rotate = 1;
                        elseif (Phi2>=Phi1+180) && (Phi2<360)
                            rotate = -1;
                            Phi2 = Phi2 - 360;
                        end
                    elseif (Phi1>=180) && (Phi1<360)
                        if (Phi2>=Phi1) && (Phi2<360)
                            rotate = 1;
                        end
                    end
                elseif Phi1 > Phi2
                    if (Phi1>=0) && (Phi1<180)
                        if (Phi2>=0) && (Phi2<Phi1)
                            rotate = -1;
                        end
                    elseif (Phi1>=180) && (Phi1<360)
                        if (Phi2>=0) && (Phi2<Phi1-180)
                            rotate = 1;
                            Phi2 = Phi2 + 360;
                        elseif (Phi2>=Phi1-180) && (Phi2<Phi1)
                            rotate = -1;
                        end
                    end
                end
                %化为弧度制
                Phi1 = Phi1 * pi / 180; %弧度制
                Phi2 = Phi2 * pi / 180; %弧度制
                distance = R_C * ( Phi2 - Phi1 );
                distance_rem = abs(distance);
                if distance_rem<=obj.Devinfo.inplt
                    %   若剩余的距离太小，则直接跳过
                    %   2022-01-18 若跳过，则不应写入点
                    %                     X_LJ =  [X_LJ;current_position(1)];
                    %                     Y_LJ =  [Y_LJ;current_position(2)];
                    %                     Z_LJ =  [Z_LJ;current_position(3)];
                    %                     F_LJ =  [F_LJ;current_speed];
                else
                    phi_c = obj.Devinfo.inplt*1e3/R_C;                  %这里将phi_C扩大1000倍，减小误差
                    current_phi = Phi1*1e3;            %这里将结果扩大1000倍，减小误差
                    j=1;
                    while distance_rem >= obj.Devinfo.inplt
                        %   简单的计算
                        target_phi = current_phi + rotate * phi_c; %该结果扩大了1000被，以减小误差
                        temp_phi = target_phi * 1e-3;
                        temp_phi = rem(temp_phi,2*pi);
                        target_x   = X_C + R_C * cos(temp_phi);
                        target_y   = Y_C + R_C * sin(temp_phi);
                        target_z   = current_position(3);
                        target_f   = current_speed;
                        %   写入密化点
                        X_LJ =  [X_LJ;target_x];
                        Y_LJ =  [Y_LJ;target_y];
                        Z_LJ =  [Z_LJ;target_z];
                        F_LJ =  [F_LJ;target_f];
                        %   2023-02-16 增加加密分组label
                        S_LJ =  [S_LJ;group_label];
                        %   后处理
                        current_phi = target_phi;
                        distance_rem = R_C * (Phi2*1e3 - current_phi) *1e-3;
                        distance_rem = abs(distance_rem);
                        if test_plot
                            subplot(1,2,1)
                            hold on
                            plot(j,distance_rem,'k.')
                            axis equal
                            hold off
                            subplot(1,2,2)
                            hold on
                            plot(target_x,target_y,'b.')
                            axis equal
                            hold off
                        end
                        j=j+1;
                    end
                end
            otherwise % 其他格式，无法密化，跳过
                %   2022-01-18 跳过时不应该写入点
                %                 X_LJ =  [X_LJ;current_position(1)];
                %                 Y_LJ =  [Y_LJ;current_position(2)];
                %                 Z_LJ =  [Z_LJ;current_position(3)];
                %                 F_LJ =  [F_LJ;current_speed];
                if test_plot
                    subplot(1,2,2)
                    hold on
                    plot(current_position(1),current_position(2),'b.')
                    axis equal
                    hold off
                end
        end
    end
    current_position = target_positon;
    current_speed = target_speed;
end
X_LJ =  [X_LJ;current_position(1)];
Y_LJ =  [Y_LJ;current_position(2)];
Z_LJ =  [Z_LJ;current_position(3)];
F_LJ =  [F_LJ;current_speed];
%   2023-02-16 非加密时，写入0
S_LJ =  [S_LJ;0];
S_LJ(S_LJ==0)=-1;
if test
    subplot(2,1,1)
    plot3(x_LJ,y_LJ,z_LJ,'k.')
    subplot(2,1,2)
    plot3(X_LJ,Y_LJ,Z_LJ,'b.')
    hold on
    gscatter(X_LJ,Y_LJ,S_LJ)
    hold off
end
% 
% for i = 1:length(XP)-1
%     diff_x = x_LJ(i+1,1)-x_LJ(i,1);
%     diff_y = y_LJ(i+1,1)-y_LJ(i,1);
%     diff_z = z_LJ(i+1,1)-z_LJ(i,1);
%     dist = sqrt(diff_x^2 + diff_y^2 + diff_z^2);
%     num_Interpo = floor(dist/c);
%     dir_diff_x = diff_x/dist;
%     dir_diff_y = diff_y/dist;
%     dir_diff_z = diff_z/dist;
%     n = 1;
%     if num_Interpo<=1
%         X_LJ(n,1) =  x_LJ(i,1);
%         Y_LJ(n,1) =  y_LJ(i,1);
%         Z_LJ(n,1) =  z_LJ(i,1);
%         X_LJ(n+1,1) = x_LJ(i,1) + dir_diff_x*j*c;
%         Y_LJ(n+1,1) = y_LJ(i,1) + dir_diff_y*j*c;
%         Z_LJ(n+1,1) = z_LJ(i,1) + dir_diff_z*j*c;
%     else
%         for j = 1:num_Interpo
%         X_LJ(n+j,1) = x_LJ(i,1) + dir_diff_x*j*c;
%         Y_LJ(n+j,1) = y_LJ(i,1) + dir_diff_y*j*c;
%         Z_LJ(n+j,1) = z_LJ(i,1) + dir_diff_z*j*c;
%         end
%         X_LJ(n+num_Interpo+1,1) = x_LJ(i+1,1) ;
%         Y_LJ(n+num_Interpo+1,1) = y_LJ(i+1,1) ;
%         Z_LJ(n+num_Interpo+1,1) = z_LJ(i+1,1);
%         n = n+num_Interpo+2;
%     end
%     
% end
%%  保存数据
obj.TJ_data.TJ4Scan.X_LJ = X_LJ;
obj.TJ_data.TJ4Scan.Y_LJ = Y_LJ;
obj.TJ_data.TJ4Scan.Z_LJ = Z_LJ;
obj.TJ_data.TJ4Scan.F_LJ = F_LJ;
obj.TJ_data.TJ4Scan.S_LJ = S_LJ;
end

