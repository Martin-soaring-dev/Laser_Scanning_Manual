%%  ��ȡDXF�ļ�����Ϣ����ȡ·���㣬������G����
%   �ð汾�������3D��ӡ���Ż�
%   �ڵ���DXF�ļ�ʱ����Ҫע������������Ҫ����λ�����ģ������޷�������ȡ
%   Ϊ�˱��ڴ������Ƕ������£�
%   ��ʵ�߲㣺��ӡ�켣
%   �ߴ��߲㣺��ѹ�����Ĳ���
%   ϸʵ�߲㣺ɨ��켣
%   [ʧЧ]���ӣ�Print_Trajectory_Read_From_DXF_V2_2();
%   ���ӣ�LJ.Trajectory_Extraction_DXF_V2_3_LJ(F0,LO);
%
%   2024-01-26 Martin ��Trajectory_Extraction_DXF_V2_3����LaserScan���У������������
%   1.  ����Ҫ�ı���������LaserScan����
% function Trajectory_Reed_From_DXF_4Print_Scan(XO,YO,LO,F0,XP,YP,XA,YA,XS,YS,X_Offset,Y_Offset,Z_Offset)
function obj = getTrajectory(obj)
%%  ������ϵ�ж�
if obj.syset.flags.read_flag_dxf~=1
    error('.dxf has not loaded yet, please use obj = loadDXF(obj) to load .dxf file first!')
end
%%  ���Բ�����ʼ��
test_a = obj.syset.flags.test_flag_tj;
% test_xyf = 1;
% if test_xyf
%     XO=0;
%     YO=0;
%     XP=0;                   %��ӡ��ʼ��X�����ʱ��һ�α�����õ�
%     YP=0;                   %��ӡ��ʼ��Y�����ʱ��һ�α�����õ�
%     XA=XP;
%     YA=YP;
%     XS=0;                   %ɨ����ʼ��X�����ʱ��һ�α�����õ�
%     YS=0;                   %ɨ����ʼ��X�����ʱ��һ�α�����õ�
%     if ~exist('LO')
%         LO=0.6;
%     end
%     if ~exist('F0')
%         F0=300;             %ɨ����ƶ����� ���ǵ����ԺͶ������͸���ֵ ����ֵ600
%     end
%     F1=1200;                %���г��ƶ����� ���ǵ����ԺͶ������͸���ֵ ����ֵ3000
%     X_Offset=0;
%     Y_Offset=0;
%     Z_Offset=0;
% end
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
X_Offset=obj.Devinfo.printer.printeroffset(1);  % ɨ��������ڴ�ӡ����ƫ�� Xƽ��   mm
Y_Offset=obj.Devinfo.printer.printeroffset(2);  % ɨ��������ڴ�ӡ����ƫ�� Yƽ��   mm
Z_Offset=obj.Devinfo.printer.printeroffset(3);  % ɨ��������ڴ�ӡ����ƫ�� Zƽ��   mm
A_Offset=obj.Devinfo.printer.printeroffset(4);  % ɨ��������ڴ�ӡ����ƫ�� ��X��ת rad
B_Offset=obj.Devinfo.printer.printeroffset(5);  % ɨ��������ڴ�ӡ����ƫ�� ��Y��ת rad
C_Offset=obj.Devinfo.printer.printeroffset(6);  % ɨ��������ڴ�ӡ����ƫ�� ��Z��ת rad
%%  ��ȡDXF�ļ�
%   2024-01-27 ��Ϊ obj = loadDXF(obj) ��ȡ
% [fname,pname] = uigetfile('.dxf','Choose a Path File in .DXF format');
% if isequal(fname,0)
%     disp('none');
% else
%     disp(fullfile(pname,fname));
% end
% str = [pname,'\',fname];
% dxf = DXFtool(str);
% %   2024-01-26 ����dxf������
% obj.TJ_data.dxf = dxf;
%%   ��ʼ������
%   ������ʽ��ÿһ�У�
%   ���      ����          �߲�                 ����[ x1,  x2,  x3,  x4,   x5,  x6]
%   ����      ֱ��:1        '��ʵ�߲�'-��ӡ��1    ֱ�ߣ���X  ��Y  ��X  ��Y   []   []
%             Բ��:2        '�ߴ��߲�'-��ѹ��2    Բ������X  ��Y  ��R  ʼ��  �զ� []
%                           'ϸʵ�߲�'-ɨ�裺3
%                           '�����߲�'-�ܻ���4
%   ��      ����
%   1       ���
%   2       ����
%   3       ͼ��
%   4       ��X
%   5       ��Y
%   6       ��X
%   7       ��Y
%   8       ��X
%   9       ��Y
%   10      ��R
%   11      ʼ��
%   12      �զ�
%   13      ִ�У�����/���ܣ���־λ
%   ��13�������ݴ���������ѹ·�������������Լ���·�����������������
Length = length(obj.TJ_data.dxf.entities);
Trajectory               = zeros(Length,12);
Trajectory4Print         = [];
Trajectory4Airpressure   = [];
Trajectory4Scan          = [];
%%  ��ȡ������������
for i = 1:Length
    Layer = obj.TJ_data.dxf.entities(i).layer;
    switch Layer
        case '��ʵ�߲�'
            Layer = 1;
        case '�ߴ��߲�'
            Layer = 2;
        case 'ϸʵ�߲�'
            Layer = 3;
        case '�����߲�'
            Layer = 4;
        otherwise
            warning(['���ڱ�׼��ʽ������ͣ�',Layer,'���������Ѻ��ԣ�����ȷ��'])
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

%   �Ѽ��㻡�ߵ���ֹ�㲢��ֵ
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
%   ���ɴ�ӡ����ѹ��ɨ�衢�ܻ�·��
Trajectory4Print         = Trajectory(find(Trajectory(:,3)==1),:);
Trajectory4Airpressure   = Trajectory(find(Trajectory(:,3)==2),:);
Trajectory4Scan          = Trajectory(find(Trajectory(:,3)==3),:);
Trajectory4Interpolation = Trajectory(find(Trajectory(:,3)==4),:);
%%  �ҵ���β����������������������
%   2022-01-14 ����
%   �������ȷֱ𽫴�ӡ����ѹ��ɨ�衢�ܻ���·����������
%   Ȼ���ϴ�ӡ����ѹ·�����ɴ�ӡG����
%   ���Ž��ɨ�衢�ܻ���·������ɨ��·�����󣬲��Ѿ��󣨹��������������浽ָ����·���£�
%   ���ں�����ȡ�Ͳ�����
%       ���ݸ�ʽ��
%               ����[ x1,  x2,  x3,  x4,   x5,  x6,  x7]
%               ֱ�ߣ���X  ��Y  ��X  ��Y   []   []   �ܻ���ʶ
%               Բ������X  ��Y  ��R  ʼ��  �զ� []   �ܻ���ʶ
%
%   ��Ҫָ�����ǣ���ӡ·����ɨ��·����Ҫ�������ġ�
%   ����ѹ���ܻ���·���������������
%   �ʹ�ӡ/ɨ��·������β������������������·���ϵ���û�ж˵��غ�
%       �����Ҫ����Ӧ���߼��жϣ�
%           �Դ�ӡΪ����
%               �ڴ�ӡ·���㣬 ͨ����ʼ��A�ҵ����߶�L1����������ֹ��B��
%               ����ѹ·���㣬 ������㡢�յ㵽�߶�AB����Ϊ����߶�L2��
%                             ����L2�Ͼ���A������Ķ˵�C���ͽ�Զ��D��
%               switch [A==C D==B]
%                   case [0 0]
%                       д�룺
%                       ���      �յ�      ��ѹ������ʶ
%                       A         C         0
%                       C         D         1
%                       D         B         0
%                   case [0 1]
%                       д�룺
%                       ���      �յ�      ��ѹ������ʶ
%                       A         C         0
%                       C         B         1
%                   case [1 0]
%                       ���      �յ�      ��ѹ������ʶ
%                       A         D         1
%                       D         B         0
%                   case [0 0]
%                       ���      �յ�      ��ѹ������ʶ
%                       A         B         1
%               end
%%   �Դ�ӡ·������
%   2022-01-14 ����
%   �����������д���Ӷ�ʵ���µĹ������̣�����ʶ����ֹ�����ݡ�G����
%   ��Ҫ����Ӧ���߼��жϣ�
%           �Դ�ӡΪ����
%               �ڴ�ӡ·���㣬 ͨ����ʼ��A�ҵ����߶�L1����������ֹ��B��
%               ����ѹ·���㣬 ������㡢�յ㵽�߶�AB����Ϊ����߶�L2��
%                             ����L2�Ͼ���A������Ķ˵�C���ͽ�Զ��D��
%               switch [A==C D==B]
%                   case [0 0]
%                       ���      �յ�      ��ѹ������ʶ
%                       A         C         0
%                       C         D         1
%                       D         B         0
%                   case [0 1]
%                       ���      �յ�      ��ѹ������ʶ
%                       A         C         0
%                       C         B         1
%                   case [1 0]
%                       ���      �յ�      ��ѹ������ʶ
%                       A         D         1
%                       D         B         0
%                   case [0 0]
%                       ���      �յ�      ��ѹ������ʶ
%                       A         B         1
%               end
%   ����ӡ·����ֵ����ʱ��������������Ա���TEMP_Trajectory���в������Ӷ������Դ���ݲ���������ݶ�ʧ
TEMP_Trajectory = Trajectory4Print;
%   ����һ�У���ţ���ȫ����Ϊ0�����������¸�ֵ
TEMP_Trajectory(:,1)=0;
%   �����趨����ʼ�㣨Ĭ��Ϊ[0,0]�����ҵ�һ���߶�
temp0 = find((TEMP_Trajectory(:,4)==XP) & (TEMP_Trajectory(:,5)==YP));
%   ����һ���߶ε������Ϊ1
TEMP_Trajectory(temp0,1)=1;
%   ����һ���߶ε��յ����긳ֵ����ʱ���������ڲ��ҵڶ����߶Σ�����ʼѭ��
X2_TEMP = TEMP_Trajectory(temp0,6);
Y2_TEMP = TEMP_Trajectory(temp0,7);
for i = 2:length(TEMP_Trajectory(:,1))
    %   ���Ҷ˵㺬���ϸ��߶��յ���߶�
    temp = find((TEMP_Trajectory(:,4)==X2_TEMP) & (TEMP_Trajectory(:,5)==Y2_TEMP));
    if isempty(temp)
        %   ���鲻������������Ϊ��ͼʱ�����������ˣ�������ֹ��������
        tempr = find((TEMP_Trajectory(:,6)==X2_TEMP) & (TEMP_Trajectory(:,7)==Y2_TEMP));
        %   ��ʱ����Ҫע�⣬��Ҫ�ų���һ���߶ε���ֹ��
        tempr(find(tempr==temp0))=[];
        if isempty(tempr)
            error('�޷��ҵ���һ�㣡')
        else
            %   ��������Ҫ�Ѹ��߶ε���ֹ��Ե���������Ҫ�ж�������
            %             for j=1:length(tempr)
            %   ����ҵ��˶�������������߶Σ�����Ӧѭ��ִ�У�
            %   ÿ�ζ�ȡ��һ���������������Ҫ�Ͱ�����ɾ�ˣ����������Ҫ��ֹͣ����
            %   �ѵ�һ�����ݶ�Ӧ�����Ͷ�ȡ����
            %   2022-01-14 ����
            %   �����޸����߼���Ӧ�����ȶ�ÿһ�����ݽ��в����������������������������������������Ϊ0
            %   �������ˣ��ٰ�����Ϊ0�ģ�ȫ��ɾ����
            %   ����֮�������ʣ�������ݣ�ֻȡ��һ��
            %                 flag_line_type = TEMP_Trajectory(tempr(1),2);
            %   ���ȰѲ����Ϲ涨���͵�����ɾ��
            for j=1:length(tempr)
                flag_line_type = TEMP_Trajectory(tempr(j),2);
                %   ��ȡ���ͣ������ǹ涨����������Ϊ0
                switch flag_line_type
                    case 1  %   ֱ�ߣ�������
                    case 2  %   Բ����������
                    otherwise % ��������Ϊ0
                        flag_line_type(j)=0;
                end
                temp(find(flag_line_type==0))=[];
                %   ����Ӧ������ɾ��
            end

            %   ɾ�����ж�һ�»���û��ʣ��ĵ㣬���û���򱨴�
            if isempty(tempr)
                error('�޷��ҵ���һ�㣡')
            end

            %   ���ʣ�������ݣ����ж��Ƿ��ж��飬����ж��飬��ֻȡ��һ����������
            if length(tempr)>1
                warning(['���ҵ�����߶Σ�ֻȡ�׸����������ģ�'])
                tempr = tempr(1);
            end

            %   Ȼ�󽫸������ݽ�����ֹ��Ե�
            flag_line_type = TEMP_Trajectory(tempr,2);
            switch flag_line_type
                case 1  %   ֱ�ߣ�
                    %                         tempr(1)=tempr;
                    temp1 = TEMP_Trajectory(tempr,4);
                    temp2 = TEMP_Trajectory(tempr,5);
                    TEMP_Trajectory(tempr,4) = TEMP_Trajectory(tempr,6);
                    TEMP_Trajectory(tempr,5) = TEMP_Trajectory(tempr,7);
                    TEMP_Trajectory(tempr,6) = temp1;
                    TEMP_Trajectory(tempr,7) = temp2;
                case 2  %   Բ��
                    %                         tempr(1)=tempr;
                    %   2022-01-14 ����
                    %   ֮ǰд�Ĳ��ԣ�������һ��
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

            %   ��������֮�󣬰�tempr���¸�ֵ��temp������߶εߵ��Ĵ���
            temp = tempr;
            %             end
        end
    else
        %   temp�ǿ�ʱ����Ҫ�ų�һ�����ʹ����Ӱ��
        flag_line_type = TEMP_Trajectory(temp,2);
        for j=1:length(temp)
            flag_line_type = TEMP_Trajectory(temp(j),2);
            %   ��ȡ���ͣ������ǹ涨����������Ϊ0
            switch flag_line_type
                case 1  %   ֱ�ߣ�������
                case 2  %   Բ����������
                otherwise % ��������Ϊ0
                    flag_line_type(j)=0;
            end
        end
        temp(find(flag_line_type==0))=[];
        %   ����Ӧ������ɾ��
        %   ��ʱ�������ֹһ��temp����Ҫ�������棬����ֻȡ�׸�temp
        if length(temp)>1
            warning(['���ҵ�����߶Σ�ֻȡ�׸����������ģ�'])
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
%%   ����ѹ·������
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
%             error('�޷��ҵ���һ�㣡')
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
%                     error('�޷��ҵ���һ�㣡')
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
%   2022-01-14 ����
%               �ڴ�ӡ·���㣬 ͨ����ʼ��A�ҵ����߶�L1����������ֹ��B��
%               ����ѹ·���㣬 ������㡢�յ㵽�߶�AB����Ϊ����߶�L2��
%                             ����L2�Ͼ���A������Ķ˵�C���ͽ�Զ��D��
%               switch [A==C D==B]
%                   case [0 0]
%                       ���      �յ�      ��ѹ������ʶ
%                       A         C         0
%                       C         D         1
%                       D         B         0
%                   case [0 1]
%                       ���      �յ�      ��ѹ������ʶ
%                       A         C         0
%                       C         B         1
%                   case [1 0]
%                       ���      �յ�      ��ѹ������ʶ
%                       A         D         1
%                       D         B         0
%                   case [0 0]
%                       ���      �յ�      ��ѹ������ʶ
%                       A         B         1
%               end
%   �µ�˼·�ǶԴ�ӡ·�����ж�ȡ���ж��Ƿ���Ҫ���߶��в�����ѹ��������
%   ����ѹ·����ֵ����ʱ��������������Ա���TEMP_Execution, TEMP_Trajectory���в������Ӷ������Դ���ݲ���������ݶ�ʧ
TEMP_Execution  = Trajectory4Airpressure;
TEMP_Trajectory = [Trajectory4Print,zeros(size(Trajectory4Print,1),1)];%��Trajectory4Print�����һ�б�־λ��ȫ��Ϊ0
%   ��TEMP_Trajectory������Ѱ���غϵ�TEMP_Execution�Σ������뵽TEMP_Trajectory��
L = size(TEMP_Trajectory,1);
for i = 1:L
    %   ����ѭ���л�����У���Ҫ���յ�һ�У���ţ������Ҷ�Ӧ����
    temp_Current_Tra = find(TEMP_Trajectory(:,1)==i);
    switch TEMP_Trajectory(temp_Current_Tra,2)
        case 1  %   ֱ�ߣ���Ҫ�жϣ��ٳ�ɸ���߶������Ƿ�һ�£�����ֹ���Ƿ�λ��AB�ϼ���
            %   ������ֹ��Ȧ���ķ�ΧѰ���߶γ�ɸ����ͨ�������жϡ��غ��жϾ�ɸ���뵱ǰ�߶��غϵ��߶Ρ�
            %Step1����Χɸѡ
            %   ��ȡ��ǰ�е���ʼ��A����ֹ��B
            X_A_TEMP = TEMP_Trajectory(temp_Current_Tra,4);
            Y_A_TEMP = TEMP_Trajectory(temp_Current_Tra,5);
            X_B_TEMP = TEMP_Trajectory(temp_Current_Tra,6);
            Y_B_TEMP = TEMP_Trajectory(temp_Current_Tra,7);
            %   ��TEMP_Execution�в�����AB���ɵľ��������ڵ��߶�
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
            %   ����Ȧ����Χ���Ҳ����������¸��߶�
            if isempty(temp0)
                continue
            end
            %Step2������ɸѡ
            %   ��������Ϊֱ�ߵ��߶�
            temp0 = temp0(find(TEMP_Execution(temp0,2)==1));
            %   �����Ҳ����������¸��߶�
            if isempty(temp0)
                continue
            end
            %Step3�����ι�ϵɸѡ
            %   �жϲ��ҵ����߶εĶ˵��Ƿ��ڵ�ǰ�߶���
            %       ��ȡ���е���ֹ��
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
            %   �����Ҳ����������¸��߶�
            if isempty(temp0)
                continue
            else
                %   ��ɸѡ���غϵ��߶Σ����ж�temp0Ԫ��������������1�򾯸沢ֻȡ��һ��
                if length(temp0)>1
                    warning('�����غ��߶Σ�ֻȡ��һ���غϵ�')
                    temp0=temp0(1);
                end
            end

            %Step4������
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
            %   ��CD���ȵ���0�������¸��߶�
            if flag_CeqD
                continue
            end
            %   ��CD��Ҫ�Ե�������жԵ�
            if flag_CecD
                %   ���Ƚ��жԵ�
                temp1 = TEMP_Execution(temp0,4);
                temp2 = TEMP_Execution(temp0,5);
                TEMP_Execution(temp0,4) = TEMP_Execution(temp0,6);
                TEMP_Execution(temp0,5) = TEMP_Execution(temp0,7);
                TEMP_Execution(temp0,6) = temp1;
                TEMP_Execution(temp0,7) = temp2;
                %   �������¼�����ر���
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

            %Step5������
            %               switch [A==C D==B]
            %                   case [1 1]
            %                       ���      �յ�      ��ѹ������ʶ
            %                       A         C         0
            %                       C         D         1
            %                       D         B         0
            %                   case [0 1]
            %                       ���      �յ�      ��ѹ������ʶ
            %                       A         C         0
            %                       C         B         1
            %                   case [1 0]
            %                       ���      �յ�      ��ѹ������ʶ
            %                       A         D         1
            %                       D         B         0
            %                   case [0 0]
            %                       ���      �յ�      ��ѹ������ʶ
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
                    %   ������ʱ����
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp5 = [TEMP_Execution(temp0,:),0];
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   ���Ϊi�������յ��ΪC
                    temp3(end,6) = X_C_TEMP;
                    temp3(end,7) = Y_C_TEMP;
                    %   ��ӵĶΣ�����ִ�б�־λ��Ϊ1
                    temp5(1,13)= 1;
                    temp5(1, 1)= 0;
                    %   ��ȡԭ�����Ϊi������ʼ���ΪD����д��������
                    temp6(1,4) = X_D_TEMP;
                    temp6(1,5) = Y_D_TEMP;
                    temp6(1,1) = 0;
                    %   �ѽ�ȡ�ĺ��������ճ���ϣ�����ֵ��TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp5;temp6;temp4];
                case 2 %[0,1]
                    %   ������ʱ����
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   ���Ϊi�������յ��ΪC
                    temp3(end,6) = X_D_TEMP;
                    temp3(end,7) = Y_D_TEMP;
                    temp3(end,13)= 1;
                    %   ��ȡԭ�����Ϊi������ʼ���ΪC������ִ�б�־λ��Ϊ1����д��������
                    temp6(1,4) = X_D_TEMP;
                    temp6(1,5) = Y_D_TEMP;
                    temp6(1,1) = 0;
                    temp6(1,13)= 0;
                    %   �ѽ�ȡ�ĺ��������ճ���ϣ�����ֵ��TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp6;temp4];
                case 3 %[1,0]
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   ���Ϊi�������յ��ΪC
                    temp3(end,6) = X_C_TEMP;
                    temp3(end,7) = Y_C_TEMP;
                    temp3(end,13)= 0;
                    %   ��ȡԭ�����Ϊi������ʼ���ΪD����д��������
                    temp6(1,4) = X_C_TEMP;
                    temp6(1,5) = Y_C_TEMP;
                    temp6(1,1) = 0;
                    temp6(1,13)= 1;
                    %   �ѽ�ȡ�ĺ��������ճ���ϣ�����ֵ��TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp6;temp4];
                case 4 %[0,0]
                    %   ������ʱ����
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    %   ���Ϊi���а�ִ�б�־λ��Ϊ1
                    temp3(end,13) = 1;
                    %   �ѽ�ȡ�ĺ��������ճ���ϣ�����ֵ��TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp4];
            end
        case 2  %   Բ������Ҫ�жϣ������͡�Բ������R���뾶�Ƿ�һ�£�����ֹ�Ƕ��Ƿ��ڷ�Χ��
            %   ����ͨ�����͡�Բ��λ�á��뾶���г�ɸ����ͨ��Բ���Ƕȷ�Χ���о�ɸ��
            %Step1������ɸѡ
            temp0 = find(TEMP_Execution(:,2)==2);
            %   �����Ҳ����������¸��߶�
            if isempty(temp0)
                continue
            end

            %Step2��Բ��λ��ɸѡ
            %   ��ȡ��ǰԲ����Բ��A���뾶R����ֹ�Ƕ�
            X_A_TEMP = TEMP_Trajectory(temp_Current_Tra,8);
            Y_A_TEMP = TEMP_Trajectory(temp_Current_Tra,9);
            R_A_TEMP = TEMP_Trajectory(temp_Current_Tra,10);
            PhiATEMP = TEMP_Trajectory(temp_Current_Tra,11);
            PhiBTEMP = TEMP_Trajectory(temp_Current_Tra,12);
            %   ��TEMP_Execution�в���Բ����A���Բ��
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
            %   �����Ҳ����������¸��߶�
            if isempty(temp0)
                continue
            end

            %Step3�����뾶ɸѡ
            R_B_TEMP = TEMP_Execution(temp0,10);
            error1 = round((R_B_TEMP-R_A_TEMP)*1e3);
            temp0 = temp0(find(error1==0));
            %   �����Ҳ����������¸��߶�
            if isempty(temp0)
                continue
            end

%             %Step4�����Ƕȷ�Χɸѡ
%             %   ��Ҫע��һ�����⣬�Ƕ��Ƿ����㣡
%             %   ������Լ�Ϊ�ǶȲ�����180��Ķ̻��������Բ��
%             %   ��ˣ�������Ҫȷ���Ƕȵı�ʾ���⡣
% %             %   ������Ϊ��ʱ�뷽��
% %             if PhiATEMP<PhiBTEMP
% %                 DeltaPhi = PhiBTEMP - PhiATEMP;
% %                 if abs(DeltaPhi)<180
% %                     %   PhiB > PhiA��������Ϊ�ӻ������账��
% %                 elseif abs(deltaPhi>180
% %                     %   PhiB > PhiA���淽��Ϊ�ӻ���PhiB-360��
% %                     PhiBTEMP = PhiBTEMP - 360;
% %                 else
% %                     error('����180��Բ�����޷����㣡')
% %                 end
% %             elseif PhiATEMP>PhiBTEMP
% %                 DeltaPhi = PhiBTEMP - PhiATEMP;
% %                 if abs(DeltaPhi)<180
% %                     %   PhiB > PhiA���淽��Ϊ�ӻ������账��
% %                 elseif abs(deltaPhi>180
% %                     %   PhiB < PhiA��������Ϊ�ӻ���PhiA+360��
% %                     PhiATEMP = PhiATEMP - 360;
% %                 else
% %                     error('����180��Բ�����޷����㣡')
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
%             %   ���ڽǶȲ���PhiA��PhiB��Χ���Ҳ����������¸��߶�
%             if isempty(temp0)
%                 continue
%             end

            %Step5����Χ�ж������
            PhiCTEMP = TEMP_Execution(temp0,11);
            PhiDTEMP = TEMP_Execution(temp0,12);
            ArcAB = PhiBTEMP-PhiATEMP;
            ArcAC = PhiCTEMP-PhiATEMP;
            ArcAD = PhiDTEMP-PhiATEMP;
            if ArcAB == 0
                continue
            end
            %��Χ�ж�
            %   �е㸴�ӣ�������Ϊ��ʱ��
            %   PhiA<PhiBʱ
            %       PhiA�� (0,180)ʱ
            %           PhiB �� (PhiA,PhiA+180)ʱ��A��B����������(PhiA,PhiB)
            %           PhiB �� (PhiA+180,360 )ʱ��A��B�淽������(PhiB,360)|(0,PhiA)
            %       PhiA�� (180��360)ʱ
            %           PhiB �� (PhiA,360)     ʱ��A��B����������(PhiA,PhiB)
            %   PhiA>PhiBʱ
            %       PhiA�� (0,180)ʱ
            %           PhiB �� (0,PhiA)       ʱ��A��B�淽������(PhiB,PhiA)
            %       PhiA�� (180��360)ʱ
            %           PhiB �� (0,PhiA-180)   ʱ��A��B����������(PhiA,360)|(0,PhiB)
            %           PhiB �� (PhiA-180,PhiA)ʱ��A��B�淽������(PhiB,PhiA)
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
                %�����ڲ��ڷ�Χ�ڵĵ㣬������
                if (flag_C==0)||(flag_D==0)
                    temp(j)=0;                    
                end
            end
            temp0(find(temp0==0));
            %   �����Ҳ����������¸��߶�
            if isempty(temp0)
                continue
            end
            %����
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
                                %�������
                            elseif (PhiCTEMP>=PhiBTEMP)&&(PhiCTEMP<360)
                                PhiCTEMP = PhiCTEMP-360;
                            end
                            if (PhiDTEMP>=0)&&(PhiDTEMP<=PhiATEMP)
                                %�������
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
                                %�������
                            elseif (PhiCTEMP>=0)&&(PhiCTEMP<=PhiBTEMP)
                                PhiCTEMP = PhiCTEMP+360;
                            end
                            if (PhiDTEMP>=PhiATEMP)&&(PhiDTEMP<360)
                                %�������
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
                    case 1 %C��D��A��B����һ�£����趯��
                    case 0 %C=D��������һ��
                        temp0(j)=0;
                    case -1%D��C����Ҫ����˳��
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
%                     case 1 %C��D��A��B����һ�£����趯��
%                     case 0 %C=D��������һ��
%                         temp0(j)=0;
%                     case -1%D��C����Ҫ����˳��
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
            %   ���temp0�е���0��Ԫ��
            temp0(find(temp0)==0)=[];
            %   ��PhiΪ�գ������¸��߶�
            if isempty(temp0)
                continue
            end

            %Step6������
                %   ���ж��temp0��ֻȡ��һ��
                temp0=temp0(1);
                %   ���¼�����ر���
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
            %                       ���      �յ�      ��ѹ������ʶ
            %                       A         C         0
            %                       C         D         1
            %                       D         B         0
            %                   case [0 1]
            %                       ���      �յ�      ��ѹ������ʶ
            %                       A         C         0
            %                       C         B         1
            %                   case [1 0]
            %                       ���      �յ�      ��ѹ������ʶ
            %                       A         D         1
            %                       D         B         0
            %                   case [0 0]
            %                       ���      �յ�      ��ѹ������ʶ
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
            %       SN  LT  LN  X1  Y1  X2  Y2  Xc  Yc  R   ��1 ��1 flag
            %       ��֪AB��CD�������������������ۣ�
            %       case 1 A����C����D����B��
            %       case 2 A����C����B��D����
            %       case 3 A��C������D����B��
            %       case 4 A����B��
            switch flag
                case 1 %[1,1]
                    %   ������ʱ����
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp5 = [TEMP_Execution(temp0,:),0];
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   ���Ϊi�������յ������ͽǶȸ�ΪC
                    temp3(end,6) = TEMP_Execution(temp0,4);
                    temp3(end,7) = TEMP_Execution(temp0,5);
                    temp3(end,12)= TEMP_Execution(temp0,11);
                    %   ��ӵĶΣ�����ִ�б�־λ��Ϊ1
                    temp5(1,13)= 1;
                    temp5(1, 1)= 0;
                    %   ��ȡԭ�����Ϊi������ʼ�����ꡢ�Ƕȸ�ΪD����д��������
                    temp6(1,4) = TEMP_Execution(temp0,6);
                    temp6(1,5) = TEMP_Execution(temp0,7);
                    temp6(1,11)= TEMP_Execution(temp0,12);
                    temp6(1,1) = 0;
                    %   �ѽ�ȡ�ĺ��������ճ���ϣ�����ֵ��TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp5;temp6;temp4];
                case 2 %[0,1]                    
                    %   ������ʱ����
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   ���Ϊi�������յ������ͽǶȸ�ΪC
                    temp3(end,6) = TEMP_Execution(temp0,6);
                    temp3(end,7) = TEMP_Execution(temp0,7);
                    temp3(end,12)= TEMP_Execution(temp0,12);
                    temp3(end,13)= 1;
                    %   ��ȡԭ�����Ϊi������ʼ�����ꡢ�Ƕȸ�ΪC����д��������
                    temp6(1,4) = TEMP_Execution(temp0,6);
                    temp6(1,5) = TEMP_Execution(temp0,7);
                    temp6(1,11)= TEMP_Execution(temp0,12);
                    temp6(1,1) = 0;
                    temp6(1,13)= 0;
                    %   �ѽ�ȡ�ĺ��������ճ���ϣ�����ֵ��TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp6;temp4];
                case 3 %[1,0]
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   ���Ϊi�������յ������ͽǶȸ�ΪD
                    temp3(end,6) = TEMP_Execution(temp0,4);
                    temp3(end,7) = TEMP_Execution(temp0,5);
                    temp3(end,12)= TEMP_Execution(temp0,11);
                    temp3(end,13)= 0;
                    %   ��ȡԭ�����Ϊi������ʼ�����ꡢ�Ƕȸ�ΪD����д��������
                    temp6(1,4) = TEMP_Execution(temp0,4);
                    temp6(1,5) = TEMP_Execution(temp0,5);
                    temp6(1,11)= TEMP_Execution(temp0,11);
                    temp6(1,1) = 0;
                    temp6(1,13)= 1;
                    %   �ѽ�ȡ�ĺ��������ճ���ϣ�����ֵ��TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp6;temp4];
                case 4 %[0,0]
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp3(end,13)= 1;
                    %   �ѽ�ȡ�ĺ��������ճ���ϣ�����ֵ��TEMP_Trajectory
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
%   2024-02-15 ���ӵ�14��-��𣬷�������켣�Ա�
Trajectory4Print(:,14)=0; %�ȳ�ʼ��Ϊ0
p_delta = Trajectory4Print(2:end,13)-Trajectory4Print(1:end-1,13); %��ȡ�����仯�����
p_start = find(p_delta==1); %�ҵ�ÿһ�����ֹ�㣬����������������ģ�����p_deltaֻ��n-1�������p_start��ʵ�ʵ�С1
p_end = find(p_delta==-1); %p_end��ʾ��һ����1����һ����0����Ҫ-1��������һ�е�����Ҫ+1����������˲���Ҫ������
if length(p_start)==length(p_end)

elseif Trajectory4Print(end,13)==1 & length(p_start)-length(p_end)==1
    p_end(end+1)=size(Trajectory4Print,1);
else
    error('��ѹ��ֹ������һ�£�����·���ļ�')
end
for i=1:length(p_start)
    Trajectory4Print(p_start(i):p_end(i),14)=i;
end

%%   ��ɨ��·������
%   2022-01-14 ����
%   �����������д���Ӷ�ʵ���µĹ������̣�����ʶ����ֹ�����ݡ�G����
%   ��Ҫ����Ӧ���߼��жϣ�
%           �Դ�ӡΪ����
%               �ڴ�ӡ·���㣬 ͨ����ʼ��A�ҵ����߶�L1����������ֹ��B��
%               ����ѹ·���㣬 ������㡢�յ㵽�߶�AB����Ϊ����߶�L2��
%                             ����L2�Ͼ���A������Ķ˵�C���ͽ�Զ��D��
%               switch [A==C D==B]
%                   case [0 0]
%                       ���      �յ�      �ܻ�������ʶ
%                       A         C         0
%                       C         D         1
%                       D         B         0
%                   case [0 1]
%                       ���      �յ�      �ܻ�������ʶ
%                       A         C         0
%                       C         B         1
%                   case [1 0]
%                       ���      �յ�      �ܻ�������ʶ
%                       A         D         1
%                       D         B         0
%                   case [0 0]
%                       ���      �յ�      �ܻ�������ʶ
%                       A         B         1
%               end
%   ����ӡ·����ֵ����ʱ��������������Ա���TEMP_Trajectory���в������Ӷ������Դ���ݲ���������ݶ�ʧ
TEMP_Trajectory = Trajectory4Scan;
%   ����һ�У���ţ���ȫ����Ϊ0�����������¸�ֵ
TEMP_Trajectory(:,1)=0;
%   �����趨����ʼ�㣨Ĭ��Ϊ[0,0]�����ҵ�һ���߶�
temp0 = find((TEMP_Trajectory(:,4)==XS) & (TEMP_Trajectory(:,5)==YS));
%   ����һ���߶ε������Ϊ1
TEMP_Trajectory(temp0,1)=1;
%   ����һ���߶ε��յ����긳ֵ����ʱ���������ڲ��ҵڶ����߶Σ�����ʼѭ��
X2_TEMP = TEMP_Trajectory(temp0,6);
Y2_TEMP = TEMP_Trajectory(temp0,7);
for i = 2:length(TEMP_Trajectory(:,1))
    %   ���Ҷ˵㺬���ϸ��߶��յ���߶�
    temp = find((TEMP_Trajectory(:,4)==X2_TEMP) & (TEMP_Trajectory(:,5)==Y2_TEMP));
    if isempty(temp)
        %   ���鲻������������Ϊ��ͼʱ�����������ˣ�������ֹ��������
        tempr = find((TEMP_Trajectory(:,6)==X2_TEMP) & (TEMP_Trajectory(:,7)==Y2_TEMP));
        %   ��ʱ����Ҫע�⣬��Ҫ�ų���һ���߶ε���ֹ��
        tempr(find(tempr==temp0))=[];
        if isempty(tempr)
            error('�޷��ҵ���һ�㣡')
        else
            %   ��������Ҫ�Ѹ��߶ε���ֹ��Ե���������Ҫ�ж�������
            %             for j=1:length(tempr)
            %   ����ҵ��˶�������������߶Σ�����Ӧѭ��ִ�У�
            %   ÿ�ζ�ȡ��һ���������������Ҫ�Ͱ�����ɾ�ˣ����������Ҫ��ֹͣ����
            %   �ѵ�һ�����ݶ�Ӧ�����Ͷ�ȡ����
            %   2022-01-14 ����
            %   �����޸����߼���Ӧ�����ȶ�ÿһ�����ݽ��в����������������������������������������Ϊ0
            %   �������ˣ��ٰ�����Ϊ0�ģ�ȫ��ɾ����
            %   ����֮�������ʣ�������ݣ�ֻȡ��һ��
            %                 flag_line_type = TEMP_Trajectory(tempr(1),2);
            %   ���ȰѲ����Ϲ涨���͵�����ɾ��
            for j=1:length(tempr)
                flag_line_type = TEMP_Trajectory(tempr(j),2);
                %   ��ȡ���ͣ������ǹ涨����������Ϊ0
                switch flag_line_type
                    case 1  %   ֱ�ߣ�������
                    case 2  %   Բ����������
                    otherwise % ��������Ϊ0
                        flag_line_type(j)=0;
                end
                temp(find(flag_line_type==0))=[];
                %   ����Ӧ������ɾ��
            end
            %   ɾ�����ж�һ�»���û��ʣ��ĵ㣬���û���򱨴�
            if isempty(tempr)
                error('�޷��ҵ���һ�㣡')
            end

            %   ���ʣ�������ݣ����ж��Ƿ��ж��飬����ж��飬��ֻȡ��һ����������
            if length(tempr)>1
                warning(['���ҵ�����߶Σ�ֻȡ�׸����������ģ�'])
                tempr = tempr(1);
            end

            %   Ȼ�󽫸������ݽ�����ֹ��Ե�
            flag_line_type = TEMP_Trajectory(tempr,2);
            switch flag_line_type
                case 1  %   ֱ�ߣ�
                    %                         tempr(1)=tempr;
                    temp1 = TEMP_Trajectory(tempr,4);
                    temp2 = TEMP_Trajectory(tempr,5);
                    TEMP_Trajectory(tempr,4) = TEMP_Trajectory(tempr,6);
                    TEMP_Trajectory(tempr,5) = TEMP_Trajectory(tempr,7);
                    TEMP_Trajectory(tempr,6) = temp1;
                    TEMP_Trajectory(tempr,7) = temp2;
                case 2  %   Բ��
                    %                         tempr(1)=tempr;
                    %   2022-01-14 ����
                    %   ֮ǰд�Ĳ��ԣ�������һ��
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

            %   ��������֮�󣬰�tempr���¸�ֵ��temp������߶εߵ��Ĵ���
            temp = tempr;
            %             end
        end
    else
        %   temp�ǿ�ʱ����Ҫ�ų�һ�����ʹ����Ӱ��
        flag_line_type = TEMP_Trajectory(temp,2);
        for j=1:length(temp)
            flag_line_type = TEMP_Trajectory(temp(j),2);
            %   ��ȡ���ͣ������ǹ涨����������Ϊ0
            switch flag_line_type
                case 1  %   ֱ�ߣ�������
                case 2  %   Բ����������
                otherwise % ��������Ϊ0
                    flag_line_type(j)=0;
            end
        end
        temp(find(flag_line_type==0))=[];
        %   ����Ӧ������ɾ��
        %   ��ʱ�������ֹһ��temp����Ҫ�������棬����ֻȡ�׸�temp
        if length(temp)>1
            warning(['���ҵ�����߶Σ�ֻȡ�׸����������ģ�'])
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
%%   ���ܻ�·������
%   ���ݡ�����ѹ·������������΢��
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
%             error('�޷��ҵ���һ�㣡')
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
%                     error('�޷��ҵ���һ�㣡')
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
%   2022-01-14 ����
%               �ڴ�ӡ·���㣬 ͨ����ʼ��A�ҵ����߶�L1����������ֹ��B��
%               ����ѹ·���㣬 ������㡢�յ㵽�߶�AB����Ϊ����߶�L2��
%                             ����L2�Ͼ���A������Ķ˵�C���ͽ�Զ��D��
%               switch [A==C D==B]
%                   case [0 0]
%                       ���      �յ�      ��ѹ������ʶ
%                       A         C         0
%                       C         D         1
%                       D         B         0
%                   case [0 1]
%                       ���      �յ�      ��ѹ������ʶ
%                       A         C         0
%                       C         B         1
%                   case [1 0]
%                       ���      �յ�      ��ѹ������ʶ
%                       A         D         1
%                       D         B         0
%                   case [0 0]
%                       ���      �յ�      ��ѹ������ʶ
%                       A         B         1
%               end
%   �µ�˼·�ǶԴ�ӡ·�����ж�ȡ���ж��Ƿ���Ҫ���߶��в�����ѹ��������
%   ����ѹ·����ֵ����ʱ��������������Ա���TEMP_Execution, TEMP_Trajectory���в������Ӷ������Դ���ݲ���������ݶ�ʧ
TEMP_Execution  = Trajectory4Interpolation;
TEMP_Trajectory = [Trajectory4Scan,zeros(size(Trajectory4Scan,1),1)];%��Trajectory4Scan�����һ�б�־λ��ȫ��Ϊ0
%   ��TEMP_Trajectory������Ѱ���غϵ�TEMP_Execution�Σ������뵽TEMP_Trajectory��
L = size(TEMP_Trajectory,1);
for i = 1:L
    %   ����ѭ���л�����У���Ҫ���յ�һ�У���ţ������Ҷ�Ӧ����
    temp_Current_Tra = find(TEMP_Trajectory(:,1)==i);
    switch TEMP_Trajectory(temp_Current_Tra,2)
        case 1  %   ֱ�ߣ���Ҫ�жϣ��ٳ�ɸ���߶������Ƿ�һ�£�����ֹ���Ƿ�λ��AB�ϼ���
            %   ������ֹ��Ȧ���ķ�ΧѰ���߶γ�ɸ����ͨ�������жϡ��غ��жϾ�ɸ���뵱ǰ�߶��غϵ��߶Ρ�
            %Step1����Χɸѡ
            %   ��ȡ��ǰ�е���ʼ��A����ֹ��B
            X_A_TEMP = TEMP_Trajectory(temp_Current_Tra,4);
            Y_A_TEMP = TEMP_Trajectory(temp_Current_Tra,5);
            X_B_TEMP = TEMP_Trajectory(temp_Current_Tra,6);
            Y_B_TEMP = TEMP_Trajectory(temp_Current_Tra,7);
            %   ��TEMP_Execution�в�����AB���ɵľ��������ڵ��߶�
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
            %   ����Ȧ����Χ���Ҳ����������¸��߶�
            if isempty(temp0)
                continue
            end
            %Step2������ɸѡ
            %   ��������Ϊֱ�ߵ��߶�
            temp0 = temp0(find(TEMP_Execution(temp0,2)==1));
            %   �����Ҳ����������¸��߶�
            if isempty(temp0)
                continue
            end
            %Step3�����ι�ϵɸѡ
            %   �жϲ��ҵ����߶εĶ˵��Ƿ��ڵ�ǰ�߶���
            %       ��ȡ���е���ֹ��
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
            %   �����Ҳ����������¸��߶�
            if isempty(temp0)
                continue
            else
                %   ��ɸѡ���غϵ��߶Σ����ж�temp0Ԫ��������������1�򾯸沢ֻȡ��һ��
                if length(temp0)>1
                    warning('�����غ��߶Σ�ֻȡ��һ���غϵ�')
                    temp0=temp0(1);
                end
            end

            %Step4������
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
            %   ��CD���ȵ���0�������¸��߶�
            if flag_CeqD
                continue
            end
            %   ��CD��Ҫ�Ե�������жԵ�
            if flag_CecD
                %   ���Ƚ��жԵ�
                temp1 = TEMP_Execution(temp0,4);
                temp2 = TEMP_Execution(temp0,5);
                TEMP_Execution(temp0,4) = TEMP_Execution(temp0,6);
                TEMP_Execution(temp0,5) = TEMP_Execution(temp0,7);
                TEMP_Execution(temp0,6) = temp1;
                TEMP_Execution(temp0,7) = temp2;
                %   �������¼�����ر���
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

            %Step5������
            %               switch [A==C D==B]
            %                   case [1 1]
            %                       ���      �յ�      ��ѹ������ʶ
            %                       A         C         0
            %                       C         D         1
            %                       D         B         0
            %                   case [0 1]
            %                       ���      �յ�      ��ѹ������ʶ
            %                       A         C         0
            %                       C         B         1
            %                   case [1 0]
            %                       ���      �յ�      ��ѹ������ʶ
            %                       A         D         1
            %                       D         B         0
            %                   case [0 0]
            %                       ���      �յ�      ��ѹ������ʶ
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
                    %   ������ʱ����
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp5 = [TEMP_Execution(temp0,:),0];
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   ���Ϊi�������յ��ΪC
                    temp3(end,6) = X_C_TEMP;
                    temp3(end,7) = Y_C_TEMP;
                    %   ��ӵĶΣ�����ִ�б�־λ��Ϊ1
                    temp5(1,13)= 1;
                    temp5(1, 1)= 0;
                    %   ��ȡԭ�����Ϊi������ʼ���ΪD����д��������
                    temp6(1,4) = X_D_TEMP;
                    temp6(1,5) = Y_D_TEMP;
                    temp6(1,1) = 0;
                    %   �ѽ�ȡ�ĺ��������ճ���ϣ�����ֵ��TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp5;temp6;temp4];
                case 2 %[0,1]
                    %   ������ʱ����
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   ���Ϊi�������յ��ΪC
                    temp3(end,6) = X_D_TEMP;
                    temp3(end,7) = Y_D_TEMP;
                    temp3(end,13)= 1;
                    %   ��ȡԭ�����Ϊi������ʼ���ΪC������ִ�б�־λ��Ϊ1����д��������
                    temp6(1,4) = X_D_TEMP;
                    temp6(1,5) = Y_D_TEMP;
                    temp6(1,1) = 0;
                    temp6(1,13)= 0;
                    %   �ѽ�ȡ�ĺ��������ճ���ϣ�����ֵ��TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp6;temp4];
                case 3 %[1,0]
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   ���Ϊi�������յ��ΪC
                    temp3(end,6) = X_C_TEMP;
                    temp3(end,7) = Y_C_TEMP;
                    temp3(end,13)= 0;
                    %   ��ȡԭ�����Ϊi������ʼ���ΪD����д��������
                    temp6(1,4) = X_C_TEMP;
                    temp6(1,5) = Y_C_TEMP;
                    temp6(1,1) = 0;
                    temp6(1,13)= 1;
                    %   �ѽ�ȡ�ĺ��������ճ���ϣ�����ֵ��TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp6;temp4];
                case 4 %[0,0]
                    %   ������ʱ����
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    %   ���Ϊi���а�ִ�б�־λ��Ϊ1
                    temp3(end,13) = 1;
                    %   �ѽ�ȡ�ĺ��������ճ���ϣ�����ֵ��TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp4];
            end
        case 2  %   Բ������Ҫ�жϣ������͡�Բ������R���뾶�Ƿ�һ�£�����ֹ�Ƕ��Ƿ��ڷ�Χ��
            %   ����ͨ�����͡�Բ��λ�á��뾶���г�ɸ����ͨ��Բ���Ƕȷ�Χ���о�ɸ��
            %Step1������ɸѡ
            temp0 = find(TEMP_Execution(:,2)==2);
            %   �����Ҳ����������¸��߶�
            if isempty(temp0)
                continue
            end

            %Step2��Բ��λ��ɸѡ
            %   ��ȡ��ǰԲ����Բ��A���뾶R����ֹ�Ƕ�
            X_A_TEMP = TEMP_Trajectory(temp_Current_Tra,8);
            Y_A_TEMP = TEMP_Trajectory(temp_Current_Tra,9);
            R_A_TEMP = TEMP_Trajectory(temp_Current_Tra,10);
            PhiATEMP = TEMP_Trajectory(temp_Current_Tra,11);
            PhiBTEMP = TEMP_Trajectory(temp_Current_Tra,12);
            %   ��TEMP_Execution�в���Բ����A���Բ��
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
            %   �����Ҳ����������¸��߶�
            if isempty(temp0)
                continue
            end

            %Step3�����뾶ɸѡ
            R_B_TEMP = TEMP_Execution(temp0,10);
            error1 = round((R_B_TEMP-R_A_TEMP)*1e3);
            temp0 = temp0(find(error1==0));
            %   �����Ҳ����������¸��߶�
            if isempty(temp0)
                continue
            end

%             %Step4�����Ƕȷ�Χɸѡ
%             %   ��Ҫע��һ�����⣬�Ƕ��Ƿ����㣡
%             %   ������Լ�Ϊ�ǶȲ�����180��Ķ̻��������Բ��
%             %   ��ˣ�������Ҫȷ���Ƕȵı�ʾ���⡣
% %             %   ������Ϊ��ʱ�뷽��
% %             if PhiATEMP<PhiBTEMP
% %                 DeltaPhi = PhiBTEMP - PhiATEMP;
% %                 if abs(DeltaPhi)<180
% %                     %   PhiB > PhiA��������Ϊ�ӻ������账��
% %                 elseif abs(deltaPhi>180
% %                     %   PhiB > PhiA���淽��Ϊ�ӻ���PhiB-360��
% %                     PhiBTEMP = PhiBTEMP - 360;
% %                 else
% %                     error('����180��Բ�����޷����㣡')
% %                 end
% %             elseif PhiATEMP>PhiBTEMP
% %                 DeltaPhi = PhiBTEMP - PhiATEMP;
% %                 if abs(DeltaPhi)<180
% %                     %   PhiB > PhiA���淽��Ϊ�ӻ������账��
% %                 elseif abs(deltaPhi>180
% %                     %   PhiB < PhiA��������Ϊ�ӻ���PhiA+360��
% %                     PhiATEMP = PhiATEMP - 360;
% %                 else
% %                     error('����180��Բ�����޷����㣡')
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
%             %   ���ڽǶȲ���PhiA��PhiB��Χ���Ҳ����������¸��߶�
%             if isempty(temp0)
%                 continue
%             end

            %Step5����Χ�ж������
            PhiCTEMP = TEMP_Execution(temp0,11);
            PhiDTEMP = TEMP_Execution(temp0,12);
            ArcAB = PhiBTEMP-PhiATEMP;
            ArcAC = PhiCTEMP-PhiATEMP;
            ArcAD = PhiDTEMP-PhiATEMP;
            if ArcAB == 0
                continue
            end
            %��Χ�ж�
            %   �е㸴�ӣ�������Ϊ��ʱ��
            %   PhiA<PhiBʱ
            %       PhiA�� (0,180)ʱ
            %           PhiB �� (PhiA,PhiA+180)ʱ��A��B����������(PhiA,PhiB)
            %           PhiB �� (PhiA+180,360 )ʱ��A��B�淽������(PhiB,360)|(0,PhiA)
            %       PhiA�� (180��360)ʱ
            %           PhiB �� (PhiA,360)     ʱ��A��B����������(PhiA,PhiB)
            %   PhiA>PhiBʱ
            %       PhiA�� (0,180)ʱ
            %           PhiB �� (0,PhiA)       ʱ��A��B�淽������(PhiB,PhiA)
            %       PhiA�� (180��360)ʱ
            %           PhiB �� (0,PhiA-180)   ʱ��A��B����������(PhiA,360)|(0,PhiB)
            %           PhiB �� (PhiA-180,PhiA)ʱ��A��B�淽������(PhiB,PhiA)
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
                %�����ڲ��ڷ�Χ�ڵĵ㣬������
                if (flag_C==0)||(flag_D==0)
                    temp(j)=0;                    
                end
            end
            temp0(find(temp0==0));
            %   �����Ҳ����������¸��߶�
            if isempty(temp0)
                continue
            end
            %����
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
                                %�������
                            elseif (PhiCTEMP>=PhiBTEMP)&&(PhiCTEMP<360)
                                PhiCTEMP = PhiCTEMP-360;
                            end
                            if (PhiDTEMP>=0)&&(PhiDTEMP<=PhiATEMP)
                                %�������
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
                                %�������
                            elseif (PhiCTEMP>=0)&&(PhiCTEMP<=PhiBTEMP)
                                PhiCTEMP = PhiCTEMP+360;
                            end
                            if (PhiDTEMP>=PhiATEMP)&&(PhiDTEMP<360)
                                %�������
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
                    case 1 %C��D��A��B����һ�£����趯��
                    case 0 %C=D��������һ��
                        temp0(j)=0;
                    case -1%D��C����Ҫ����˳��
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
%                     case 1 %C��D��A��B����һ�£����趯��
%                     case 0 %C=D��������һ��
%                         temp0(j)=0;
%                     case -1%D��C����Ҫ����˳��
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
            %   ���temp0�е���0��Ԫ��
            temp0(find(temp0)==0)=[];
            %   ��PhiΪ�գ������¸��߶�
            if isempty(temp0)
                continue
            end

            %Step6������
                %   ���ж��temp0��ֻȡ��һ��
                temp0=temp0(1);
                %   ���¼�����ر���
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
            %                       ���      �յ�      ��ѹ������ʶ
            %                       A         C         0
            %                       C         D         1
            %                       D         B         0
            %                   case [0 1]
            %                       ���      �յ�      ��ѹ������ʶ
            %                       A         C         0
            %                       C         B         1
            %                   case [1 0]
            %                       ���      �յ�      ��ѹ������ʶ
            %                       A         D         1
            %                       D         B         0
            %                   case [0 0]
            %                       ���      �յ�      ��ѹ������ʶ
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
            %       SN  LT  LN  X1  Y1  X2  Y2  Xc  Yc  R   ��1 ��1 flag
            %       ��֪AB��CD�������������������ۣ�
            %       case 1 A����C����D����B��
            %       case 2 A����C����B��D����
            %       case 3 A��C������D����B��
            %       case 4 A����B��
            switch flag
                case 1 %[1,1]
                    %   ������ʱ����
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp5 = [TEMP_Execution(temp0,:),0];
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   ���Ϊi�������յ������ͽǶȸ�ΪC
                    temp3(end,6) = TEMP_Execution(temp0,4);
                    temp3(end,7) = TEMP_Execution(temp0,5);
                    temp3(end,12)= TEMP_Execution(temp0,11);
                    %   ��ӵĶΣ�����ִ�б�־λ��Ϊ1
                    temp5(1,13)= 1;
                    temp5(1, 1)= 0;
                    %   ��ȡԭ�����Ϊi������ʼ�����ꡢ�Ƕȸ�ΪD����д��������
                    temp6(1,4) = TEMP_Execution(temp0,6);
                    temp6(1,5) = TEMP_Execution(temp0,7);
                    temp6(1,11)= TEMP_Execution(temp0,12);
                    temp6(1,1) = 0;
                    %   �ѽ�ȡ�ĺ��������ճ���ϣ�����ֵ��TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp5;temp6;temp4];
                case 2 %[0,1]                    
                    %   ������ʱ����
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   ���Ϊi�������յ������ͽǶȸ�ΪC
                    temp3(end,6) = TEMP_Execution(temp0,6);
                    temp3(end,7) = TEMP_Execution(temp0,7);
                    temp3(end,12)= TEMP_Execution(temp0,12);
                    temp3(end,13)= 1;
                    %   ��ȡԭ�����Ϊi������ʼ�����ꡢ�Ƕȸ�ΪC����д��������
                    temp6(1,4) = TEMP_Execution(temp0,6);
                    temp6(1,5) = TEMP_Execution(temp0,7);
                    temp6(1,11)= TEMP_Execution(temp0,12);
                    temp6(1,1) = 0;
                    temp6(1,13)= 0;
                    %   �ѽ�ȡ�ĺ��������ճ���ϣ�����ֵ��TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp6;temp4];
                case 3 %[1,0]
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp6 = TEMP_Trajectory(temp_Current_Tra,:);
                    %   ���Ϊi�������յ������ͽǶȸ�ΪD
                    temp3(end,6) = TEMP_Execution(temp0,4);
                    temp3(end,7) = TEMP_Execution(temp0,5);
                    temp3(end,12)= TEMP_Execution(temp0,11);
                    temp3(end,13)= 0;
                    %   ��ȡԭ�����Ϊi������ʼ�����ꡢ�Ƕȸ�ΪD����д��������
                    temp6(1,4) = TEMP_Execution(temp0,4);
                    temp6(1,5) = TEMP_Execution(temp0,5);
                    temp6(1,11)= TEMP_Execution(temp0,11);
                    temp6(1,1) = 0;
                    temp6(1,13)= 1;
                    %   �ѽ�ȡ�ĺ��������ճ���ϣ�����ֵ��TEMP_Trajectory
                    TEMP_Trajectory = [temp3;temp6;temp4];
                case 4 %[0,0]
                    temp3 = TEMP_Trajectory(1:temp_Current_Tra,:);
                    temp4 = TEMP_Trajectory(temp_Current_Tra+1:end,:);
                    temp3(end,13)= 1;
                    %   �ѽ�ȡ�ĺ��������ճ���ϣ�����ֵ��TEMP_Trajectory
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
%%  2024-01-26 ����dxf������
obj.TJ_data.TJ4PT = Trajectory4Print;
obj.TJ_data.TJ4AP = Trajectory4Airpressure;
obj.TJ_data.TJ4SC = Trajectory4Scan;
obj.TJ_data.TJ4IT = Trajectory4Interpolation;
%%  ����Gcode�ݸ�
%   ��ʼ��
Flag_Air_Target= 0;                         %Ŀ����ѹ״̬
Flag_Air_Current = Flag_Air_Target;         %��ǰ��ѹ״̬
Target_Position = zeros(1,2);               %Ŀ��λ��
cmd_num = 1;
%   ǰ�ô���
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
%   ��ʼѭ��
for i = 1:length(Trajectory4Print(:,1))
    %Part1����ʼ��
    Target_Position = Current_Position;%2023-03-06 ��ʼ��Target_Position
    Flag_Air_Target = Trajectory4Print(i,13);
    Target_Position(1:2) = [Trajectory4Print(i,6),Trajectory4Print(i,7)];
    Line_Type = Trajectory4Print(i,2);
    %   2022-01-15 ��ѹ״̬����Trajectory4Print��13�еı�־λȷ��
    %Part2����ѹ����״̬ȷ��
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
                error('��ѹ���ݴ���')
        end
    end
    Flag_Air_Current = Flag_Air_Target;
    %Part3����λд��
    %   �ⲿ����Ҫ�ж����ͣ���Ϊֱ�ߣ�ֱ��дG01�����ǻ��ߣ��ж�G02����G03��Ȼ��д��
    switch Line_Type
        case 1 %ֱ��
            %   2023-03-06 ���Ӽ���������
            Target_Position(4) = Current_Position(4) + 0*norm(Target_Position(1:3)-Current_Position(1:3));
            obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s','G01 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' Z',0,' E',Target_Position(4),' F',F1,';');
            cmd_num=cmd_num+1;
        case 2 %����
            isG02 = sign(Trajectory4Print(i,12)-Trajectory4Print(i,11));
            R = Trajectory4Print(i,10);
            %   2023-03-06 ���Ӽ��������㣨�뾶R���Ƕȱ仯��=����=������������
            Target_Position(4) = Current_Position(4) + 0*R * deg2rad(abs(Trajectory4Print(i,12)-Trajectory4Print(i,11)));
            switch isG02
                case 1
                    obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s','G02 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' E',Target_Position(4),' F',F1,';');
                    cmd_num=cmd_num+1;
                case -1
                    obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s','G03 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' E',Target_Position(4),' F',F1,';');
                    cmd_num=cmd_num+1;
                otherwise
                    warn(['���ߴ���������',num2str(i),'��'])
                    continue
            end
        otherwise
            warn(['����δ֪��������',num2str(i),'��'])
            continue
    end
    Current_Position = Target_Position;
end
%   ���ô���
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
%   �ر��ļ�
% fclose(fid);
%%  ���ɴ�ӡGcode
%   2024-01-27 ʹ��obj = saveCode4Print(obj)���ɴ�ӡ����
% %   ��ʼ��
% Flag_Air_Target= 0;                         %Ŀ����ѹ״̬
% Flag_Air_Current = Flag_Air_Target;         %��ǰ��ѹ״̬
% Target_Position = zeros(1,2);               %Ŀ��λ��
% cmd_num = 1;
% %   �½������ĵ�
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
% %   ǰ�ô���
% fprintf(fid,'%s \n','G28;');
% %   2024-01-26 ����������д����
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G28;');
% cmd_num = cmd_num+1;
% fprintf(fid,'%s \n','G0 F3000;');
% %   2024-01-26 ����������д����
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G0 F3000;');
% cmd_num = cmd_num+1;
% fprintf(fid,'%s \n','G0 Z3.000;');
% %   2024-01-26 ����������д����
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G0 Z3.000;');
% cmd_num=cmd_num+1;
% % fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G0 X',XO,' Y',YO,' Z',LO,' F',F0,';');
% %   2022-01-20 ����Ӧ�ð�F����ֵ��Ϊ����
% fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G0 X',XO,' Y',YO,' Z',LO,' F',F0,';');
% %   2024-01-26 ����������д����
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s%.3f%s%.3f%s%.3f%s%.3f%s','G0 X',XO,' Y',YO,' Z',LO,' F',F0,';');
% cmd_num=cmd_num+1;
% fprintf(fid,'%s \n','G92 X0 Y0 Z0 E0;');
% %   2024-01-26 ����������д����
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G92 X0 Y0 Z0 E0;');
% cmd_num=cmd_num+1;
% Current_Position = [0, 0, 0, 0, 0];
% %   ��ʼѭ��
% for i = 1:length(Trajectory4Print(:,1))
%     %Part1����ʼ��
%     %     Flag_Air_Target = 1;
%     %   2022-01-15 �����޸���һ��
%     Target_Position = Current_Position;%2023-03-06 ��ʼ��Target_Position
%     Flag_Air_Target = Trajectory4Print(i,13);
%     Target_Position(1:2) = [Trajectory4Print(i,6),Trajectory4Print(i,7)];
%     Line_Type = Trajectory4Print(i,2);
%     %     %   �ⲿ��ȷ����ѹ����״̬�Ƿ�ı䣬���ı�����в�����
%     %     try
%     %         temp_air = Trajectory4Airpressure(find(...
%     %             (Trajectory4Airpressure(i,6)==Target_Position(1))&...
%     %             (Trajectory4Airpressure(i,7)==Target_Position(2))...
%     %             ));
%     %     catch
%     %         Flag_Air_Target = 0;
%     %     end
%     %   2022-01-15 ��ѹ״̬����Trajectory4Print��13�еı�־λȷ������˲���Ҫ��һ����
%     %Part2����ѹ����״̬ȷ��
%     Flage_Change_Air = ~isequal(Flag_Air_Target,Flag_Air_Current);
%     if Flage_Change_Air
%         switch Flag_Air_Target
%             case 1
%                 fprintf(fid,'%s \n','M106;');
%                 %   2024-01-26 ����������д����
%                 obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','M106;');
%                 cmd_num=cmd_num+1;
%             case 0
%                 fprintf(fid,'%s \n','M107;');
%                 %   2024-01-26 ����������д����
%                 obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','M107;');
%                 cmd_num=cmd_num+1;
%             otherwise
%                 error('��ѹ���ݴ���')
%         end
%     end
%     Flag_Air_Current = Flag_Air_Target;
%     %Part3����λд��
%     %   �ⲿ����Ҫ�ж����ͣ���Ϊֱ�ߣ�ֱ��дG01�����ǻ��ߣ��ж�G02����G03��Ȼ��д��
%     switch Line_Type
%         case 1 %ֱ��
%             %             fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G01 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' Z',0,' F',F0,';');
%             %             %   2022-01-20 ����Ӧ�ð�F����ֵ��Ϊ����
%             %             fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%u%s \n','G01 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' Z',0,' F',F0,';');
%             %   2023-03-06 ���Ӽ���������
%             Target_Position(4) = Current_Position(4) + 0*norm(Target_Position(1:3)-Current_Position(1:3));
%             fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s \n','G01 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' Z',0,' E',Target_Position(4),' F',F0,';');
%             %   2024-01-26 ����������д����
%             obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s','G01 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' Z',0,' E',Target_Position(4),' F',F0,';');
%             cmd_num=cmd_num+1;
%         case 2 %����
%             isG02 = sign(Trajectory4Print(i,12)-Trajectory4Print(i,11));
%             R = Trajectory4Print(i,10);
%             %   2023-03-06 ���Ӽ��������㣨�뾶R���Ƕȱ仯��=����=������������
%             Target_Position(4) = Current_Position(4) + 0*R * deg2rad(abs(Trajectory4Print(i,12)-Trajectory4Print(i,11)));
%             switch isG02
%                 case 1
%                     %                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G02 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' F',F0,';');
%                     %                     %   2022-01-20 ����Ӧ�ð�F����ֵ��Ϊ����
%                     %                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%u%s \n','G02 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',0,' F',F0,';');
%                     %   2023-03-06 ���Ӽ���������
%                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s \n','G02 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' E',Target_Position(4),' F',F0,';');
%                     %   2024-01-26 ����������д����
%                     obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s','G02 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' E',Target_Position(4),' F',F0,';');
%                     cmd_num=cmd_num+1;
%                 case -1
%                     %                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s \n','G03 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' F',F0,';');
%                     %                     %   2022-01-20 ����Ӧ�ð�F����ֵ��Ϊ����
%                     %                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%u%s \n','G03 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' F',F0,';');
%                     %   2023-03-06 ���Ӽ���������
%                     fprintf(fid,'%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s \n','G03 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' E',Target_Position(4),' F',F0,';');
%                     %   2024-01-26 ����������д����
%                     obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s%.3f%s%.3f%s%.3f%s%.3f%s%u%s','G03 X',Target_Position(1)+X_Offset,' Y',Target_Position(2)+Y_Offset,' R',R,' E',Target_Position(4),' F',F0,';');
%                     cmd_num=cmd_num+1;
%                 otherwise
%                     warn(['���ߴ���������',num2str(i),'��'])
%                     continue
%             end
%         otherwise
%             warn(['����δ֪��������',num2str(i),'��'])
%             continue
%     end
%     Current_Position = Target_Position;
% end
% %   ���ô���
% fprintf(fid,'%s \n','M107;');
% %   2024-01-26 ����������д����
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','M107;');
% cmd_num=cmd_num+1;
% fprintf(fid,'%s \n','G91;');
% %   2024-01-26 ����������д����
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G91;');
% cmd_num=cmd_num+1;
% fprintf(fid,'%s \n','G0 F3000;');
% %   2024-01-26 ����������д����
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G0 F3000;');
% cmd_num=cmd_num+1;
% fprintf(fid,'%s \n','G0 Z2;');
% %   2024-01-26 ����������д����
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G0 Z2;');
% cmd_num=cmd_num+1;
% fprintf(fid,'%s \n','G90;');
% %   2024-01-26 ����������д����
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G90;');
% cmd_num=cmd_num+1;
% fprintf(fid,'%s \n','G00 X0 Y0;');
% %   2024-01-26 ����������д����
% obj.TJ_data.Code4Print{cmd_num,1}=sprintf('%s','G00 X0 Y0;');
% cmd_num=cmd_num+1;
% %   �ر��ļ�
% fclose(fid);
%%  ����ɨ��Gcode
%   2022-01-15 ���£�
%   ���ɨ�衢�ܻ���·������ɨ��·�����󣬲��Ѿ��󣨹��������������浽ָ����·���£�
%   ����������˼·��
%       ��1��������ֱ�ӽ��м��ܴ�����Ҫ����޸Ĵ��룬LJ_Control�Ĵ����޸Ľ���
%       ��2����ʹ��G������д��ݣ�ֱ��ʹ�ù������������д��䣬�ô��Ǽ����˱��ļ���LJ_Control�Ĵ�������
%           �������������ֹ���̵��Ѷȣ�δ����Ҫɨ����������DXF��MATALB��Scaner�Ĺ�������
%       Ȩ�����׺�ѡ��ڶ��ַ�ʽ��
%   ���ں�����ȡ�Ͳ�����
%       ���ݸ�ʽ��
%               ����[ x1,  x2,  x3,  x4,   x5,  x6 ]
%               ֱ�ߣ���X  ��Y  ��X  ��Y   []   []   
%               Բ������X  ��Y  ��R  ʼ��  �զ� []   
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
%  2024-01-26 ����dxf������
obj.TJ_data.TJ4ZZ = Z_Value;
obj.TJ_data.TJ4FF = F_Value;
%%  ��������
obj.syset.flags.read_flag_trajectory = 1;
end