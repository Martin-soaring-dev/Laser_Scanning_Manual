function obj = LS_tilt_correction(obj,plot_flag)
%%  依赖关系判断
if obj.syset.flags.read_flag_pf~=1
    error('plane fitting has not been done yet!')
end
%%  读取数据
%   obj.Surface.plane_eq
%   线性模型 Poly11:
%   val(x,y) = p00 + p10*x + p01*y
%   平面方程可写为
%   A*x+B*y+C*z+D=0;
%   则法线向量为 n = (A,B,C)
%   A∂*x+B*∂y+C*∂z=0;
%   ∂z/∂x = -A/C
%   ∂z/∂y = -B/C
%   A = p10
%   B = p01
%   C = -1
%   D = p00
%   a = ∂z/∂x = p10
%   b = ∂z/∂y = p01
%   sin(α)/a = cos(α)/1 = 1/sqrt(1+a^2) → cos(α) = 1/sqrt(1+a^2)
%   sin(β)/b = cos(β)/1 = 1/sqrt(1+b^2) → cos(β) = 1/sqrt(1+b^2)
if ~exist("plot_flag")
    plot_flag=0;
end
a = obj.Surface.plane_eq.p10;
b = obj.Surface.plane_eq.p01;
alpha = acosd(1/sqrt(1+a^2))*sign(asind(a/sqrt(1+a^2)));
beta  = acosd(1/sqrt(1+b^2))*sign(asind(b/sqrt(1+b^2)));

p1 = obj.PC_data_merged.Merged_PC.X;

xyzsn = ~isnan(p1(:,1))&~isnan(p1(:,2))&~isnan(p1(:,3));
xc = mean(p1(xyzsn,1));
yc = mean(p1(xyzsn,2));
zc = mean(p1(xyzsn,3));
% p2 = Homo_coordi_trans(p1,[xc yc zc beta alpha 0],[xc yc zc 0 0 0],1);
% p2 = Homo_coordi_trans(p1,[xc yc zc beta 0 0],[xc yc zc 0 0 0],1);
P1 = [p1,ones(size(p1,1),1)];
o1  = [0 0 0 -beta -alpha 0];
% o1 = [0 0 0 -beta 0 0];
o2 = [xc yc zc 0 0 0];
t  = trans_matrix(o2,1)*trans_matrix(o1,1)*trans_matrix(-o2,1);
P2 = (t*P1')';
p2 = P2(:,1:3);
obj.PC_data_merged.fitted_PC = obj.PC_data_merged.Merged_PC;
obj.PC_data_merged.fitted_PC.X = p2;
%% 显示拟合结果
if plot_flag
    subplot(2,2,1)
    scatter(p1(:,2),p1(:,3),1,p1(:,3),"filled");
    % view([1 0 0])
    subplot(2,2,3)
    scatter(p2(:,2),p2(:,3),1,p2(:,3),"filled");
    % view([1 0 0])
    subplot(2,2,2)
    scatter(p1(:,1),p1(:,3),1,p1(:,3),"filled");
    % view([0 1 0])
    subplot(2,2,4)
    scatter(p2(:,1),p2(:,3),1,p2(:,3),"filled");
    % view([0 1 0])
    set(gca,'FontName','Times New Roman')
end
%%  结束与标记
obj.syset.flags.read_flag_af = 1;
end