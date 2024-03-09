function obj = LS_voxelization(obj)
%%  依赖关系判断
if obj.syset.flags.read_flag_sdgrou~=1
    error('strand grouping has not been processed yet!')
end
%%  处理程序
test = 1;
test2= 1;
%   组提取
tt = obj.PC_data_merged.group_data.act; %   tt是分组数据：-1 1 2 3 4... -1是杂点
group = unique(tt(tt>0));
%   线条内部点应满足一下条件：f(x,y)>z>zreg,其中：
%       f是第i组的点拟合得到的曲面方程
%       zreg是之前用于轨迹提取用到的判据，认为在这个点上方的点才是曲面内部点
%       通过上述两个面包围的点就认为构成了线条实体
%   提取判据
zreg = obj.PC_data_merged.group_data.reg;
%   提取所有点
x = obj.PC_data_merged.fitted_PC.X(:,1);
y = obj.PC_data_merged.fitted_PC.X(:,2);
z = obj.PC_data_merged.group_data.Z(:);

zbot = mean(z(~isnan(z)&tt==-1));
obj.PC_data_merged.group_data.bottom = zbot;
% %   然后把分组为-1的点的Z值修改为zmin-std(z)，确保这些点存在，并远低于平面
% z(tt==-1)=min(z)-std(z(~isnan(z)));
%   把分组为-1的点的Z值修改为-1组内非NAN值得最小值，发现比zreg底，但是不是很离谱
z(tt==-1)=min([zbot zreg]);
%   测试一下
if test
    figure(7)
    scatter(x,y,3,z,"filled");
    pause(5)
end
% %   构建体素区域（规避x,y,z中的nan项)
% x1 = x(~isnan(x)&~isnan(y)&~isnan(z));
% y1 = y(~isnan(x)&~isnan(y)&~isnan(z));
% z1 = z(~isnan(x)&~isnan(y)&~isnan(z));
% %   拟合
% F = scatteredInterpolant(x1, y1, z1, 'natural', 'none');
% clear x1 y1 z1
% close all
for i = 1:length(group)
    %   目前已经：
    %       1. 提取zreg
    %       2. 提取xyz,并把-1组设置为统一值
    %       3. 提取分组信息tt，和组别group
    %   对于每组：
    %       1. 体素化全部区域
    %       2. 以该组的xy范围拟合曲面函数f
    %       3. 内外判断及赋值
    %       4. 关键参数的保存

    %   体素化vox
    c = obj.Devinfo.inplt;
    W = round((max(x)-min(x))/c);   %   Width 宽 列数
    H = round((max(y)-min(y))/c);   %   Height高 行数
    D = round((max(z)-zreg)/c);     %   Depth 深 层数
    vox = false(H,W,D);             %   体素 W×H×D 逻辑变量

    %   拟合函数
    % xi = x(tt==group(i)); yi = y(tt==group(i)); zi = z(tt==group(i));
    %   提取第i组数据的最值
    ximin = min(x(tt==group(i)))-5*c;
    ximax = max(x(tt==group(i)))+5*c;
    yimin = min(y(tt==group(i)))-5*c;
    yimax = max(y(tt==group(i)))+5*c;
    zimin = min(z(tt==group(i)))-5*c;
    zimax = max(z(tt==group(i)))+5*c;
    obj.LS_Vox(i).edge = [ximin;ximax;yimin;yimax;zimin;zimax];    %   边界信息保存
    %   提取第i组数据及背景数据（-1组）
    xi = x(tt==-1|tt==group(i)); yi = y(tt==-1|tt==group(i)); zi = z(tt==-1|tt==group(i));
    %   提取在第i组数据范围内的点
    % sn = (xi>=ximin && xi<=ximax) && (yi>=yimin && yi<=yimax) && (zi>=zimin && zi<=zimax);
    sn = xi>=ximin & xi<=ximax & yi>=yimin & yi<=yimax;
    xi = xi(sn); yi = yi(sn); zi = zi(sn);
    %   拟合函数
    F = scatteredInterpolant(xi, yi, zi, 'natural', 'none');
    %   保存函数
    obj.LS_Vox(i).function = F;    %   函数信息保存
    if test
        [XX,YY]=meshgrid(min(xi):0.1:max(xi),min(yi):0.1:max(yi));
        ZZ = F(XX,YY);
        figure(8)
        mesh(XX,YY,ZZ)
        hold on
        plot3(xi,yi,zi,'r.')
        hold off
        view([-2 -4 8])
        pause(5)
    end
    %   矩阵和坐标的不同
    %   https://blog.csdn.net/qq_15295565/article/details/99688829
    %   matlab程序中处理图像时，有时候用的是（x，y）来操作，有时候用的是（y，x），所以什么时候用哪个就会分不清楚，到底有什么区别呢？
    %   首先，图像坐标系是以图像的左上角为原点，访问的时候是从1开始，而不是0，在C程序中是从0开始。
    %   （1）在对图像的像素进行访问时需要对图像进行双层遍历，在对图像像素访问时，坐标为（y,x），则外层遍历和内层遍历便是分别对图像的行（对应y坐标）、列（对应x坐标）的遍历。
    %   （2）如果是将图像进行plot显示或者进行其他操作，坐标为（x，y）的顺序。

    %   内外判定
    for j = 1:D
        layer = vox(:,:,j);
        height = zreg+c*j;
        [xx,yy] = meshgrid(min(xi)+c*(1:W),min(yi)+c*(1:H));
        temp_x = reshape(xx,[],1);
        temp_y = reshape(yy,[],1);
        temp_z = F(temp_x,temp_y)>height;
        temp_z(isnan(temp_z))=false;
        temp_z = reshape(temp_z,H,W);
        if test
            figure(9)
            imshow(flip(temp_z))
            title(['layer ',num2str(j)])
            pause(0.5)
        end
        layer(find(temp_z>0))=true;
        vox(:,:,j) = layer;
    end

    %   保存数据
    obj.LS_Vox(i).vox=vox;

    %   绘图
    if test2
    skel = Skeleton3D(vox);
    col=[.7 .7 .8];
    figure(10)
    hold on
    hiso = patch(isosurface(vox,0),'FaceColor',col,'EdgeColor','none');
    hiso2 = patch(isocaps(vox,0),'FaceColor',col,'EdgeColor','none');
    axis equal;axis off;
    lighting phong;
    isonormals(vox,hiso);
    alpha(0.5);
    set(gca,'DataAspectRatio',[1 1 1])
    camlight;
    w=size(skel,1);
    l=size(skel,2);
    h=size(skel,3);
    [x1,y1,z1]=ind2sub([w,l,h],find(skel(:)));
    plot3(y1,x1,z1,'square','Markersize',4,'MarkerFaceColor','r','Color','r');
    set(gcf,'Color','white');
    % view(140,80)
    % view([1 1 1])
    view([0 0 1])
    hold off
    end
end
%%  结束与标记
obj.syset.flags.read_flag_vox = 1;
end