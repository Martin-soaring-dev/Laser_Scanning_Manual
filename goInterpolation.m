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
%   ������ȡ
XO=obj.Devinfo.trajectory.start_point(1);
YO=obj.Devinfo.trajectory.start_point(2);
XP=obj.Devinfo.trajectory.start_point(3);       % ��ӡ��ʼ��X�����ʱ��һ�α�����õ�
YP=obj.Devinfo.trajectory.start_point(4);       % ��ӡ��ʼ��Y�����ʱ��һ�α�����õ�
XA=obj.Devinfo.trajectory.start_point(5);
YA=obj.Devinfo.trajectory.start_point(6);
XS=obj.Devinfo.trajectory.start_point(7);       % ɨ����ʼ��X�����ʱ��һ�α�����õ�
YS=obj.Devinfo.trajectory.start_point(8);       % ɨ����ʼ��X�����ʱ��һ�α�����õ�
F0=obj.Devinfo.trajectory.feed_rate(1);         % ���г�����
F1=obj.Devinfo.trajectory.feed_rate(2);         % ��ӡ����
F2=obj.Devinfo.trajectory.feed_rate(3);         % ɨ������
LO=obj.Devinfo.trajectory.layer_height;         % ���
X_Offset=obj.Devinfo.scanner.scanneroffset(1);  % ɨ��������ڴ�ӡ����ƫ�� Xƽ��   mm
Y_Offset=obj.Devinfo.scanner.scanneroffset(2);  % ɨ��������ڴ�ӡ����ƫ�� Yƽ��   mm
Z_Offset=obj.Devinfo.scanner.scanneroffset(3);  % ɨ��������ڴ�ӡ����ƫ�� Zƽ��   mm
A_Offset=obj.Devinfo.scanner.scanneroffset(4);  % ɨ��������ڴ�ӡ����ƫ�� ��X��ת rad
B_Offset=obj.Devinfo.scanner.scanneroffset(5);  % ɨ��������ڴ�ӡ����ƫ�� ��Y��ת rad
C_Offset=obj.Devinfo.scanner.scanneroffset(6);  % ɨ��������ڴ�ӡ����ƫ�� ��Z��ת rad
Z_Value=obj.TJ_data.TJ4ZZ;
F_Value=obj.TJ_data.TJ4FF;
Trajectory4Scan = obj.TJ_data.TJ4SC;

XP = [Trajectory4Scan(1,4);Trajectory4Scan(:,6)]+XO;
YP = [Trajectory4Scan(1,5);Trajectory4Scan(:,7)]+YO;
ZP = Z_Value * ones(size(XP));
FP = F_Value * ones(size(XP));
SP = Trajectory4Scan(:,13) ;  % 2022-01-15 ֮ǰ�Ķ����Ƿָ��������������ж��Ƿ�Ҫ�ܻ��ı�־
LP = Trajectory4Scan(:, 2) ;  % 2022-01-15 ��λ����״ 1��ֱ�� 2��Բ��������DXF�ļ���ԭ���������
% for i =1:length(XP)                             %��û���ǵ�ûд���������
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
%   ���ȶ�ȡ��һ������Ϊ��ǰ��
current_position =[x_LJ(1);y_LJ(1);z_LJ(1)];
current_speed = f_LJ(1);
group_label   = s_LJ(1);
%   ��ʼ���������
X_LJ = [];
Y_LJ = [];
Z_LJ = [];
F_LJ = [];
%   2023-02-16 ������Ҫ��¼һ�¼��ܷ���label�����ں�������
S_LJ = [];
%   �ӵ�2���㣨��1���߶ε��յ㣩��ʼѭ��
for i=2:length(XP)
    %   2022-02-16 ��d_LJ(i-1)Ϊ1�����group_label+1
    if s_LJ(i-1)==1
        group_label=group_label+1;
    end
    X_LJ =  [X_LJ;current_position(1)];
    Y_LJ =  [Y_LJ;current_position(2)];
    Z_LJ =  [Z_LJ;current_position(3)];
    F_LJ =  [F_LJ;current_speed];
    %   2023-02-16 ���Ӽ��ܷ���label
    S_LJ =  [S_LJ;group_label];
    target_positon = [x_LJ(i);y_LJ(i);z_LJ(i)];
    target_speed = f_LJ(i);
    move_vector = target_positon-current_position;
    distance = norm(move_vector);
    move_vector = target_positon-current_position;
    %     if move_vector(1)==0 && move_vector(2)~=0
    %     %����Y���ƶ�ʱ�������ܻ�
    %    2022-01-15 ��û���ܻ���־���򲻽��м��ܴ���
    if s_LJ(i-1)==0
        %         X_LJ =  [X_LJ;current_position(1)];
        %         Y_LJ =  [Y_LJ;current_position(2)];
        %         Z_LJ =  [Z_LJ;current_position(3)];
        %         F_LJ =  [F_LJ;current_speed];
        %         2022-01-18 ��û�б�־����ֱ������������Ҫд���յ㣬����������м��
        if test_plot
            subplot(1,2,2)
            hold on
            plot(current_position(1),current_position(2),'b.')
            axis equal
            hold off
        end
    else                                                    %��������������岹
        switch l_LJ(i-1)
            case 1  %   ֱ���ܻ�
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
                    %   2023-02-16 ���Ӽ��ܷ���label
                    S_LJ =  [S_LJ;group_label];
                    if test_plot
                        subplot(1,2,2)
                        hold on
                        plot(Interpolation_positon(1),Interpolation_positon(2),'b.')
                        axis equal
                        hold off
                    end
                end
                
            case 2  %   ��άԲ���ܻ�
                X_C = Trajectory4Scan(i-1,8);
                Y_C = Trajectory4Scan(i-1,9);
                R_C = Trajectory4Scan(i-1,10);   
                Phi1= Trajectory4Scan(i-1,11);%�Ƕ���
                Phi2= Trajectory4Scan(i-1,12);%�Ƕ���
                %   �����ӻ�����Phi1��Phi2�ķ���
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
                %��Ϊ������
                Phi1 = Phi1 * pi / 180; %������
                Phi2 = Phi2 * pi / 180; %������
                distance = R_C * ( Phi2 - Phi1 );
                distance_rem = abs(distance);
                if distance_rem<=obj.Devinfo.inplt
                    %   ��ʣ��ľ���̫С����ֱ������
                    %   2022-01-18 ����������Ӧд���
                    %                     X_LJ =  [X_LJ;current_position(1)];
                    %                     Y_LJ =  [Y_LJ;current_position(2)];
                    %                     Z_LJ =  [Z_LJ;current_position(3)];
                    %                     F_LJ =  [F_LJ;current_speed];
                else
                    phi_c = obj.Devinfo.inplt*1e3/R_C;                  %���ｫphi_C����1000������С���
                    current_phi = Phi1*1e3;            %���ｫ�������1000������С���
                    j=1;
                    while distance_rem >= obj.Devinfo.inplt
                        %   �򵥵ļ���
                        target_phi = current_phi + rotate * phi_c; %�ý��������1000�����Լ�С���
                        temp_phi = target_phi * 1e-3;
                        temp_phi = rem(temp_phi,2*pi);
                        target_x   = X_C + R_C * cos(temp_phi);
                        target_y   = Y_C + R_C * sin(temp_phi);
                        target_z   = current_position(3);
                        target_f   = current_speed;
                        %   д���ܻ���
                        X_LJ =  [X_LJ;target_x];
                        Y_LJ =  [Y_LJ;target_y];
                        Z_LJ =  [Z_LJ;target_z];
                        F_LJ =  [F_LJ;target_f];
                        %   2023-02-16 ���Ӽ��ܷ���label
                        S_LJ =  [S_LJ;group_label];
                        %   ����
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
            otherwise % ������ʽ���޷��ܻ�������
                %   2022-01-18 ����ʱ��Ӧ��д���
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
%   2023-02-16 �Ǽ���ʱ��д��0
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
%%  ��������
obj.TJ_data.TJ4Scan.X_LJ = X_LJ;
obj.TJ_data.TJ4Scan.Y_LJ = Y_LJ;
obj.TJ_data.TJ4Scan.Z_LJ = Z_LJ;
obj.TJ_data.TJ4Scan.F_LJ = F_LJ;
obj.TJ_data.TJ4Scan.S_LJ = S_LJ;
end

