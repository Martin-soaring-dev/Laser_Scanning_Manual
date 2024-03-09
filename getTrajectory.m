%%  读取DXF文件的信息，提取路径点，并生成G代码
%   该版本针对五轴3D打印机优化
%   在导出DXF文件时，需要注意所有线条需要是首位相连的，否则无法进行提取
%   为了便于处理，我们定义如下：
%   粗实线层：打印轨迹
%   尺寸线层：气压开启的部分
%   细实线层：扫描轨迹
%   [失效]例子：Print_Trajectory_Read_From_DXF_V2_2();
%   例子：LJ.Trajectory_Extraction_DXF_V2_3_LJ(F0,LO);
%
%   2024-01-26 Martin 将Trajectory_Extraction_DXF_V2_3融入LaserScan类中，方便后续调用
%   1.  将必要的变量保存在LaserScan类中
% function Trajectory_Reed_From_DXF_4Print_Scan(XO,YO,LO,F0,XP,YP,XA,YA,XS,YS,X_Offset,Y_Offset,Z_Offset)
function obj = getTrajectory(obj)
%%  依赖关系判断
if obj.syset.flags.read_flag_dxf~=1
    error('.dxf has not loaded yet, please use obj = loadDXF(obj) to load .dxf file first!')
end
%%  测试参数初始化
test_a = obj.syset.flags.test_flag_tj;
% test_xyf = 1;
% if test_xyf
%     XO=0;
%     YO=0;
%     XP=0;                   %打印起始点X，设计时第一段必须过该点
%     YP=0;                   %打印起始点Y，设计时第一段必须过该点
%     XA=XP;
%     YA=YP;
%     XS=0;                   %扫描起始点X，设计时第一段必须过该点
%     YS=0;                   %扫描起始点X，设计时第一段必须过该点
%     if ~exist('LO')
%         LO=0.6;
%     end
%     if ~exist('F0')
%         F0=300;             %扫描段移动速率 考虑到惯性和丢步降低该数值 曾用值600
%     end
%     F1=1200;                %空行程移动速率 考虑到惯性和丢步降低该数值 曾用值3000
%     X_Offset=0;
%     Y_Offset=0;
%     Z_Offset=0;
% end
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
X_Offset=obj.Devinfo.printer.printeroffset(1);  % 扫描仪相对于打印机的偏置 X平移   mm
Y_Offset=obj.Devinfo.printer.printeroffset(2);  % 扫描仪相对于打印机的偏置 Y平移   mm
Z_Offset=obj.Devinfo.printer.printeroffset(3);  % 扫描仪相对于打印机的偏置 Z平移   mm
A_Offset=obj.Devinfo.printer.printeroffset(4);  % 扫描仪相对于打印机的偏置 绕X旋转 rad
B_Offset=obj.Devinfo.printer.printeroffset(5);  % 扫描仪相对于打印机的偏置 绕Y旋转 rad
C_Offset=obj.Devinfo.printer.printeroffset(6);  % 扫描仪相对于打印机的偏置 绕Z旋转 rad
%%  读取DXF文件
%   2024-01-27 改为 obj = loadDXF(obj) 读取
% [fname,pname] = uigetfile('.dxf','Choose a Path File in .DXF format');
% if isequal(fname,0)
%     disp('none');
% else
%     disp(fullfile(pname,fname));
% end
% str = [pname,'\',fname];
% dxf = DXFtool(str);
% %   2024-01-26 保存dxf到类中
% obj.TJ_data.dxf = dxf;
%%   初始化变量
%   变量格式（每一行）
%   序号      线型          线层                 参数[ x1,  x2,  x3,  x4,   x5,  x6]
%   数字      直线:1        '粗实线层'-打印：1    直线：起X  起Y  终X  终Y   []   []
%             圆弧:2        '尺寸线层'-气压：2    圆弧：心X  心Y  经R  始θ  终θ []
%                           '细实线层'-扫描：3
%                           '中心线层'-密化：4
%   列      定义
%   1       序号
%   2       线型
%   3       图层
%   4       起X
%   5       起Y
%   6       终X
%   7       终Y
%   8       心X
%   9       心Y
%   10      径R
%   11      始θ
%   12      终θ
%   13      执行（气动/加密）标志位
%   第13列在数据处理（“对气压路径操作”、“对加密路径操作”）部分添加
Length = length(obj.TJ_data.dxf.entities);
Trajectory               = zeros(Length,12);
Trajectory4Print         = [];
Trajectory4Airpressure   = [];
Trajectory4Scan          = [];
%%  读取所有线条数据
for i = 1:Length
    Layer = obj.TJ_data.dxf.entities(i).layer;
    switch Layer
        case '粗实线层'
            Layer = 1;
        case '尺寸线层'
            Layer = 2;
        case '细实线层'
            Layer = 3;
        case '中心线层'
            Layer = 4;
        otherwise
            warning(['存在标准格式外的线型：',Layer,'。该线型已忽略，请检查确认'])
            continue
    end

    Name = obj.TJ_data.dxf.entities(i).name;
    switch Name
        case 'LINE'
            Name = 1;
            Temp_P = obj.TJ_data.dxf.entities(i).line;
            Parameters = [Temp_P,NaN,NaN,NaN,NaN,NaN];
        case 'ARC'
            Name = 2;
            Temp_P = obj.TJ_data.dxf.entities(i).arc;
            Parameters = [NaN,NaN,NaN,NaN,Temp_P];
        otherwise
            continue
    end
    Trajectory(i,:) = [i,Name,Layer,Parameters];
end

%   把计算弧线的起止点并赋值
temp = Trajectory(find(Trajectory(:,2)==2),:);
CX = temp(:,8);
CY = temp(:,9);
CR = temp(:,10);
C1 = temp(:,11);
C2 = temp(:,12);
X1 = CX + CR .* cosd(C1);
Y1 = CY + CR .* sind(C1);
X2 = CX + CR .* cosd(C2);
Y2 = CY + CR .* sind(C2);
Trajectory(find(Trajectory(:,2)==2),4:7) = [X1, Y1, X2, Y2];
for i = 4:7
    Trajectory(:,i)=round(Trajectory(:,i)*1e3)*1e-3;
end
%   生成打印、气压、扫描、密化路径
Trajectory4Print         = Trajectory(find(Trajectory(:,3)==1),:);
Trajectory4Airpressure   = Trajectory(find(Trajectory(:,3)==2),:);
Trajectory4Scan          = Trajectory(find(Trajectory(:,3)==3),:);
Trajectory4Interpolation = Trajectory(find(Trajectory(:,3)==4),:);
%%  找到首尾相连的向量，并重新排序
%   2022-01-14 更新
%   这里首先分别将打印、气压、扫描、密化的路径重新排序
%   然后结合打印、气压路径生成打印G代码
%   接着结合扫描、密化的路径生成扫描路径矩阵，并把矩阵（工作区变量）保存到指定的路径下，
%   便于后续读取和操作。
%       数据格式：
%               参数[ x1,  x2,  x3,  x4,   x5,  x6,  x7]
%               直线：起X  起Y  终X  终Y   []   []   密化标识
%               圆弧：心X  心Y  经R  始θ  终θ []   密化标识
%
%   需要指出的是，打印路径、扫描路径需要是连续的。
%   而气压、密化的路径存在以下情况：
%   和打印/扫描路径：首尾相连、单端相连、在路径上但是没有端点重合
%       因此需要做相应的逻辑判断：
%           以打印为例：
%               在打印路径层， 通过起始点A找到该线段L1，并查找终止点B；
%               在气压路径层， 查找起点、终点到线段AB距离为零的线段L2；
%                             查找L2上距离A点最近的端点C，和较远点D；
%               switch [A==C D==B]
%                   case [0 0]
%                       写入：
%                       起点      终点      气压工作标识
%                       A         C         0
%                       C         D         1
%                       D         B         0
%                   case [0 1]
%                       写入：
%                       起点      终点      气压工作标识
%                       A         C         0
%                       C         B         1
%                   case [1 0]
%                       起点      终点      气压工作标识
%                       A         D         1
%                       D         B         0
%                   case [0 0]
%                       起点      终点      气压工作标识
%                       A         B         1
%               end
%%   对打印路径操作
%   2022-01-14 更新
%   这里进行了重写，从而实现新的工作流程，带标识的起止点数据→G代码
%   需要做相应的逻辑判断：
%           以打印为例：
%               在打印路径层， 通过起始点A找到该线段L1，并查找终止点B；
%               在气压路径层， 查找起点、终点到线段AB距离为零的线段L2；
%                             查找L2上距离A点最近的端点C，和较远点D；
%               switch [A==C D==B]
%                   case [0 0]
%                       起点      终点      气压工作标识
%                       A         C         0
%                       C         D         1
%                       D         B         0
%                   case [0 1]
%                       起点      终点      气压工作标识
%                       A         C         0
%                       C         B         1
%                   case [1 0]
%                       起点      终点      气压工作标识
%                       A         D         1
%                       D         B         0
%                   case [0 0]
%                       起点      终点      气压工作标识
%                       A         B         1
%               end
%   将打印路径赋值给临时变量，后面仅仅对变量TEMP_Trajectory进行操作，从而避免对源数据操作造成数据丢失
TEMP_Trajectory = Trajectory4Print;
%   将第一列（序号）先全部置为0，后面再重新赋值
TEMP_Trajectory(:,1)=0;
%   按照设定的起始点（默认为[0,0]）查找第一个线段
temp0 = find((TEMP_Trajectory(:,4)==XP) & (TEMP_Trajectory(:,5)==YP));
%   将第一个线段的序号置为1
TEMP_Trajectory(temp0,1)=1;
%   将第一个线段的终点坐标赋值给临时变量，用于查找第二个线段，并开始循环
X2_TEMP = TEMP_Trajectory(temp0,6);
Y2_TEMP = TEMP_Trajectory(temp0,7);
for i = 2:length(TEMP_Trajectory(:,1))
    %   查找端点含有上个线段终点的线段
    temp = find((TEMP_Trajectory(:,4)==X2_TEMP) & (TEMP_Trajectory(:,5)==Y2_TEMP));
    if isempty(temp)
        %   若查不到，可能是因为绘图时，线条方向反了，按照终止点来查找
        tempr = find((TEMP_Trajectory(:,6)==X2_TEMP) & (TEMP_Trajectory(:,7)==Y2_TEMP));
        %   这时，需要注意，需要排除第一个线段的终止点
        tempr(find(tempr==temp0))=[];
        if isempty(tempr)
            error('无法找到下一点！')
        else
            %   接下来需要把该线段的起止点对调，但是需要判断其线型
            %             for j=1:length(tempr)
            %   如果找到了多个符合条件的线段，首先应循环执行，
            %   每次读取第一个，如果不符合需要就把数据删了，如果复合需要就停止处理
            %   把第一个数据对应的线型读取出来
            %   2022-01-14 更新
            %   这里修改了逻辑，应该是先对每一个数据进行操作，如果复合条件，处理；不符合条件，线型置为0
            %   处理完了，再把线型为0的，全部删除；
            %   在这之后，如果还剩多组数据，只取第一个
            %                 flag_line_type = TEMP_Trajectory(tempr(1),2);
            %   首先把不符合规定线型的数据删除
            for j=1:length(tempr)
                flag_line_type = TEMP_Trajectory(tempr(j),2);
                %   读取线型，并将非规定种类线型置为0
                switch flag_line_type
                    case 1  %   直线，不操作
                    case 2  %   圆弧，不操作
                    otherwise % 其他，置为0
                        flag_line_type(j)=0;
                end
                temp(find(flag_line_type==0))=[];
                %   将对应的数据删除
            end

            %   删除后判断一下还有没有剩余的点，如果没有则报错
            if isempty(tempr)
                error('无法找到下一点！')
            end

            %   如果剩下了数据，先判断是否有多组，如果有多组，则只取第一个，并警告
            if length(tempr)>1
                warning(['查找到多个线段，只取首个符合条件的！'])
                tempr = tempr(1);
            end

            %   然后将改组数据进行起止点对调
            flag_line_type = TEMP_Trajectory(tempr,2);
            switch flag_line_type
                case 1  %   直线，
                    %                         tempr(1)=tempr;
                    temp1 = TEMP_Trajectory(tempr,4);
                    temp2 = TEMP_Trajectory(tempr,5);
                    TEMP_Trajectory(tempr,4) = TEMP_Trajectory(tempr,6);
                    TEMP_Trajectory(tempr,5) = TEMP_Trajectory(tempr,7);
                    TEMP_Trajectory(tempr,6) = temp1;
                    TEMP_Trajectory(tempr,7) = temp2;
                case 2  %   圆弧
                    %                         tempr(1)=tempr;
                    %   2022-01-14 更新
                    %   之前写的不对，修正了一下
                    %                     tempr=tempr(1);
                    temp1 = TEMP_Trajectory(tempr,4);
                    temp2 = TEMP_Trajectory(tempr,5);
                    TEMP_Trajectory(tempr,4) = TEMP_Trajectory(tempr,6);
                    TEMP_Trajectory(tempr,5) = TEMP_Trajectory(tempr,7);
                    TEMP_Trajectory(tempr,6) = temp1;
                    TEMP_Trajectory(tempr,7) = temp2;
                    temp3 = TEMP_Trajectory(tempr,11);
                    TEMP_Trajectory(tempr,11) = TEMP_Trajectory(tempr,12);
                    TEMP_Trajectory(tempr,12) = temp3;
            end

            %   处理完了之后，把tempr重新赋值给temp，完成线段颠倒的处置
            temp = tempr;
            %             end
        end
    else
        %   temp非空时，需要排除一下线型错误的影响
        flag_line_type = TEMP_Trajectory(temp,2);
        for j=1:length(temp)
            flag_line_type = TEMP_Trajectory(temp(j),2);
            %   读取线型，并将非规定种类线型置为0
            switch flag_line_type
                case 1  %   直线，不操作
                case 2  %   圆弧，不操作
                otherwise % 其他，置为0
                    flag_line_type(j)=0;
            end
        end
        temp(find(flag_line_type==0))=[];
        %   将对应的数据删除
        %   此时，如果不止一个temp，需要发出警告，并且只取首个temp
        if length(temp)>1
            warning(['查找到多个线段，只取首个符合条件的！'])
            temp = temp(1);
        end
    end
    TEMP_Trajectory(temp,1)=i;
    X2_TEMP = TEMP_Trajectory(temp,6);
    Y2_TEMP = TEMP_Trajectory(temp,7);
    if test_a
        disp(i)
    end
    temp0 = temp;
end
[~,pos] = sort(TEMP_Trajectory(:,1));
Trajectory4Print = TEMP_Trajectory( pos , :);
%%   对气压路径操作
% TEMP_Trajectory = Trajectory4Airpressure;
% TEMP_Trajectory(:,1)=0;
% temp0 = find((TEMP_Trajectory(:,4)==XA) & (TEMP_Trajectory(:,5)==YA));
% TEMP_Trajectory(temp0,1)=1;
% X2_TEMP = TEMP_Trajectory(temp0,6);
% Y2_TEMP = TEMP_Trajectory(temp0,7);
% for i = 2:length(TEMP_Trajectory(:,1))
%     temp = find((TEMP_Trajectory(:,4)==X2_TEMP) & (TEMP_Trajectory(:,5)==Y2_TEMP));
%     if isempty(temp)
%         tempr = find((TEMP_Trajectory(:,6)==X2_TEMP) & (TEMP_Trajectory(:,7)==Y2_TEMP));
%         tempr(find(tempr==temp0))=[];
%         if isempty(tempr)
%             error('无法找到下一点！')
%         else
%             for j=1:length(tempr)
%                 flag_line_type = TEMP_Trajectory(tempr(1),2);
%                 switch flag_line_type
%                     case 1
%                         tempr(1)=tempr;
%                         temp1 = TEMP_Trajectory(tempr,4);
%                         temp2 = TEMP_Trajectory(tempr,5);
%                         TEMP_Trajectory(tempr,4) = TEMP_Trajectory(tempr,6);
%                         TEMP_Trajectory(tempr,5) = TEMP_Trajectory(tempr,7);
%                         TEMP_Trajectory(tempr,6) = temp1;
%                         TEMP_Trajectory(tempr,7) = temp2;
%                     case 2
%                         tempr(1)=tempr;
%                         temp1 = TEMP_Trajectory(tempr,4);
%                         temp2 = TEMP_Trajectory(tempr,5);
%                         TEMP_Trajectory(tempr,4) = TEMP_Trajectory(tempr,6);
%                         TEMP_Trajectory(tempr,5) = TEMP_Trajectory(tempr,7);
%                         TEMP_Trajectory(tempr,6) = temp1;
%                         TEMP_Trajectory(tempr,7) = temp2;
%                         temp3 = TEMP_Trajectory(tempr,11);
%                         TEMP_Trajectory(tempr,11) = TEMP_Trajectory(tempr,12);
%                         TEMP_Trajectory(tempr,12) = temp3;
%                     otherwise
%                         tempr(j)=[];
%                 end
%                 if isempty(tempr)
%                     error('无法找到下一点！')
%                 else
%                     temp=tempr;
%                 end
%             end
%         end
%     end
%     TEMP_Trajectory(temp,1)=i;
%     X2_TEMP = TEMP_Trajectory(temp,6);
%     Y2_TEMP = TEMP_Trajectory(temp,7);
%     if test_a
%         disp(i)
%     end
%     temp0 = temp;
% end
% [b,pos] = sort(TEMP_Trajectory(:,1));
% Trajectory4Airpressure = TEMP_Trajectory( pos , :);
%   2022-01-14 更新
%               在打印路径层， 通过起始点A找到该线段L1，并查找终止点B；
%               在气压路径层， 查找起点、终点到线段AB距离为零的线段L2；
%                             查找L2上距离A点最近的端点C，和较远点D；
%               switch [A==C D==B]
%                   case [0 0]
%                       起点      终点      气压工作标识
%                       A         C         0
%                       C         D         1
%                       D         B         0
%                   case [0 1]
%                       起点      终点      气压工作标识
%                       A         C         0
%                       C         B         1
%                   case [1 0]
%                       起点      终点      气压工作标识
%                       A         D         1
%                       D         B         0
%                   case [0 0]
%                       起点      终点      气压工作标识
%                       A         B         1
%               end
%   新的思路是对打印路径进行读取，判断是否需要在线段中插入气压工作的行
%   将气压路径赋值给临时变量，后面仅仅对变量TEMP_Execution, TEMP_Trajectory进行操作，从而避免对源数据操作造成数据丢失
TEMP_Execution  = Trajectory4Airpressure;
TEMP_Trajectory = [Trajectory4Print,zeros(size(Trajectory4Print,1),1)];%在Trajectory4Print后添加一列标志位，全部为0
%   对TEMP_Trajectory遍历，寻找重合的TEMP_Execution段，并插入到TEMP_Trajectory中
L = size(TEMP_Trajectory,1);
for i = 1:L
    %   由于循环中会插入行，需要按照第一列（序号）来查找对应的行
    temp_Current_Tra = find(TEMP_Trajectory(:,1)==i);
    switch TEMP_Trajectory(temp_Current_Tra,2)
        case 1  %   直线，需要判断：①初筛的线段线型是否一致，②起止点是否位于AB上即可
            %   按照起止点圈定的范围寻找线段初筛，再通过线型判断、重合判断精筛出与当前线段重合的线段。
            %Step1：范围筛选
            %   获取当前行的起始点A和终止点B
            X_A_TEMP = TEMP_Trajectory(temp_Current_Tra,4);
            Y_A_TEMP = TEMP_Trajectory(temp_Current_Tra,5);
            X_B_TEMP = TEMP_Trajectory(temp_Current_Tra,6);
            Y_B_TEMP = TEMP_Trajectory(temp_Current_Tra,7);
            %   在TEMP_Execution中查找在AB构成的矩形区域内的线段
            X_MIN_TEMP1 = min([X_A_TEMP, X_B_TEMP]);
            Y_MIN_TEMP1 = min([Y_A_TEMP, Y_B_TEMP]);
            X_MAX_TEMP1 = max([X_A_TEMP, X_B_TEMP]);
            Y_MAX_TEMP1 = max([Y_A_TEMP, Y_B_TEMP]);
            X_MIN_TEMP2 = min([TEMP_Execution(:,4), TEMP_Execution(:,6)],[],2);
            Y_MIN_TEMP2 = min([TEMP_Execution(:,5), TEMP_Execution(:,7)],[],2);
            X_MAX_TEMP2 = max([TEMP_Execution(:,4), TEMP_Execution(:,6)],[],2);
            Y_MAX_TEMP2 = max([TEMP_Execution(:,5), TEMP_Execution(:,7)],[],2);
            temp0 = find(   round((X_MIN_TEMP1-X_MIN_TEMP2)*1e3)<=0&...
                            round((Y_MIN_TEMP1-Y_MIN_TEMP2)*1e3)<=0&...
                            round((X_MAX_TEMP1-X_MAX_TEMP2)*1e3)>=0&...
                            round((Y_MAX_TEMP1-Y_MAX_TEMP2)*1e3)>=0      );
            %   若在圈定范围内找不到，跳到下个线段
            if isempty(temp0)
                continue
            end
            %Step2：线型筛选
            %   查找线型为直线的线段
            temp0 = temp0(find(TEMP_Execution(temp0,2)==1));
            %   若在找不到，跳到下个线段
            if isempty(temp0)
                continue
            end
            %Step3：几何关系筛选
            %   判断查找到的线段的端点是否在当前线段上
            %       读取所有的起止点
            X_C_TEMP = TEMP_Execution(temp0,4);
            Y_C_TEMP = TEMP_Execution(temp0,5);
            X_D_TEMP = TEMP_Execution(temp0,6);
            Y_D_TEMP = TEMP_Execution(temp0,7);
            vector_AB = [X_B_TEMP-X_A_TEMP, Y_B_TEMP-Y_A_TEMP];
            vector_AC = [X_C_TEMP-X_A_TEMP, Y_C_TEMP-Y_A_TEMP];
            vector_AD = [X_D_TEMP-X_A_TEMP, Y_D_TEMP-Y_A_TEMP];
            for j = 1:length(temp0)
                distance_AC = round(norm(vector_AC(j,:))*1e3);
                distance_AD = round(norm(vector_AD(j,:))*1e3);
                complex_AB = complex(vector_AB(1),vector_AB(2));
                complex_AC = complex(vector_AC(j,1),vector_AC(j,2));
                complex_AD = complex(vector_AD(j,1),vector_AD(j,2));
                angle_AB = angle(complex_AB)*180/pi;
                if distance_AC==0
                    angle_AC = angle_AB;
                else
                    angle_AC = angle(complex_AC)*180/pi;
                end
                if distance_AD==0
                    angle_AD = angle_AB;
                else
                    angle_AD = angle(complex_AD)*180/pi;
                end
                error1 = round(angle_AB*1e2-angle_AC*1e2);
                error2 = round(angle_AB*1e2-angle_AD*1e2);
                if (error1~=0)||(error2~=0)
                    temp0(j)=0;
                end
            end
            temp0(find(temp0==0))=[];
            %   若在找不到，跳到下个线段
            if isempty(temp0)
                continue
            else
                %   若筛选出重合的线段，则判断temp0元素数量，若大于1则警告并只取第一个
                if length(temp0)>1
                    warning('存在重合线段，只取第一个重合点')
                    temp0=temp0(1);
                end
            end

            %Step4：调整
            X_C_TEMP = TEMP_Execution(temp0,4);
            Y_C_TEMP = TEMP_Execution(temp0,5);
            X_D_TEMP = TEMP_Execution(temp0,6);
            Y_D_TEMP = TEMP_Execution(temp0,7);
            distance_AB = norm([X_B_TEMP-X_A_TEMP, Y_B_TEMP-Y_A_TEMP]);
            distance_AC = norm([X_C_TEMP-X_A_TEMP, Y_C_TEMP-Y_A_TEMP]);
            distance_AD = norm([X_D_TEMP-X_A_TEMP, Y_D_TEMP-Y_A_TEMP]);
            flag_CeqD = round(distance_AC*1e3 - distance_AD*1e3)==0;
            flag_CecD = round(distance_AC*1e3 - distance_AD*1e3)>0;
            flag_AeqC = round(distance_AC*1e3)~=0;
            flag_BeqD = round(distance_AB*1e3 - distance_AD*1e3)~=0;
            %   若CD长度等于0，跳到下个线段
            if flag_CeqD
                continue
            end
            %   若CD需要对调，则进行对调
            if flag_CecD
                %   首先进行对调
                temp1 = TEMP_Execution(temp0,4);
                temp2 = TEMP_Execution(temp0,5);
                TEMP_Execution(temp0,4) = TEMP_Execution(temp0,6);
                TEMP_Execution(temp0,5) = TEMP_Execution(temp0,7);
                TEMP_Execution(temp0,6) = temp1;
                TEMP_Execution(temp0,7) = temp2;
                %   接着重新计算相关变量
                X_C_TEMP = TEMP_Execution(temp0,4);
                Y_C_TEMP = TEMP_Execution(temp0,5);
                X_D_TEMP = TEMP_Execution(temp0,6);
                Y_D_TEMP = TEMP_Execution(temp0,7);
                distance_AB = norm([X_B_TEMP-X_A_TEMP, Y_B_TEMP-Y_A_TEMP]);
                distance_AC = norm([X_C_TEMP-X_A_TEMP, Y_C_TEMP-Y_A_TEMP]);
                distance_AD = norm([X_D_TEMP-X_A_TEMP, Y_D_TEMP-Y_A_TEMP]);
                flag_AeqC = round(distance_AC*1e3)~=0;
                flag_BeqD = round(distance_AB*1e3 - distance_AD*1e3)~=0;
            end

            %Step5：插入
            %               switch [A==C D==B]
            %                   case [1 1]
            %                       起点      终点      气压工作标识
            %                       A         C         0
            %                       C         D         1
            %                       D         B         0
            %                   case [0 1]
            %                       起点      终点      气压工作标识
            %                       A         C         0
            %                       C         B         1
            %                   case [1 0]
            %                       起点      终点      气压工作标识
            %                       A         D         1
            %                       D         B         0
            %                   case [0 0]
            %                       起点      终点      气压工作标识
            %                       A         B         1
            %               end
            if flag_BeqD==1
                if flag_AeqC==1
                flag = 1;
                else
                    flag = 2;
                end
            else
                if flag_AeqC==1
                    flag = 3;
                else
                    flag = 4;
                end
            end
            switch flag
                case 1 %[1,1]
                    %   建立临时变量
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp5 = [TEMP_Execution(temp0,:),0];
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   序号为i的行行终点改为C
                    temp3(end,6) = X_C_TEMP;
                    temp3(end,7) = Y_C_TEMP;
                    %   添加的段，并把执行标志位置为1
                    temp5(1,13)= 1;
                    temp5(1, 1)= 0;
                    %   提取原先序号为i的行起始点改为D，并写到插入点后
                    temp6(1,4) = X_D_TEMP;
                    temp6(1,5) = Y_D_TEMP;
                    temp6(1,1) = 0;
                    %   把截取的后面的数据粘结上，并赋值给TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp5;temp6;temp4];
                case 2 %[0,1]
                    %   建立临时变量
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   序号为i的行行终点改为C
                    temp3(end,6) = X_D_TEMP;
                    temp3(end,7) = Y_D_TEMP;
                    temp3(end,13)= 1;
                    %   提取原先序号为i的行起始点改为C，并把执行标志位置为1，并写到插入点后
                    temp6(1,4) = X_D_TEMP;
                    temp6(1,5) = Y_D_TEMP;
                    temp6(1,1) = 0;
                    temp6(1,13)= 0;
                    %   把截取的后面的数据粘结上，并赋值给TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp6;temp4];
                case 3 %[1,0]
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   序号为i的行行终点改为C
                    temp3(end,6) = X_C_TEMP;
                    temp3(end,7) = Y_C_TEMP;
                    temp3(end,13)= 0;
                    %   提取原先序号为i的行起始点改为D，并写到插入点后
                    temp6(1,4) = X_C_TEMP;
                    temp6(1,5) = Y_C_TEMP;
                    temp6(1,1) = 0;
                    temp6(1,13)= 1;
                    %   把截取的后面的数据粘结上，并赋值给TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp6;temp4];
                case 4 %[0,0]
                    %   建立临时变量
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    %   序号为i的行把执行标志位置为1
                    temp3(end,13) = 1;
                    %   把截取的后面的数据粘结上，并赋值给TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp4];
            end
        case 2  %   圆弧，需要判断：①线型、圆心坐标R及半径是否一致，②起止角度是否在范围内
            %   首先通过线型、圆心位置、半径进行初筛；再通过圆弧角度范围进行精筛。
            %Step1：线型筛选
            temp0 = find(TEMP_Execution(:,2)==2);
            %   若在找不到，跳到下个线段
            if isempty(temp0)
                continue
            end

            %Step2：圆心位置筛选
            %   获取当前圆弧的圆心A、半径R、起止角度
            X_A_TEMP = TEMP_Trajectory(temp_Current_Tra,8);
            Y_A_TEMP = TEMP_Trajectory(temp_Current_Tra,9);
            R_A_TEMP = TEMP_Trajectory(temp_Current_Tra,10);
            PhiATEMP = TEMP_Trajectory(temp_Current_Tra,11);
            PhiBTEMP = TEMP_Trajectory(temp_Current_Tra,12);
            %   在TEMP_Execution中查找圆心在A点的圆弧
            X_B_TEMP = TEMP_Execution(temp0,8);
            Y_B_TEMP = TEMP_Execution(temp0,9);
            vector_A = [X_B_TEMP-X_A_TEMP, Y_B_TEMP-Y_A_TEMP];
            for j = 1:length(temp0)
                distance_AB = round(norm(vector_A(j,:))*1e3);
                if distance_AB~=0
                    temp0(j)=0;
                end
            end
            temp0(find(temp0==0))=[];
            %   若在找不到，跳到下个线段
            if isempty(temp0)
                continue
            end

            %Step3：按半径筛选
            R_B_TEMP = TEMP_Execution(temp0,10);
            error1 = round((R_B_TEMP-R_A_TEMP)*1e3);
            temp0 = temp0(find(error1==0));
            %   若在找不到，跳到下个线段
            if isempty(temp0)
                continue
            end

%             %Step4：按角度范围筛选
%             %   需要注意一个问题，角度是否过零点！
%             %   问题可以简化为角度不超过180°的短弧是所需的圆弧
%             %   因此，首先需要确定角度的表示问题。
% %             %   正方向为逆时针方向
% %             if PhiATEMP<PhiBTEMP
% %                 DeltaPhi = PhiBTEMP - PhiATEMP;
% %                 if abs(DeltaPhi)<180
% %                     %   PhiB > PhiA，正方向为劣弧：无需处理
% %                 elseif abs(deltaPhi>180
% %                     %   PhiB > PhiA，逆方向为劣弧：PhiB-360°
% %                     PhiBTEMP = PhiBTEMP - 360;
% %                 else
% %                     error('存在180°圆弧，无法计算！')
% %                 end
% %             elseif PhiATEMP>PhiBTEMP
% %                 DeltaPhi = PhiBTEMP - PhiATEMP;
% %                 if abs(DeltaPhi)<180
% %                     %   PhiB > PhiA，逆方向为劣弧：无需处理
% %                 elseif abs(deltaPhi>180
% %                     %   PhiB < PhiA，正方向为劣弧：PhiA+360°
% %                     PhiATEMP = PhiATEMP - 360;
% %                 else
% %                     error('存在180°圆弧，无法计算！')
% %                 end
% %             else 
% %                 continue
% %             end
%             PhiCTEMP = TEMP_Execution(temp0,11);
%             PhiDTEMP = TEMP_Execution(temp0,12);
%             Phi_MIN_TEMP1 = min([PhiATEMP,PhiBTEMP]);
%             Phi_MAX_TEMP1 = max([PhiATEMP,PhiBTEMP]);
%             Phi_MIN_TEMP2 = min([PhiCTEMP,PhiDTEMP],[],2);
%             Phi_MAX_TEMP2 = max([PhiCTEMP,PhiDTEMP],[],2);
%             temp0(find(     round((Phi_MIN_TEMP1-Phi_MIN_TEMP2)*1e3)>0&...
%                             round((Phi_MAX_TEMP1-Phi_MAX_TEMP2)*1e3)<0      ))...
%                             =[];
%             %   若在角度不在PhiA，PhiB范围内找不到，跳到下个线段
%             if isempty(temp0)
%                 continue
%             end

            %Step5：范围判断与调整
            PhiCTEMP = TEMP_Execution(temp0,11);
            PhiDTEMP = TEMP_Execution(temp0,12);
            ArcAB = PhiBTEMP-PhiATEMP;
            ArcAC = PhiCTEMP-PhiATEMP;
            ArcAD = PhiDTEMP-PhiATEMP;
            if ArcAB == 0
                continue
            end
            %范围判断
            %   有点复杂，正方向为逆时针
            %   PhiA<PhiB时
            %       PhiA在 (0,180)时
            %           PhiB 在 (PhiA,PhiA+180)时，A向B正方向区间(PhiA,PhiB)
            %           PhiB 在 (PhiA+180,360 )时，A向B逆方向区间(PhiB,360)|(0,PhiA)
            %       PhiA在 (180，360)时
            %           PhiB 在 (PhiA,360)     时，A向B正方向区间(PhiA,PhiB)
            %   PhiA>PhiB时
            %       PhiA在 (0,180)时
            %           PhiB 在 (0,PhiA)       时，A向B逆方向区间(PhiB,PhiA)
            %       PhiA在 (180，360)时
            %           PhiB 在 (0,PhiA-180)   时，A向B正方向区间(PhiA,360)|(0,PhiB)
            %           PhiB 在 (PhiA-180,PhiA)时，A向B逆方向区间(PhiB,PhiA)
            for j = 1:length(temp0)
                PhiCTEMP = TEMP_Execution(temp0(j),11);
                PhiDTEMP = TEMP_Execution(temp0(j),12);
                if PhiATEMP < PhiBTEMP
                    if (PhiATEMP>=0) && (PhiATEMP<180)
                        if (PhiBTEMP>=PhiATEMP) && (PhiBTEMP<PhiATEMP+180)
                            flag_C = (PhiCTEMP>=PhiATEMP)&&(PhiCTEMP<=PhiBTEMP);
                            flag_D = (PhiDTEMP>=PhiATEMP)&&(PhiDTEMP<=PhiBTEMP);
                            rotate = 1;
                        elseif (PhiBTEMP>=PhiATEMP+180) && (PhiBTEMP<360)
                            flag_C = ((PhiCTEMP>=0)&&(PhiCTEMP<=PhiATEMP))||...
                                     ((PhiCTEMP>=PhiBTEMP)&&(PhiCTEMP<360));
                            flag_D = ((PhiDTEMP>=0)&&(PhiDTEMP<=PhiATEMP))||...
                                     ((PhiDTEMP>=PhiBTEMP)&&(PhiDTEMP<360));
                            rotate = -1;
                        end
                    elseif (PhiATEMP>=180) && (PhiATEMP<360)
                        if (PhiBTEMP>=PhiATEMP) && (PhiBTEMP<360)
                            flag_C = (PhiCTEMP>=PhiATEMP)&&(PhiCTEMP<=PhiBTEMP);
                            flag_D = (PhiDTEMP>=PhiATEMP)&&(PhiDTEMP<=PhiBTEMP);
                            rotate = 1;
                        end
                    end
                elseif PhiATEMP > PhiBTEMP
                    if (PhiATEMP>=0) && (PhiATEMP<180)
                        if (PhiBTEMP>=0) && (PhiBTEMP<PhiATEMP)
                            flag_C = (PhiCTEMP>=PhiBTEMP)&&(PhiCTEMP<=PhiATEMP);
                            flag_D = (PhiDTEMP>PhiBTEMP)&&(PhiDTEMP<=PhiATEMP);
                            rotate = -1;
                        end
                    elseif (PhiATEMP>=180) && (PhiATEMP<360)
                        if (PhiBTEMP>=0) && (PhiBTEMP<PhiATEMP-180)
                            flag_C = ((PhiCTEMP>=PhiATEMP)&&(PhiCTEMP<360))||...
                                     ((PhiCTEMP>=0)&&(PhiCTEMP<=PhiBTEMP));
                            flag_D = ((PhiDTEMP>=PhiATEMP)&&(PhiDTEMP<360))||...
                                     ((PhiDTEMP>=0)&&(PhiDTEMP<=PhiBTEMP));
                            rotate = 1;
                        elseif (PhiBTEMP>=PhiATEMP-180) && (PhiBTEMP<PhiATEMP)
                            flag_C = (PhiCTEMP>=PhiBTEMP)&&(PhiCTEMP<=PhiATEMP);
                            flag_D = (PhiDTEMP>=PhiBTEMP)&&(PhiDTEMP<=PhiATEMP);
                            rotate = -1;
                        end
                    end
                end
                %若存在不在范围内的点，则置零
                if (flag_C==0)||(flag_D==0)
                    temp(j)=0;                    
                end
            end
            temp0(find(temp0==0));
            %   若在找不到，跳到下个线段
            if isempty(temp0)
                continue
            end
            %调整
            for j = 1:length(temp0)
                PhiCTEMP = TEMP_Execution(temp0(j),11);
                PhiDTEMP = TEMP_Execution(temp0(j),12);
                if PhiATEMP < PhiBTEMP
                    if (PhiATEMP>=0) && (PhiATEMP<180)
                        if (PhiBTEMP>=PhiATEMP) && (PhiBTEMP<PhiATEMP+180)
                            rotate = 1;
                            flag_CecD = rotate * sign(PhiDTEMP - PhiCTEMP);
                        elseif (PhiBTEMP>=PhiATEMP+180) && (PhiBTEMP<360)
                            if (PhiCTEMP>=0)&&(PhiCTEMP<=PhiATEMP)
                                %无需操作
                            elseif (PhiCTEMP>=PhiBTEMP)&&(PhiCTEMP<360)
                                PhiCTEMP = PhiCTEMP-360;
                            end
                            if (PhiDTEMP>=0)&&(PhiDTEMP<=PhiATEMP)
                                %无需操作
                            elseif (PhiDTEMP>=PhiBTEMP)&&(PhiDTEMP<360)
                                PhiCTEMP = PhiCTEMP-360;
                            end
                            rotate = -1;
                            flag_CecD = rotate * sign(PhiDTEMP - PhiCTEMP);
                        end
                    elseif (PhiATEMP>=180) && (PhiATEMP<360)
                        if (PhiBTEMP>=PhiATEMP) && (PhiBTEMP<360)
                            rotate = 1;
                            flag_CecD = rotate * sign(PhiDTEMP - PhiCTEMP);
                        end
                    end
                elseif PhiATEMP > PhiBTEMP
                    if (PhiATEMP>=0) && (PhiATEMP<180)
                        if (PhiBTEMP>=0) && (PhiBTEMP<PhiATEMP)
                            rotate = -1;
                            flag_CecD = rotate * sign(PhiDTEMP - PhiCTEMP);
                        end
                    elseif (PhiATEMP>=180) && (PhiATEMP<360)
                        if (PhiBTEMP>=0) && (PhiBTEMP<PhiATEMP-180)
                            if (PhiCTEMP>=PhiATEMP)&&(PhiCTEMP<360)
                                %无需操作
                            elseif (PhiCTEMP>=0)&&(PhiCTEMP<=PhiBTEMP)
                                PhiCTEMP = PhiCTEMP+360;
                            end
                            if (PhiDTEMP>=PhiATEMP)&&(PhiDTEMP<360)
                                %无需操作
                            elseif (PhiDTEMP>=0)&&(PhiDTEMP<=PhiBTEMP)
                                PhiDTEMP = PhiDTEMP+360;
                            end
                            rotate = 1;
                            flag_CecD = rotate * sign(PhiDTEMP - PhiCTEMP);
                        elseif (PhiBTEMP>=PhiATEMP-180) && (PhiBTEMP<PhiATEMP)
                            rotate = -1;
                            flag_CecD = rotate * sign(PhiDTEMP - PhiCTEMP);
                        end
                    end
                end
                switch flag_CecD
                    case 1 %C→D和A→B方向一致，无需动作
                    case 0 %C=D，跳到下一段
                        temp0(j)=0;
                    case -1%D→C，需要调整顺序
                        temp1 = TEMP_Execution(temp0(j),4);
                        temp2 = TEMP_Execution(temp0(j),5);
                        TEMP_Execution(temp0(j),4) = TEMP_Execution(temp0(j),6);
                        TEMP_Execution(temp0(j),5) = TEMP_Execution(temp0(j),7);
                        TEMP_Execution(temp0(j),6) = temp1;
                        TEMP_Execution(temp0(j),7) = temp2;
                        temp3 = TEMP_Execution(temp0(j),11);
                        TEMP_Execution(temp0(j),11) = TEMP_Execution(temp0(j),12);
                        TEMP_Execution(temp0(j),12) = temp3;
                end
            end
%             
%             flag_CecD = sign((ArcAD - ArcAC)/(ArcAB));
%             for j = 1:length(flag_CecD)
%                 switch flag_CecD
%                     case 1 %C→D和A→B方向一致，无需动作
%                     case 0 %C=D，跳到下一段
%                         temp0(j)=0;
%                     case -1%D→C，需要调整顺序
%                         temp1 = TEMP_Execution(temp0(j),4);
%                         temp2 = TEMP_Execution(temp0(j),5);
%                         TEMP_Execution(temp0(j),4) = TEMP_Execution(temp0(j),6);
%                         TEMP_Execution(temp0(j),5) = TEMP_Execution(temp0(j),7);
%                         TEMP_Execution(temp0(j),6) = temp1;
%                         TEMP_Execution(temp0(j),7) = temp2;
%                         temp3 = TEMP_Execution(temp0(j),11);
%                         TEMP_Execution(temp0(j),11) = TEMP_Execution(temp0(j),12);
%                         TEMP_Execution(temp0(j),12) = temp3;
%                 end
%             end
            %   清空temp0中等于0的元素
            temp0(find(temp0)==0)=[];
            %   若Phi为空，跳到下个线段
            if isempty(temp0)
                continue
            end

            %Step6：插入
                %   若有多个temp0，只取第一个
                temp0=temp0(1);
                %   重新计算相关变量
                PhiCTEMP = TEMP_Execution(temp0,11);
                PhiDTEMP = TEMP_Execution(temp0,12);
                if PhiATEMP < PhiBTEMP
                    if (PhiATEMP>=0) && (PhiATEMP<180)
                        if (PhiBTEMP>=PhiATEMP) && (PhiBTEMP<PhiATEMP+180)
                            rotate = 1;
                        elseif (PhiBTEMP>=PhiATEMP+180) && (PhiBTEMP<360)
                            rotate = -1;
                        end
                    elseif (PhiATEMP>=180) && (PhiATEMP<360)
                        if (PhiBTEMP>=PhiATEMP) && (PhiBTEMP<360)
                            rotate = 1;
                        end
                    end
                elseif PhiATEMP > PhiBTEMP
                    if (PhiATEMP>=0) && (PhiATEMP<180)
                        if (PhiBTEMP>=0) && (PhiBTEMP<PhiATEMP)
                            rotate = -1;
                        end
                    elseif (PhiATEMP>=180) && (PhiATEMP<360)
                        if (PhiBTEMP>=0) && (PhiBTEMP<PhiATEMP-180)
                            rotate = 1;
                        elseif (PhiBTEMP>=PhiATEMP-180) && (PhiBTEMP<PhiATEMP)
                            rotate = -1;
                        end
                    end
                end
                Phi_MIN_TEMP1 = min([PhiATEMP,PhiBTEMP]);
                Phi_MAX_TEMP1 = max([PhiATEMP,PhiBTEMP]);
                Phi_MIN_TEMP2 = min([PhiCTEMP,PhiDTEMP],[],2);
                Phi_MAX_TEMP2 = max([PhiCTEMP,PhiDTEMP],[],2);
                ArcAB = PhiBTEMP-PhiATEMP;
                ArcAC = PhiCTEMP-PhiATEMP;
                ArcAD = PhiDTEMP-PhiATEMP;
                flag_AeqC = round(ArcAC*1e3)~=0;
                flag_BeqD = round(ArcAB*1e3 - ArcAD*1e3)~=0;
            %               switch [A==C D==B]
            %                   case [1 1]
            %                       起点      终点      气压工作标识
            %                       A         C         0
            %                       C         D         1
            %                       D         B         0
            %                   case [0 1]
            %                       起点      终点      气压工作标识
            %                       A         C         0
            %                       C         B         1
            %                   case [1 0]
            %                       起点      终点      气压工作标识
            %                       A         D         1
            %                       D         B         0
            %                   case [0 0]
            %                       起点      终点      气压工作标识
            %                       A         B         1
            %               end
            if flag_BeqD==1
                if flag_AeqC==1
                flag = 1;
                else
                    flag = 2;
                end
            else
                if flag_AeqC==1
                    flag = 3;
                else
                    flag = 4;
                end
            end
            %       1   2   3   4   5   6   7   8   9   10  11  12  13
            %       SN  LT  LN  X1  Y1  X2  Y2  Xc  Yc  R   θ1 θ1 flag
            %       已知AB，CD待定，按上面的情况讨论：
            %       case 1 A——C——D——B；
            %       case 2 A——C——B（D）；
            %       case 3 A（C）——D——B；
            %       case 4 A——B；
            switch flag
                case 1 %[1,1]
                    %   建立临时变量
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp5 = [TEMP_Execution(temp0,:),0];
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   序号为i的行行终点的坐标和角度改为C
                    temp3(end,6) = TEMP_Execution(temp0,4);
                    temp3(end,7) = TEMP_Execution(temp0,5);
                    temp3(end,12)= TEMP_Execution(temp0,11);
                    %   添加的段，并把执行标志位置为1
                    temp5(1,13)= 1;
                    temp5(1, 1)= 0;
                    %   提取原先序号为i的行起始点坐标、角度改为D，并写到插入点后
                    temp6(1,4) = TEMP_Execution(temp0,6);
                    temp6(1,5) = TEMP_Execution(temp0,7);
                    temp6(1,11)= TEMP_Execution(temp0,12);
                    temp6(1,1) = 0;
                    %   把截取的后面的数据粘结上，并赋值给TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp5;temp6;temp4];
                case 2 %[0,1]                    
                    %   建立临时变量
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   序号为i的行行终点的坐标和角度改为C
                    temp3(end,6) = TEMP_Execution(temp0,6);
                    temp3(end,7) = TEMP_Execution(temp0,7);
                    temp3(end,12)= TEMP_Execution(temp0,12);
                    temp3(end,13)= 1;
                    %   提取原先序号为i的行起始点坐标、角度改为C，并写到插入点后
                    temp6(1,4) = TEMP_Execution(temp0,6);
                    temp6(1,5) = TEMP_Execution(temp0,7);
                    temp6(1,11)= TEMP_Execution(temp0,12);
                    temp6(1,1) = 0;
                    temp6(1,13)= 0;
                    %   把截取的后面的数据粘结上，并赋值给TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp6;temp4];
                case 3 %[1,0]
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   序号为i的行行终点的坐标和角度改为D
                    temp3(end,6) = TEMP_Execution(temp0,4);
                    temp3(end,7) = TEMP_Execution(temp0,5);
                    temp3(end,12)= TEMP_Execution(temp0,11);
                    temp3(end,13)= 0;
                    %   提取原先序号为i的行起始点坐标、角度改为D，并写到插入点后
                    temp6(1,4) = TEMP_Execution(temp0,4);
                    temp6(1,5) = TEMP_Execution(temp0,5);
                    temp6(1,11)= TEMP_Execution(temp0,11);
                    temp6(1,1) = 0;
                    temp6(1,13)= 1;
                    %   把截取的后面的数据粘结上，并赋值给TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp6;temp4];
                case 4 %[0,0]
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp3(end,13)= 1;
                    %   把截取的后面的数据粘结上，并赋值给TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp4];
            end
            otherwise
    end
end
L = size(TEMP_Trajectory,1);
for i = 1:L
    TEMP_Trajectory(i,1)=i;
end
Trajectory4Print = TEMP_Trajectory;
%   2024-02-15 增加第14列-组别，方便后续轨迹对比
Trajectory4Print(:,14)=0; %先初始化为0
p_delta = Trajectory4Print(2:end,13)-Trajectory4Print(1:end-1,13); %读取线条变化的情况
p_start = find(p_delta==1); %找到每一组的起止点，但是这里是有问题的，由于p_delta只有n-1个，因此p_start比实际的小1
p_end = find(p_delta==-1); %p_end表示上一点是1而这一点是0，需要-1，由于上一行的问题要+1，抵消，因此不需要做调整
if length(p_start)==length(p_end)

elseif Trajectory4Print(end,13)==1 & length(p_start)-length(p_end)==1
    p_end(end+1)=size(Trajectory4Print,1);
else
    error('气压起止数量不一致，请检查路径文件')
end
for i=1:length(p_start)
    Trajectory4Print(p_start(i):p_end(i),14)=i;
end

%%   对扫描路径操作
%   2022-01-14 更新
%   这里进行了重写，从而实现新的工作流程，带标识的起止点数据→G代码
%   需要做相应的逻辑判断：
%           以打印为例：
%               在打印路径层， 通过起始点A找到该线段L1，并查找终止点B；
%               在气压路径层， 查找起点、终点到线段AB距离为零的线段L2；
%                             查找L2上距离A点最近的端点C，和较远点D；
%               switch [A==C D==B]
%                   case [0 0]
%                       起点      终点      密化操作标识
%                       A         C         0
%                       C         D         1
%                       D         B         0
%                   case [0 1]
%                       起点      终点      密化操作标识
%                       A         C         0
%                       C         B         1
%                   case [1 0]
%                       起点      终点      密化操作标识
%                       A         D         1
%                       D         B         0
%                   case [0 0]
%                       起点      终点      密化操作标识
%                       A         B         1
%               end
%   将打印路径赋值给临时变量，后面仅仅对变量TEMP_Trajectory进行操作，从而避免对源数据操作造成数据丢失
TEMP_Trajectory = Trajectory4Scan;
%   将第一列（序号）先全部置为0，后面再重新赋值
TEMP_Trajectory(:,1)=0;
%   按照设定的起始点（默认为[0,0]）查找第一个线段
temp0 = find((TEMP_Trajectory(:,4)==XS) & (TEMP_Trajectory(:,5)==YS));
%   将第一个线段的序号置为1
TEMP_Trajectory(temp0,1)=1;
%   将第一个线段的终点坐标赋值给临时变量，用于查找第二个线段，并开始循环
X2_TEMP = TEMP_Trajectory(temp0,6);
Y2_TEMP = TEMP_Trajectory(temp0,7);
for i = 2:length(TEMP_Trajectory(:,1))
    %   查找端点含有上个线段终点的线段
    temp = find((TEMP_Trajectory(:,4)==X2_TEMP) & (TEMP_Trajectory(:,5)==Y2_TEMP));
    if isempty(temp)
        %   若查不到，可能是因为绘图时，线条方向反了，按照终止点来查找
        tempr = find((TEMP_Trajectory(:,6)==X2_TEMP) & (TEMP_Trajectory(:,7)==Y2_TEMP));
        %   这时，需要注意，需要排除第一个线段的终止点
        tempr(find(tempr==temp0))=[];
        if isempty(tempr)
            error('无法找到下一点！')
        else
            %   接下来需要把该线段的起止点对调，但是需要判断其线型
            %             for j=1:length(tempr)
            %   如果找到了多个符合条件的线段，首先应循环执行，
            %   每次读取第一个，如果不符合需要就把数据删了，如果复合需要就停止处理
            %   把第一个数据对应的线型读取出来
            %   2022-01-14 更新
            %   这里修改了逻辑，应该是先对每一个数据进行操作，如果复合条件，处理；不符合条件，线型置为0
            %   处理完了，再把线型为0的，全部删除；
            %   在这之后，如果还剩多组数据，只取第一个
            %                 flag_line_type = TEMP_Trajectory(tempr(1),2);
            %   首先把不符合规定线型的数据删除
            for j=1:length(tempr)
                flag_line_type = TEMP_Trajectory(tempr(j),2);
                %   读取线型，并将非规定种类线型置为0
                switch flag_line_type
                    case 1  %   直线，不操作
                    case 2  %   圆弧，不操作
                    otherwise % 其他，置为0
                        flag_line_type(j)=0;
                end
                temp(find(flag_line_type==0))=[];
                %   将对应的数据删除
            end
            %   删除后判断一下还有没有剩余的点，如果没有则报错
            if isempty(tempr)
                error('无法找到下一点！')
            end

            %   如果剩下了数据，先判断是否有多组，如果有多组，则只取第一个，并警告
            if length(tempr)>1
                warning(['查找到多个线段，只取首个符合条件的！'])
                tempr = tempr(1);
            end

            %   然后将改组数据进行起止点对调
            flag_line_type = TEMP_Trajectory(tempr,2);
            switch flag_line_type
                case 1  %   直线，
                    %                         tempr(1)=tempr;
                    temp1 = TEMP_Trajectory(tempr,4);
                    temp2 = TEMP_Trajectory(tempr,5);
                    TEMP_Trajectory(tempr,4) = TEMP_Trajectory(tempr,6);
                    TEMP_Trajectory(tempr,5) = TEMP_Trajectory(tempr,7);
                    TEMP_Trajectory(tempr,6) = temp1;
                    TEMP_Trajectory(tempr,7) = temp2;
                case 2  %   圆弧
                    %                         tempr(1)=tempr;
                    %   2022-01-14 更新
                    %   之前写的不对，修正了一下
                    %                     tempr=tempr(1);
                    temp1 = TEMP_Trajectory(tempr,4);
                    temp2 = TEMP_Trajectory(tempr,5);
                    TEMP_Trajectory(tempr,4) = TEMP_Trajectory(tempr,6);
                    TEMP_Trajectory(tempr,5) = TEMP_Trajectory(tempr,7);
                    TEMP_Trajectory(tempr,6) = temp1;
                    TEMP_Trajectory(tempr,7) = temp2;
                    temp3 = TEMP_Trajectory(tempr,11);
                    TEMP_Trajectory(tempr,11) = TEMP_Trajectory(tempr,12);
                    TEMP_Trajectory(tempr,12) = temp3;
            end

            %   处理完了之后，把tempr重新赋值给temp，完成线段颠倒的处置
            temp = tempr;
            %             end
        end
    else
        %   temp非空时，需要排除一下线型错误的影响
        flag_line_type = TEMP_Trajectory(temp,2);
        for j=1:length(temp)
            flag_line_type = TEMP_Trajectory(temp(j),2);
            %   读取线型，并将非规定种类线型置为0
            switch flag_line_type
                case 1  %   直线，不操作
                case 2  %   圆弧，不操作
                otherwise % 其他，置为0
                    flag_line_type(j)=0;
            end
        end
        temp(find(flag_line_type==0))=[];
        %   将对应的数据删除
        %   此时，如果不止一个temp，需要发出警告，并且只取首个temp
        if length(temp)>1
            warning(['查找到多个线段，只取首个符合条件的！'])
            temp = temp(1);
        end
    end
    TEMP_Trajectory(temp,1)=i;
    X2_TEMP = TEMP_Trajectory(temp,6);
    Y2_TEMP = TEMP_Trajectory(temp,7);
    if test_a
        disp(i)
    end
    temp0 = temp;
end
[b,pos] = sort(TEMP_Trajectory(:,1));
Trajectory4Scan = TEMP_Trajectory( pos , :);
%%   对密化路径操作
%   根据“对气压路径操作”部分微调
% TEMP_Trajectory = Trajectory4Airpressure;
% TEMP_Trajectory(:,1)=0;
% temp0 = find((TEMP_Trajectory(:,4)==XA) & (TEMP_Trajectory(:,5)==YA));
% TEMP_Trajectory(temp0,1)=1;
% X2_TEMP = TEMP_Trajectory(temp0,6);
% Y2_TEMP = TEMP_Trajectory(temp0,7);
% for i = 2:length(TEMP_Trajectory(:,1))
%     temp = find((TEMP_Trajectory(:,4)==X2_TEMP) & (TEMP_Trajectory(:,5)==Y2_TEMP));
%     if isempty(temp)
%         tempr = find((TEMP_Trajectory(:,6)==X2_TEMP) & (TEMP_Trajectory(:,7)==Y2_TEMP));
%         tempr(find(tempr==temp0))=[];
%         if isempty(tempr)
%             error('无法找到下一点！')
%         else
%             for j=1:length(tempr)
%                 flag_line_type = TEMP_Trajectory(tempr(1),2);
%                 switch flag_line_type
%                     case 1
%                         tempr(1)=tempr;
%                         temp1 = TEMP_Trajectory(tempr,4);
%                         temp2 = TEMP_Trajectory(tempr,5);
%                         TEMP_Trajectory(tempr,4) = TEMP_Trajectory(tempr,6);
%                         TEMP_Trajectory(tempr,5) = TEMP_Trajectory(tempr,7);
%                         TEMP_Trajectory(tempr,6) = temp1;
%                         TEMP_Trajectory(tempr,7) = temp2;
%                     case 2
%                         tempr(1)=tempr;
%                         temp1 = TEMP_Trajectory(tempr,4);
%                         temp2 = TEMP_Trajectory(tempr,5);
%                         TEMP_Trajectory(tempr,4) = TEMP_Trajectory(tempr,6);
%                         TEMP_Trajectory(tempr,5) = TEMP_Trajectory(tempr,7);
%                         TEMP_Trajectory(tempr,6) = temp1;
%                         TEMP_Trajectory(tempr,7) = temp2;
%                         temp3 = TEMP_Trajectory(tempr,11);
%                         TEMP_Trajectory(tempr,11) = TEMP_Trajectory(tempr,12);
%                         TEMP_Trajectory(tempr,12) = temp3;
%                     otherwise
%                         tempr(j)=[];
%                 end
%                 if isempty(tempr)
%                     error('无法找到下一点！')
%                 else
%                     temp=tempr;
%                 end
%             end
%         end
%     end
%     TEMP_Trajectory(temp,1)=i;
%     X2_TEMP = TEMP_Trajectory(temp,6);
%     Y2_TEMP = TEMP_Trajectory(temp,7);
%     if test_a
%         disp(i)
%     end
%     temp0 = temp;
% end
% [b,pos] = sort(TEMP_Trajectory(:,1));
% Trajectory4Airpressure = TEMP_Trajectory( pos , :);
%   2022-01-14 更新
%               在打印路径层， 通过起始点A找到该线段L1，并查找终止点B；
%               在气压路径层， 查找起点、终点到线段AB距离为零的线段L2；
%                             查找L2上距离A点最近的端点C，和较远点D；
%               switch [A==C D==B]
%                   case [0 0]
%                       起点      终点      气压工作标识
%                       A         C         0
%                       C         D         1
%                       D         B         0
%                   case [0 1]
%                       起点      终点      气压工作标识
%                       A         C         0
%                       C         B         1
%                   case [1 0]
%                       起点      终点      气压工作标识
%                       A         D         1
%                       D         B         0
%                   case [0 0]
%                       起点      终点      气压工作标识
%                       A         B         1
%               end
%   新的思路是对打印路径进行读取，判断是否需要在线段中插入气压工作的行
%   将气压路径赋值给临时变量，后面仅仅对变量TEMP_Execution, TEMP_Trajectory进行操作，从而避免对源数据操作造成数据丢失
TEMP_Execution  = Trajectory4Interpolation;
TEMP_Trajectory = [Trajectory4Scan,zeros(size(Trajectory4Scan,1),1)];%在Trajectory4Scan后添加一列标志位，全部为0
%   对TEMP_Trajectory遍历，寻找重合的TEMP_Execution段，并插入到TEMP_Trajectory中
L = size(TEMP_Trajectory,1);
for i = 1:L
    %   由于循环中会插入行，需要按照第一列（序号）来查找对应的行
    temp_Current_Tra = find(TEMP_Trajectory(:,1)==i);
    switch TEMP_Trajectory(temp_Current_Tra,2)
        case 1  %   直线，需要判断：①初筛的线段线型是否一致，②起止点是否位于AB上即可
            %   按照起止点圈定的范围寻找线段初筛，再通过线型判断、重合判断精筛出与当前线段重合的线段。
            %Step1：范围筛选
            %   获取当前行的起始点A和终止点B
            X_A_TEMP = TEMP_Trajectory(temp_Current_Tra,4);
            Y_A_TEMP = TEMP_Trajectory(temp_Current_Tra,5);
            X_B_TEMP = TEMP_Trajectory(temp_Current_Tra,6);
            Y_B_TEMP = TEMP_Trajectory(temp_Current_Tra,7);
            %   在TEMP_Execution中查找在AB构成的矩形区域内的线段
            X_MIN_TEMP1 = min([X_A_TEMP, X_B_TEMP]);
            Y_MIN_TEMP1 = min([Y_A_TEMP, Y_B_TEMP]);
            X_MAX_TEMP1 = max([X_A_TEMP, X_B_TEMP]);
            Y_MAX_TEMP1 = max([Y_A_TEMP, Y_B_TEMP]);
            X_MIN_TEMP2 = min([TEMP_Execution(:,4), TEMP_Execution(:,6)],[],2);
            Y_MIN_TEMP2 = min([TEMP_Execution(:,5), TEMP_Execution(:,7)],[],2);
            X_MAX_TEMP2 = max([TEMP_Execution(:,4), TEMP_Execution(:,6)],[],2);
            Y_MAX_TEMP2 = max([TEMP_Execution(:,5), TEMP_Execution(:,7)],[],2);
            temp0 = find(   round((X_MIN_TEMP1-X_MIN_TEMP2)*1e3)<=0&...
                            round((Y_MIN_TEMP1-Y_MIN_TEMP2)*1e3)<=0&...
                            round((X_MAX_TEMP1-X_MAX_TEMP2)*1e3)>=0&...
                            round((Y_MAX_TEMP1-Y_MAX_TEMP2)*1e3)>=0      );
            %   若在圈定范围内找不到，跳到下个线段
            if isempty(temp0)
                continue
            end
            %Step2：线型筛选
            %   查找线型为直线的线段
            temp0 = temp0(find(TEMP_Execution(temp0,2)==1));
            %   若在找不到，跳到下个线段
            if isempty(temp0)
                continue
            end
            %Step3：几何关系筛选
            %   判断查找到的线段的端点是否在当前线段上
            %       读取所有的起止点
            X_C_TEMP = TEMP_Execution(temp0,4);
            Y_C_TEMP = TEMP_Execution(temp0,5);
            X_D_TEMP = TEMP_Execution(temp0,6);
            Y_D_TEMP = TEMP_Execution(temp0,7);
            vector_AB = [X_B_TEMP-X_A_TEMP, Y_B_TEMP-Y_A_TEMP];
            vector_AC = [X_C_TEMP-X_A_TEMP, Y_C_TEMP-Y_A_TEMP];
            vector_AD = [X_D_TEMP-X_A_TEMP, Y_D_TEMP-Y_A_TEMP];
            for j = 1:length(temp0)
                distance_AC = round(norm(vector_AC(j,:))*1e3);
                distance_AD = round(norm(vector_AD(j,:))*1e3);
                complex_AB = complex(vector_AB(1),vector_AB(2));
                complex_AC = complex(vector_AC(j,1),vector_AC(j,2));
                complex_AD = complex(vector_AD(j,1),vector_AD(j,2));
                angle_AB = angle(complex_AB)*180/pi;
                if distance_AC==0
                    angle_AC = angle_AB;
                else
                    angle_AC = angle(complex_AC)*180/pi;
                end
                if distance_AD==0
                    angle_AD = angle_AB;
                else
                    angle_AD = angle(complex_AD)*180/pi;
                end
                error1 = round(angle_AB*1e2-angle_AC*1e2);
                error2 = round(angle_AB*1e2-angle_AD*1e2);
                if (error1~=0)||(error2~=0)
                    temp0(j)=0;
                end
            end
            temp0(find(temp0==0))=[];
            %   若在找不到，跳到下个线段
            if isempty(temp0)
                continue
            else
                %   若筛选出重合的线段，则判断temp0元素数量，若大于1则警告并只取第一个
                if length(temp0)>1
                    warning('存在重合线段，只取第一个重合点')
                    temp0=temp0(1);
                end
            end

            %Step4：调整
            X_C_TEMP = TEMP_Execution(temp0,4);
            Y_C_TEMP = TEMP_Execution(temp0,5);
            X_D_TEMP = TEMP_Execution(temp0,6);
            Y_D_TEMP = TEMP_Execution(temp0,7);
            distance_AB = norm([X_B_TEMP-X_A_TEMP, Y_B_TEMP-Y_A_TEMP]);
            distance_AC = norm([X_C_TEMP-X_A_TEMP, Y_C_TEMP-Y_A_TEMP]);
            distance_AD = norm([X_D_TEMP-X_A_TEMP, Y_D_TEMP-Y_A_TEMP]);
            flag_CeqD = round(distance_AC*1e3 - distance_AD*1e3)==0;
            flag_CecD = round(distance_AC*1e3 - distance_AD*1e3)>0;
            flag_AeqC = round(distance_AC*1e3)~=0;
            flag_BeqD = round(distance_AB*1e3 - distance_AD*1e3)~=0;
            %   若CD长度等于0，跳到下个线段
            if flag_CeqD
                continue
            end
            %   若CD需要对调，则进行对调
            if flag_CecD
                %   首先进行对调
                temp1 = TEMP_Execution(temp0,4);
                temp2 = TEMP_Execution(temp0,5);
                TEMP_Execution(temp0,4) = TEMP_Execution(temp0,6);
                TEMP_Execution(temp0,5) = TEMP_Execution(temp0,7);
                TEMP_Execution(temp0,6) = temp1;
                TEMP_Execution(temp0,7) = temp2;
                %   接着重新计算相关变量
                X_C_TEMP = TEMP_Execution(temp0,4);
                Y_C_TEMP = TEMP_Execution(temp0,5);
                X_D_TEMP = TEMP_Execution(temp0,6);
                Y_D_TEMP = TEMP_Execution(temp0,7);
                distance_AB = norm([X_B_TEMP-X_A_TEMP, Y_B_TEMP-Y_A_TEMP]);
                distance_AC = norm([X_C_TEMP-X_A_TEMP, Y_C_TEMP-Y_A_TEMP]);
                distance_AD = norm([X_D_TEMP-X_A_TEMP, Y_D_TEMP-Y_A_TEMP]);
                flag_AeqC = round(distance_AC*1e3)~=0;
                flag_BeqD = round(distance_AB*1e3 - distance_AD*1e3)~=0;
            end

            %Step5：插入
            %               switch [A==C D==B]
            %                   case [1 1]
            %                       起点      终点      气压工作标识
            %                       A         C         0
            %                       C         D         1
            %                       D         B         0
            %                   case [0 1]
            %                       起点      终点      气压工作标识
            %                       A         C         0
            %                       C         B         1
            %                   case [1 0]
            %                       起点      终点      气压工作标识
            %                       A         D         1
            %                       D         B         0
            %                   case [0 0]
            %                       起点      终点      气压工作标识
            %                       A         B         1
            %               end
            if flag_BeqD==1
                if flag_AeqC==1
                flag = 1;
                else
                    flag = 2;
                end
            else
                if flag_AeqC==1
                    flag = 3;
                else
                    flag = 4;
                end
            end
            switch flag
                case 1 %[1,1]
                    %   建立临时变量
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp5 = [TEMP_Execution(temp0,:),0];
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   序号为i的行行终点改为C
                    temp3(end,6) = X_C_TEMP;
                    temp3(end,7) = Y_C_TEMP;
                    %   添加的段，并把执行标志位置为1
                    temp5(1,13)= 1;
                    temp5(1, 1)= 0;
                    %   提取原先序号为i的行起始点改为D，并写到插入点后
                    temp6(1,4) = X_D_TEMP;
                    temp6(1,5) = Y_D_TEMP;
                    temp6(1,1) = 0;
                    %   把截取的后面的数据粘结上，并赋值给TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp5;temp6;temp4];
                case 2 %[0,1]
                    %   建立临时变量
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   序号为i的行行终点改为C
                    temp3(end,6) = X_D_TEMP;
                    temp3(end,7) = Y_D_TEMP;
                    temp3(end,13)= 1;
                    %   提取原先序号为i的行起始点改为C，并把执行标志位置为1，并写到插入点后
                    temp6(1,4) = X_D_TEMP;
                    temp6(1,5) = Y_D_TEMP;
                    temp6(1,1) = 0;
                    temp6(1,13)= 0;
                    %   把截取的后面的数据粘结上，并赋值给TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp6;temp4];
                case 3 %[1,0]
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   序号为i的行行终点改为C
                    temp3(end,6) = X_C_TEMP;
                    temp3(end,7) = Y_C_TEMP;
                    temp3(end,13)= 0;
                    %   提取原先序号为i的行起始点改为D，并写到插入点后
                    temp6(1,4) = X_C_TEMP;
                    temp6(1,5) = Y_C_TEMP;
                    temp6(1,1) = 0;
                    temp6(1,13)= 1;
                    %   把截取的后面的数据粘结上，并赋值给TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp6;temp4];
                case 4 %[0,0]
                    %   建立临时变量
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    %   序号为i的行把执行标志位置为1
                    temp3(end,13) = 1;
                    %   把截取的后面的数据粘结上，并赋值给TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp4];
            end
        case 2  %   圆弧，需要判断：①线型、圆心坐标R及半径是否一致，②起止角度是否在范围内
            %   首先通过线型、圆心位置、半径进行初筛；再通过圆弧角度范围进行精筛。
            %Step1：线型筛选
            temp0 = find(TEMP_Execution(:,2)==2);
            %   若在找不到，跳到下个线段
            if isempty(temp0)
                continue
            end

            %Step2：圆心位置筛选
            %   获取当前圆弧的圆心A、半径R、起止角度
            X_A_TEMP = TEMP_Trajectory(temp_Current_Tra,8);
            Y_A_TEMP = TEMP_Trajectory(temp_Current_Tra,9);
            R_A_TEMP = TEMP_Trajectory(temp_Current_Tra,10);
            PhiATEMP = TEMP_Trajectory(temp_Current_Tra,11);
            PhiBTEMP = TEMP_Trajectory(temp_Current_Tra,12);
            %   在TEMP_Execution中查找圆心在A点的圆弧
            X_B_TEMP = TEMP_Execution(temp0,8);
            Y_B_TEMP = TEMP_Execution(temp0,9);
            vector_A = [X_B_TEMP-X_A_TEMP, Y_B_TEMP-Y_A_TEMP];
            for j = 1:length(temp0)
                distance_AB = round(norm(vector_A(j,:))*1e3);
                if distance_AB~=0
                    temp0(j)=0;
                end
            end
            temp0(find(temp0==0))=[];
            %   若在找不到，跳到下个线段
            if isempty(temp0)
                continue
            end

            %Step3：按半径筛选
            R_B_TEMP = TEMP_Execution(temp0,10);
            error1 = round((R_B_TEMP-R_A_TEMP)*1e3);
            temp0 = temp0(find(error1==0));
            %   若在找不到，跳到下个线段
            if isempty(temp0)
                continue
            end

%             %Step4：按角度范围筛选
%             %   需要注意一个问题，角度是否过零点！
%             %   问题可以简化为角度不超过180°的短弧是所需的圆弧
%             %   因此，首先需要确定角度的表示问题。
% %             %   正方向为逆时针方向
% %             if PhiATEMP<PhiBTEMP
% %                 DeltaPhi = PhiBTEMP - PhiATEMP;
% %                 if abs(DeltaPhi)<180
% %                     %   PhiB > PhiA，正方向为劣弧：无需处理
% %                 elseif abs(deltaPhi>180
% %                     %   PhiB > PhiA，逆方向为劣弧：PhiB-360°
% %                     PhiBTEMP = PhiBTEMP - 360;
% %                 else
% %                     error('存在180°圆弧，无法计算！')
% %                 end
% %             elseif PhiATEMP>PhiBTEMP
% %                 DeltaPhi = PhiBTEMP - PhiATEMP;
% %                 if abs(DeltaPhi)<180
% %                     %   PhiB > PhiA，逆方向为劣弧：无需处理
% %                 elseif abs(deltaPhi>180
% %                     %   PhiB < PhiA，正方向为劣弧：PhiA+360°
% %                     PhiATEMP = PhiATEMP - 360;
% %                 else
% %                     error('存在180°圆弧，无法计算！')
% %                 end
% %             else 
% %                 continue
% %             end
%             PhiCTEMP = TEMP_Execution(temp0,11);
%             PhiDTEMP = TEMP_Execution(temp0,12);
%             Phi_MIN_TEMP1 = min([PhiATEMP,PhiBTEMP]);
%             Phi_MAX_TEMP1 = max([PhiATEMP,PhiBTEMP]);
%             Phi_MIN_TEMP2 = min([PhiCTEMP,PhiDTEMP],[],2);
%             Phi_MAX_TEMP2 = max([PhiCTEMP,PhiDTEMP],[],2);
%             temp0(find(     round((Phi_MIN_TEMP1-Phi_MIN_TEMP2)*1e3)>0&...
%                             round((Phi_MAX_TEMP1-Phi_MAX_TEMP2)*1e3)<0      ))...
%                             =[];
%             %   若在角度不在PhiA，PhiB范围内找不到，跳到下个线段
%             if isempty(temp0)
%                 continue
%             end

            %Step5：范围判断与调整
            PhiCTEMP = TEMP_Execution(temp0,11);
            PhiDTEMP = TEMP_Execution(temp0,12);
            ArcAB = PhiBTEMP-PhiATEMP;
            ArcAC = PhiCTEMP-PhiATEMP;
            ArcAD = PhiDTEMP-PhiATEMP;
            if ArcAB == 0
                continue
            end
            %范围判断
            %   有点复杂，正方向为逆时针
            %   PhiA<PhiB时
            %       PhiA在 (0,180)时
            %           PhiB 在 (PhiA,PhiA+180)时，A向B正方向区间(PhiA,PhiB)
            %           PhiB 在 (PhiA+180,360 )时，A向B逆方向区间(PhiB,360)|(0,PhiA)
            %       PhiA在 (180，360)时
            %           PhiB 在 (PhiA,360)     时，A向B正方向区间(PhiA,PhiB)
            %   PhiA>PhiB时
            %       PhiA在 (0,180)时
            %           PhiB 在 (0,PhiA)       时，A向B逆方向区间(PhiB,PhiA)
            %       PhiA在 (180，360)时
            %           PhiB 在 (0,PhiA-180)   时，A向B正方向区间(PhiA,360)|(0,PhiB)
            %           PhiB 在 (PhiA-180,PhiA)时，A向B逆方向区间(PhiB,PhiA)
            for j = 1:length(temp0)
                PhiCTEMP = TEMP_Execution(temp0(j),11);
                PhiDTEMP = TEMP_Execution(temp0(j),12);
                if PhiATEMP < PhiBTEMP
                    if (PhiATEMP>=0) && (PhiATEMP<180)
                        if (PhiBTEMP>=PhiATEMP) && (PhiBTEMP<PhiATEMP+180)
                            flag_C = (PhiCTEMP>=PhiATEMP)&&(PhiCTEMP<=PhiBTEMP);
                            flag_D = (PhiDTEMP>=PhiATEMP)&&(PhiDTEMP<=PhiBTEMP);
                            rotate = 1;
                        elseif (PhiBTEMP>=PhiATEMP+180) && (PhiBTEMP<360)
                            flag_C = ((PhiCTEMP>=0)&&(PhiCTEMP<=PhiATEMP))||...
                                     ((PhiCTEMP>=PhiBTEMP)&&(PhiCTEMP<360));
                            flag_D = ((PhiDTEMP>=0)&&(PhiDTEMP<=PhiATEMP))||...
                                     ((PhiDTEMP>=PhiBTEMP)&&(PhiDTEMP<360));
                            rotate = -1;
                        end
                    elseif (PhiATEMP>=180) && (PhiATEMP<360)
                        if (PhiBTEMP>=PhiATEMP) && (PhiBTEMP<360)
                            flag_C = (PhiCTEMP>=PhiATEMP)&&(PhiCTEMP<=PhiBTEMP);
                            flag_D = (PhiDTEMP>=PhiATEMP)&&(PhiDTEMP<=PhiBTEMP);
                            rotate = 1;
                        end
                    end
                elseif PhiATEMP > PhiBTEMP
                    if (PhiATEMP>=0) && (PhiATEMP<180)
                        if (PhiBTEMP>=0) && (PhiBTEMP<PhiATEMP)
                            flag_C = (PhiCTEMP>=PhiBTEMP)&&(PhiCTEMP<=PhiATEMP);
                            flag_D = (PhiDTEMP>PhiBTEMP)&&(PhiDTEMP<=PhiATEMP);
                            rotate = -1;
                        end
                    elseif (PhiATEMP>=180) && (PhiATEMP<360)
                        if (PhiBTEMP>=0) && (PhiBTEMP<PhiATEMP-180)
                            flag_C = ((PhiCTEMP>=PhiATEMP)&&(PhiCTEMP<360))||...
                                     ((PhiCTEMP>=0)&&(PhiCTEMP<=PhiBTEMP));
                            flag_D = ((PhiDTEMP>=PhiATEMP)&&(PhiDTEMP<360))||...
                                     ((PhiDTEMP>=0)&&(PhiDTEMP<=PhiBTEMP));
                            rotate = 1;
                        elseif (PhiBTEMP>=PhiATEMP-180) && (PhiBTEMP<PhiATEMP)
                            flag_C = (PhiCTEMP>=PhiBTEMP)&&(PhiCTEMP<=PhiATEMP);
                            flag_D = (PhiDTEMP>=PhiBTEMP)&&(PhiDTEMP<=PhiATEMP);
                            rotate = -1;
                        end
                    end
                end
                %若存在不在范围内的点，则置零
                if (flag_C==0)||(flag_D==0)
                    temp(j)=0;                    
                end
            end
            temp0(find(temp0==0));
            %   若在找不到，跳到下个线段
            if isempty(temp0)
                continue
            end
            %调整
            for j = 1:length(temp0)
                PhiCTEMP = TEMP_Execution(temp0(j),11);
                PhiDTEMP = TEMP_Execution(temp0(j),12);
                if PhiATEMP < PhiBTEMP
                    if (PhiATEMP>=0) && (PhiATEMP<180)
                        if (PhiBTEMP>=PhiATEMP) && (PhiBTEMP<PhiATEMP+180)
                            rotate = 1;
                            flag_CecD = rotate * sign(PhiDTEMP - PhiCTEMP);
                        elseif (PhiBTEMP>=PhiATEMP+180) && (PhiBTEMP<360)
                            if (PhiCTEMP>=0)&&(PhiCTEMP<=PhiATEMP)
                                %无需操作
                            elseif (PhiCTEMP>=PhiBTEMP)&&(PhiCTEMP<360)
                                PhiCTEMP = PhiCTEMP-360;
                            end
                            if (PhiDTEMP>=0)&&(PhiDTEMP<=PhiATEMP)
                                %无需操作
                            elseif (PhiDTEMP>=PhiBTEMP)&&(PhiDTEMP<360)
                                PhiCTEMP = PhiCTEMP-360;
                            end
                            rotate = -1;
                            flag_CecD = rotate * sign(PhiDTEMP - PhiCTEMP);
                        end
                    elseif (PhiATEMP>=180) && (PhiATEMP<360)
                        if (PhiBTEMP>=PhiATEMP) && (PhiBTEMP<360)
                            rotate = 1;
                            flag_CecD = rotate * sign(PhiDTEMP - PhiCTEMP);
                        end
                    end
                elseif PhiATEMP > PhiBTEMP
                    if (PhiATEMP>=0) && (PhiATEMP<180)
                        if (PhiBTEMP>=0) && (PhiBTEMP<PhiATEMP)
                            rotate = -1;
                            flag_CecD = rotate * sign(PhiDTEMP - PhiCTEMP);
                        end
                    elseif (PhiATEMP>=180) && (PhiATEMP<360)
                        if (PhiBTEMP>=0) && (PhiBTEMP<PhiATEMP-180)
                            if (PhiCTEMP>=PhiATEMP)&&(PhiCTEMP<360)
                                %无需操作
                            elseif (PhiCTEMP>=0)&&(PhiCTEMP<=PhiBTEMP)
                                PhiCTEMP = PhiCTEMP+360;
                            end
                            if (PhiDTEMP>=PhiATEMP)&&(PhiDTEMP<360)
                                %无需操作
                            elseif (PhiDTEMP>=0)&&(PhiDTEMP<=PhiBTEMP)
                                PhiDTEMP = PhiDTEMP+360;
                            end
                            rotate = 1;
                            flag_CecD = rotate * sign(PhiDTEMP - PhiCTEMP);
                        elseif (PhiBTEMP>=PhiATEMP-180) && (PhiBTEMP<PhiATEMP)
                            rotate = -1;
                            flag_CecD = rotate * sign(PhiDTEMP - PhiCTEMP);
                        end
                    end
                end
                switch flag_CecD
                    case 1 %C→D和A→B方向一致，无需动作
                    case 0 %C=D，跳到下一段
                        temp0(j)=0;
                    case -1%D→C，需要调整顺序
                        temp1 = TEMP_Execution(temp0(j),4);
                        temp2 = TEMP_Execution(temp0(j),5);
                        TEMP_Execution(temp0(j),4) = TEMP_Execution(temp0(j),6);
                        TEMP_Execution(temp0(j),5) = TEMP_Execution(temp0(j),7);
                        TEMP_Execution(temp0(j),6) = temp1;
                        TEMP_Execution(temp0(j),7) = temp2;
                        temp3 = TEMP_Execution(temp0(j),11);
                        TEMP_Execution(temp0(j),11) = TEMP_Execution(temp0(j),12);
                        TEMP_Execution(temp0(j),12) = temp3;
                end
            end
%             
%             flag_CecD = sign((ArcAD - ArcAC)/(ArcAB));
%             for j = 1:length(flag_CecD)
%                 switch flag_CecD
%                     case 1 %C→D和A→B方向一致，无需动作
%                     case 0 %C=D，跳到下一段
%                         temp0(j)=0;
%                     case -1%D→C，需要调整顺序
%                         temp1 = TEMP_Execution(temp0(j),4);
%                         temp2 = TEMP_Execution(temp0(j),5);
%                         TEMP_Execution(temp0(j),4) = TEMP_Execution(temp0(j),6);
%                         TEMP_Execution(temp0(j),5) = TEMP_Execution(temp0(j),7);
%                         TEMP_Execution(temp0(j),6) = temp1;
%                         TEMP_Execution(temp0(j),7) = temp2;
%                         temp3 = TEMP_Execution(temp0(j),11);
%                         TEMP_Execution(temp0(j),11) = TEMP_Execution(temp0(j),12);
%                         TEMP_Execution(temp0(j),12) = temp3;
%                 end
%             end
            %   清空temp0中等于0的元素
            temp0(find(temp0)==0)=[];
            %   若Phi为空，跳到下个线段
            if isempty(temp0)
                continue
            end

            %Step6：插入
                %   若有多个temp0，只取第一个
                temp0=temp0(1);
                %   重新计算相关变量
                PhiCTEMP = TEMP_Execution(temp0,11);
                PhiDTEMP = TEMP_Execution(temp0,12);
                if PhiATEMP < PhiBTEMP
                    if (PhiATEMP>=0) && (PhiATEMP<180)
                        if (PhiBTEMP>=PhiATEMP) && (PhiBTEMP<PhiATEMP+180)
                            rotate = 1;
                        elseif (PhiBTEMP>=PhiATEMP+180) && (PhiBTEMP<360)
                            rotate = -1;
                        end
                    elseif (PhiATEMP>=180) && (PhiATEMP<360)
                        if (PhiBTEMP>=PhiATEMP) && (PhiBTEMP<360)
                            rotate = 1;
                        end
                    end
                elseif PhiATEMP > PhiBTEMP
                    if (PhiATEMP>=0) && (PhiATEMP<180)
                        if (PhiBTEMP>=0) && (PhiBTEMP<PhiATEMP)
                            rotate = -1;
                        end
                    elseif (PhiATEMP>=180) && (PhiATEMP<360)
                        if (PhiBTEMP>=0) && (PhiBTEMP<PhiATEMP-180)
                            rotate = 1;
                        elseif (PhiBTEMP>=PhiATEMP-180) && (PhiBTEMP<PhiATEMP)
                            rotate = -1;
                        end
                    end
                end
                Phi_MIN_TEMP1 = min([PhiATEMP,PhiBTEMP]);
                Phi_MAX_TEMP1 = max([PhiATEMP,PhiBTEMP]);
                Phi_MIN_TEMP2 = min([PhiCTEMP,PhiDTEMP],[],2);
                Phi_MAX_TEMP2 = max([PhiCTEMP,PhiDTEMP],[],2);
                ArcAB = PhiBTEMP-PhiATEMP;
                ArcAC = PhiCTEMP-PhiATEMP;
                ArcAD = PhiDTEMP-PhiATEMP;
                flag_AeqC = round(ArcAC*1e3)~=0;
                flag_BeqD = round(ArcAB*1e3 - ArcAD*1e3)~=0;
            %               switch [A==C D==B]
            %                   case [1 1]
            %                       起点      终点      气压工作标识
            %                       A         C         0
            %                       C         D         1
            %                       D         B         0
            %                   case [0 1]
            %                       起点      终点      气压工作标识
            %                       A         C         0
            %                       C         B         1
            %                   case [1 0]
            %                       起点      终点      气压工作标识
            %                       A         D         1
            %                       D         B         0
            %                   case [0 0]
            %                       起点      终点      气压工作标识
            %                       A         B         1
            %               end
            if flag_BeqD==1
                if flag_AeqC==1
                flag = 1;
                else
                    flag = 2;
                end
            else
                if flag_AeqC==1
                    flag = 3;
                else
                    flag = 4;
                end
            end
            %       1   2   3   4   5   6   7   8   9   10  11  12  13
            %       SN  LT  LN  X1  Y1  X2  Y2  Xc  Yc  R   θ1 θ1 flag
            %       已知AB，CD待定，按上面的情况讨论：
            %       case 1 A——C——D——B；
            %       case 2 A——C——B（D）；
            %       case 3 A（C）——D——B；
            %       case 4 A——B；
            switch flag
                case 1 %[1,1]
                    %   建立临时变量
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp5 = [TEMP_Execution(temp0,:),0];
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   序号为i的行行终点的坐标和角度改为C
                    temp3(end,6) = TEMP_Execution(temp0,4);
                    temp3(end,7) = TEMP_Execution(temp0,5);
                    temp3(end,12)= TEMP_Execution(temp0,11);
                    %   添加的段，并把执行标志位置为1
                    temp5(1,13)= 1;
                    temp5(1, 1)= 0;
                    %   提取原先序号为i的行起始点坐标、角度改为D，并写到插入点后
                    temp6(1,4) = TEMP_Execution(temp0,6);
                    temp6(1,5) = TEMP_Execution(temp0,7);
                    temp6(1,11)= TEMP_Execution(temp0,12);
                    temp6(1,1) = 0;
                    %   把截取的后面的数据粘结上，并赋值给TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp5;temp6;temp4];
                case 2 %[0,1]                    
                    %   建立临时变量
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   序号为i的行行终点的坐标和角度改为C
                    temp3(end,6) = TEMP_Execution(temp0,6);
                    temp3(end,7) = TEMP_Execution(temp0,7);
                    temp3(end,12)= TEMP_Execution(temp0,12);
                    temp3(end,13)= 1;
                    %   提取原先序号为i的行起始点坐标、角度改为C，并写到插入点后
                    temp6(1,4) = TEMP_Execution(temp0,6);
                    temp6(1,5) = TEMP_Execution(temp0,7);
                    temp6(1,11)= TEMP_Execution(temp0,12);
                    temp6(1,1) = 0;
                    temp6(1,13)= 0;
                    %   把截取的后面的数据粘结上，并赋值给TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp6;temp4];
                case 3 %[1,0]
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   序号为i的行行终点的坐标和角度改为D
                    temp3(end,6) = TEMP_Execution(temp0,4);
                    temp3(end,7) = TEMP_Execution(temp0,5);
                    temp3(end,12)= TEMP_Execution(temp0,11);
                    temp3(end,13)= 0;
                    %   提取原先序号为i的行起始点坐标、角度改为D，并写到插入点后
                    temp6(1,4) = TEMP_Execution(temp0,4);
                    temp6(1,5) = TEMP_Execution(temp0,5);
                    temp6(1,11)= TEMP_Execution(temp0,11);
                    temp6(1,1) = 0;
                    temp6(1,13)= 1;
                    %   把截取的后面的数据粘结上，并赋值给TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp6;temp4];
                case 4 %[0,0]
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp3(end,13)= 1;
                    %   把截取的后面的数据粘结上，并赋值给TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp4];
            end
            otherwise
    end
end
L = size(TEMP_Trajectory,1);
for i = 1:L
    TEMP_Trajectory(i,1)=i;
end
Trajectory4Scan = TEMP_Trajectory;
%%  2024-01-26 保存dxf到类中
obj.TJ_data.TJ4PT = Trajectory4Print;
obj.TJ_data.TJ4AP = Trajectory4Airpressure;
obj.TJ_data.TJ4SC = Trajectory4Scan;
obj.TJ_data.TJ4IT = Trajectory4Interpolation;
%%  保存Gcode草稿
%   初始化
Flag_Air_Target= 0;                         %目标气压状态
Flag_Air_Current = Flag_Air_Target;         %当前气压状态
Target_Position = zeros(1,2);               %目标位置
cmd_num = 1;
%   前置代码
obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','; This file is generated by LaserScan Class. Copyright Martin All Rights Reserved');
cmd_num=cmd_num+1;
obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','; Email: martinsoaring@outlook.com');
cmd_num=cmd_num+1;
obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G28;');
cmd_num=cmd_num+1;
obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G0 F3000;');
cmd_num=cmd_num+1;
obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s',['G0 Z',num2str(3+Z_Offset,'%.3f'),';']);
cmd_num=cmd_num+1;
obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s%.3f%s%.3f%s%.3f%s%.3f%s','G0 X',XO,' Y',YO,' Z',LO+Z_Offset,' F',F0,';');
cmd_num=cmd_num+1;
obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G92 X0 Y0 Z0 E0;');
cmd_num=cmd_num+1;
Current_Position = [0, 0, 0, 0, 0, 0];
%   开始循环
for i = 1:length(Trajectory4Print(:,1))
    %Part1：初始化
    Target_Position = Current_Position;%2023-03-06 初始化Target_Position
    Flag_Air_Target = Trajectory4Print(i,13);
    Target_Position(1:2) = [Trajectory4Print(i,6),Trajectory4Print(i,7)];
    Line_Type = Trajectory4Print(i,2);
    %   2022-01-15 气压状态根据Trajectory4Print第13列的标志位确定
    %Part2：气压工作状态确定
    Flage_Change_Air = ~isequal(Flag_Air_Target,Flag_Air_Current);
    if Flage_Change_Air
        switch Flag_Air_Target
            case 1
                obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','M106;');
                cmd_num=cmd_num+1;
            case 0
                obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','M107;');
                cmd_num=cmd_num+1;
            otherwise
                error('气压数据错误')
        end
    end
    Flag_Air_Current = Flag_Air_Target;
    %Part3：点位写入
    %   这部分需要判断线型，若为直线，直接写G01，若是弧线，判断G02还是G03，然后写入
    switch Line_Type
        case 1 %直线
            %   2023-03-06 增加挤出量计算
            Target_Position(4) = Current_Position(4) + 0*norm(Target_Position(1:3)-Current_Position(1:3));
            obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s','G01 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' Z',0,' E',Target_Position(4),' F',F1,';');
            cmd_num=cmd_num+1;
        case 2 %弧线
            isG02 = sign(Trajectory4Print(i,12)-Trajectory4Print(i,11));
            R = Trajectory4Print(i,10);
            %   2023-03-06 增加挤出量计算（半径R×角度变化量=弧长=挤出增加量）
            Target_Position(4) = Current_Position(4) + 0*R * deg2rad(abs(Trajectory4Print(i,12)-Trajectory4Print(i,11)));
            switch isG02
                case 1
                    obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s','G02 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' E',Target_Position(4),' F',F1,';');
                    cmd_num=cmd_num+1;
                case -1
                    obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s','G03 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' E',Target_Position(4),' F',F1,';');
                    cmd_num=cmd_num+1;
                otherwise
                    warn(['弧线错误，跳过第',num2str(i),'行'])
                    continue
            end
        otherwise
            warn(['线型未知，跳过第',num2str(i),'行'])
            continue
    end
    Current_Position = Target_Position;
end
%   后置代码
obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','M107;');
cmd_num=cmd_num+1;
obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G91;');
cmd_num=cmd_num+1;
obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G0 F3000;');
cmd_num=cmd_num+1;
obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G0 Z2;');
cmd_num=cmd_num+1;
obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G90;');
cmd_num=cmd_num+1;
obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G00 X0 Y0;');
cmd_num=cmd_num+1;
%   关闭文件
% fclose(fid);
%%  生成打印Gcode
%   2024-01-27 使用obj = saveCode4Print(obj)生成打印代码
% %   初始化
% Flag_Air_Target= 0;                         %目标气压状态
% Flag_Air_Current = Flag_Air_Target;         %当前气压状态
% Target_Position = zeros(1,2);               %目标位置
% cmd_num = 1;
% %   新建并打开文档
% [pname2] = uigetdir([],'Choose a Path to save GCODE');
% fname2 = 'Gcode4Print.gcode';
% % fname5 = 'Gcode4Print.mat';
% if isequal(fname,0)
%     disp('none');
% else
%     disp(fullfile(pname2,fname2));
% end
% str = [pname2,'\',fname2];
% fid = fopen(str,'w');
% %   前置代码
% fprintf(fid,'%s \n','G28;');
% %   2024-01-26 将代码内容写入类
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G28;');
% cmd_num = cmd_num+1;
% fprintf(fid,'%s \n','G0 F3000;');
% %   2024-01-26 将代码内容写入类
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G0 F3000;');
% cmd_num = cmd_num+1;
% fprintf(fid,'%s \n','G0 Z3.000;');
% %   2024-01-26 将代码内容写入类
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G0 Z3.000;');
% cmd_num=cmd_num+1;
% % fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G0 X',XO,' Y',YO,' Z',LO,' F',F0,';');
% %   2022-01-20 这里应该把F的数值改为整数
% fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G0 X',XO,' Y',YO,' Z',LO,' F',F0,';');
% %   2024-01-26 将代码内容写入类
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s%.3f%s%.3f%s%.3f%s%.3f%s','G0 X',XO,' Y',YO,' Z',LO,' F',F0,';');
% cmd_num=cmd_num+1;
% fprintf(fid,'%s \n','G92 X0 Y0 Z0 E0;');
% %   2024-01-26 将代码内容写入类
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G92 X0 Y0 Z0 E0;');
% cmd_num=cmd_num+1;
% Current_Position = [0, 0, 0, 0, 0];
% %   开始循环
% for i = 1:length(Trajectory4Print(:,1))
%     %Part1：初始化
%     %     Flag_Air_Target = 1;
%     %   2022-01-15 这里修改了一下
%     Target_Position = Current_Position;%2023-03-06 初始化Target_Position
%     Flag_Air_Target = Trajectory4Print(i,13);
%     Target_Position(1:2) = [Trajectory4Print(i,6),Trajectory4Print(i,7)];
%     Line_Type = Trajectory4Print(i,2);
%     %     %   这部分确定气压开关状态是否改变，若改变则进行操作。
%     %     try
%     %         temp_air = Trajectory4Airpressure(find(...
%     %             (Trajectory4Airpressure(i,6)==Target_Position(1))&...
%     %             (Trajectory4Airpressure(i,7)==Target_Position(2))...
%     %             ));
%     %     catch
%     %         Flag_Air_Target = 0;
%     %     end
%     %   2022-01-15 气压状态根据Trajectory4Print第13列的标志位确定，因此不需要这一段了
%     %Part2：气压工作状态确定
%     Flage_Change_Air = ~isequal(Flag_Air_Target,Flag_Air_Current);
%     if Flage_Change_Air
%         switch Flag_Air_Target
%             case 1
%                 fprintf(fid,'%s \n','M106;');
%                 %   2024-01-26 将代码内容写入类
%                 obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','M106;');
%                 cmd_num=cmd_num+1;
%             case 0
%                 fprintf(fid,'%s \n','M107;');
%                 %   2024-01-26 将代码内容写入类
%                 obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','M107;');
%                 cmd_num=cmd_num+1;
%             otherwise
%                 error('气压数据错误')
%         end
%     end
%     Flag_Air_Current = Flag_Air_Target;
%     %Part3：点位写入
%     %   这部分需要判断线型，若为直线，直接写G01，若是弧线，判断G02还是G03，然后写入
%     switch Line_Type
%         case 1 %直线
%             %             fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G01 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' Z',0,' F',F0,';');
%             %             %   2022-01-20 这里应该把F的数值改为整数
%             %             fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%u%s \n','G01 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' Z',0,' F',F0,';');
%             %   2023-03-06 增加挤出量计算
%             Target_Position(4) = Current_Position(4) + 0*norm(Target_Position(1:3)-Current_Position(1:3));
%             fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s \n','G01 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' Z',0,' E',Target_Position(4),' F',F0,';');
%             %   2024-01-26 将代码内容写入类
%             obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s','G01 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' Z',0,' E',Target_Position(4),' F',F0,';');
%             cmd_num=cmd_num+1;
%         case 2 %弧线
%             isG02 = sign(Trajectory4Print(i,12)-Trajectory4Print(i,11));
%             R = Trajectory4Print(i,10);
%             %   2023-03-06 增加挤出量计算（半径R×角度变化量=弧长=挤出增加量）
%             Target_Position(4) = Current_Position(4) + 0*R * deg2rad(abs(Trajectory4Print(i,12)-Trajectory4Print(i,11)));
%             switch isG02
%                 case 1
%                     %                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G02 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' F',F0,';');
%                     %                     %   2022-01-20 这里应该把F的数值改为整数
%                     %                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%u%s \n','G02 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',0,' F',F0,';');
%                     %   2023-03-06 增加挤出量计算
%                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s \n','G02 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' E',Target_Position(4),' F',F0,';');
%                     %   2024-01-26 将代码内容写入类
%                     obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s','G02 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' E',Target_Position(4),' F',F0,';');
%                     cmd_num=cmd_num+1;
%                 case -1
%                     %                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G03 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' F',F0,';');
%                     %                     %   2022-01-20 这里应该把F的数值改为整数
%                     %                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%u%s \n','G03 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' F',F0,';');
%                     %   2023-03-06 增加挤出量计算
%                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s \n','G03 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' E',Target_Position(4),' F',F0,';');
%                     %   2024-01-26 将代码内容写入类
%                     obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s','G03 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' E',Target_Position(4),' F',F0,';');
%                     cmd_num=cmd_num+1;
%                 otherwise
%                     warn(['弧线错误，跳过第',num2str(i),'行'])
%                     continue
%             end
%         otherwise
%             warn(['线型未知，跳过第',num2str(i),'行'])
%             continue
%     end
%     Current_Position = Target_Position;
% end
% %   后置代码
% fprintf(fid,'%s \n','M107;');
% %   2024-01-26 将代码内容写入类
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','M107;');
% cmd_num=cmd_num+1;
% fprintf(fid,'%s \n','G91;');
% %   2024-01-26 将代码内容写入类
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G91;');
% cmd_num=cmd_num+1;
% fprintf(fid,'%s \n','G0 F3000;');
% %   2024-01-26 将代码内容写入类
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G0 F3000;');
% cmd_num=cmd_num+1;
% fprintf(fid,'%s \n','G0 Z2;');
% %   2024-01-26 将代码内容写入类
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G0 Z2;');
% cmd_num=cmd_num+1;
% fprintf(fid,'%s \n','G90;');
% %   2024-01-26 将代码内容写入类
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G90;');
% cmd_num=cmd_num+1;
% fprintf(fid,'%s \n','G00 X0 Y0;');
% %   2024-01-26 将代码内容写入类
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G00 X0 Y0;');
% cmd_num=cmd_num+1;
% %   关闭文件
% fclose(fid);
%%  生成扫描Gcode
%   2022-01-15 更新：
%   结合扫描、密化的路径生成扫描路径矩阵，并把矩阵（工作区变量）保存到指定的路径下，
%   这里有两个思路：
%       （1）在这里直接进行加密处理，需要大幅修改代码，LJ_Control的代码修改较少
%       （2）不使用G代码进行传递，直接使用工作区变量进行传输，好处是减少了本文件和LJ_Control的代码量，
%           坏处是增加了手工编程的难度，未来需要扫描则必须采用DXF→MATALB→Scaner的工作流程
%       权衡利弊后选择第二种方式！
%   便于后续读取和操作。
%       数据格式：
%               参数[ x1,  x2,  x3,  x4,   x5,  x6 ]
%               直线：起X  起Y  终X  终Y   []   []   
%               圆弧：心X  心Y  经R  始θ  终θ []   
% fname4 = 'Gcode4Scan.mat';
% if isequal(fname4,0)
%     disp('none');
% else
%     disp(fullfile(pname2,fname4));
% end
% str = [pname2,'\',fname4];
Z_Value = LO;
F_Value = F2;
% save(str,'Trajectory4Scan','Z_Value','F_Value','XO','YO','Trajectory4Print')
%  2024-01-26 保存dxf到类中
obj.TJ_data.TJ4ZZ = Z_Value;
obj.TJ_data.TJ4FF = F_Value;
%%  结束与标记
obj.syset.flags.read_flag_trajectory = 1;
end