function [data_coordin,data_profile] = LJ_G5000_P_cmd(obj,A,test_flag)
% 功能:   处理传感器发回的数据, 生成横纵坐标（X,Z）, 单位为um.
% 语法:
%   [data_coordin,data_profile] = LJ_G5000_Pcmd_data_process(A,test_flag)
%       A:              激光轮廓传感器返回的原始数值
%       test_flag:      测试标志, 若定义, 则会回显一些语句, 并绘轮廓图
%       data_coordin:   轮廓横坐标(X), 单位um
%       data_profile:   轮廓纵坐标(Z), 单位um
% 引用：
%   该函数引用了以下几个自己编写的子函数：
%   trans_endian(a,x),  a是需要进行大小端转换的字符串, 可以是二进制(bin)和十六进制(hex),
%                       x是每次读取的位数, 一般二进制是8, 十六进制为2.
%   hex2bin(),          将十六进制数转为二进制数, Matlab中居然没有集成, 就自己写了一下.
%   com2dec(),          将二进制补码转为十进制数.
%   数据存储格式为带符号32位(32bit signed), 小端读取(little endian), 补码形式,
%   因此需要编写上述三个子函数方便计算.

%   测试标志
% test_flag=1;
if ~exist('test_flag')
    test_flag = 0;
end
if test_flag
    disp('数据已接收')
end
num_data = length(A);
if num_data~=3224
    profile = [];
    error("数据出现丢失, 请重新尝试！")
    return
end
%   Head
head_temp = reshape(dec2hex(A(1:24))',1,[]);
check_temp = strcmp('980C071F000000000000000000',head_temp([1:24,29,30]));
error_coede_1 = head_temp(9:10);      %
error_coede_2 = head_temp(17:18);     %
num_of_profile= head_temp(25:28);     %   数据点数量（16进制）(unsigned 16bit, little endian)
X_pitch       = head_temp(33:40);     %   X间距 (Hex, 0.1um, 32 bit signed, Little endian)
X_coordinate  = head_temp(41:48);     %   第一个点的X坐标 (Hex, 0.1um, 32 bit signed, Little endian)
%   这里的Little endian的意思是这样
%   num_of_profile should be:
%       0d800,    0x0320,    0b0000001100100000
%   we can get it directly as:
%       0d8195,   0x2003,    0b0010000000000011
%   so, we should read 8bit at a time.

%   参考资料：
%   [1] 【数据存储结构】int32的二进制存储形式. https://blog.csdn.net/plaxbsga/article/details/124819567
%   [2] INT类型在文件中的二进制存储方式. https://blog.csdn.net/m0_65529430/article/details/123874549?spm=1001.2101.3001.6661.1&utm_medium=distribute.pc_relevant_t0.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123874549-blog-124819567.pc_relevant_3mothn_strategy_and_data_recovery&depth_1-utm_source=distribute.pc_relevant_t0.none-task-blog-2%7Edefault%7ECTRLIST%7ERate-1-123874549-blog-124819567.pc_relevant_3mothn_strategy_and_data_recovery
%   [3] 深入理解计算机中的原码、补码、反码. https://zhuanlan.zhihu.com/p/371184302
if check_temp
    num_of_profile_trans   = trans_endian(num_of_profile,2);
    X_pitch_trans          = trans_endian(X_pitch,2);
    X_coordinate_trans     = trans_endian(X_coordinate,2);
    X_pitch_com            = hex2bin(X_pitch_trans);
    X_coordinate_com       = hex2bin(X_coordinate_trans);
    num_of_profile_dec     = hex2dec(num_of_profile_trans);
    X_pitch_dec            = com2dec(X_pitch_com);
    X_coordinate_dec       = com2dec(X_coordinate_com);
    if test_flag
        disp(['Returned ',num2str(num_of_profile_dec),' profiles.']);
        disp(['X pitch is ',num2str(X_pitch_dec*1e-1),' um.']);
        disp(['First X coordinate is ',num2str(X_coordinate_dec*1e-1),' um']);
    end
else
    data_coordin=[];
    data_profile=[];
    error(['接收错误!',' Error Code 1: ',error_coede_1,', Error Code 2: ',error_coede_2,'. ']);
    return
end

%   Data
data_profile = zeros (800,1);
for i=1:800
    temp_0 = dec2bin(A(21+4*i:24+4*i),8);   %读取某一组的数据（4×8的二维数组）
    temp_1 = reshape(temp_0',1,[]);         %转为1×32的一维数组
    temp_tans = trans_endian(temp_1,8);     %由于为小端读取, 读取了二进制补码
    temp_dec  = com2dec(temp_tans);         %转为十进制数
    data_profile(i) = temp_dec;
end
data_profile = data_profile*1e-1;           %   单位为um
data_coordin = [0:num_of_profile_dec-1]*X_pitch_dec*1e-1+X_coordinate_dec*1e-1;
data_coordin = data_coordin';
%   剔除异常点
error_points = find(data_profile==com2dec('10000000000000000000000000000000')*1e-1);
data_profile(error_points)=NaN;
data_coordin(error_points)=NaN;
if test_flag
    plot(data_coordin,data_profile)
    %     axis equal
    disp('图像已绘制')
end