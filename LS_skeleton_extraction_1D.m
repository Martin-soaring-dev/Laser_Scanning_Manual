function obj = LS_skeleton_extraction_1D(obj,varargin)
%%  依赖关系判断
if obj.syset.flags.read_flag_vox~=1
    error('voxelization has not been processed yet!')
end
%%  default values
default_test_flag= 0;       % 测试标志
default_fit_mode = 1;       % 拟合模式，1.直接拟合y=f(x) 2.参数化拟合x=f(t),y=f(t)
%   声明一个p为inputParser格式的。其实也可以理解为一个该格式的句柄一样的东西
IP = inputParser;
addRequired(IP,'obj');
%   接下来两个是可选参数，名字分别为’stepsize'和'OptimalityTolerance'，如果没有检测到输入将有相应的缺省值defaulth和epsilon。这些都在函数开头声明好了
addParameter(IP,'fit_mode',default_fit_mode);
addParameter(IP,'test_flag',default_test_flag);
%   利用parse函数将输入参数与上面的进行匹配
parse(IP,obj,varargin{:});
%   此时就已经生成好了一个inputParser格式的参数p，p里面含有不少东西，其中它的Results为一个结构体，是输入参数在匹配后的值，利用这个可以完成我的output的赋值
fit_mode = IP.Results.fit_mode;
test_flag = IP.Results.test_flag;
%%  处理程序
% test_flag = 1;
if test_flag
    close
end
for i = 1:length(obj.LS_Vox)
    edge = obj.LS_Vox(i).edge;
    func = obj.LS_Vox(i).function;
    c    = obj.Devinfo.inplt;
    skel = Skeleton3D(obj.LS_Vox(i).vox);
    w=size(skel,1);
    l=size(skel,2);
    h=size(skel,3);
    [y1,x1,z1]=ind2sub([w,l,h],find(skel(:)));
    x1 = x1*c+edge(1);
    y1 = y1*c+edge(3);
    z1 = z1*c+edge(5);
    if test_flag
        figure(11)
        plot3(x1,y1,z1,'square','Markersize',4,'MarkerFaceColor','r','Color','r');
        set(gcf,'Color','white');
        hold on
        x    = edge(1):c:edge(2);
        y    = edge(3):c:edge(4);
        [X,Y]= meshgrid(x,y);
        Z = func(X,Y);
        mesh(X,Y,Z,'FaceAlpha','0');
        view([0 0 1])
    end
    %   保存拟合函数
    switch fit_mode
        case 1
    % obj.LS_Vox(i).curve = csaps(x1,y1,0.98);
    obj.LS_Vox(i).curve = cp_extract_cspline(x1,y1,0.5,'mode',2);    %   这里其实还是当作二维曲线来拟合的，如果后续想拟合三维曲线，需要编写对应的方程，并提前做异常数据剔除
        case 2
            %   2024-02-06 增加了第二种拟合算法，可以应对任意曲线，基本原理如下：
            %       建立了一个新的函数，即按照距离进行排序，这样可以按照起点不断搜索至终点，从而确保点是连续的
            %       函数提供了两种搜索方向，从第一个点向后搜索，以及从最后一个点向前搜索
            %       这里分别从两个方向进行搜索排序
            %       然后计算排序后的总路程，取路程最小的排序，并赋给x2,y2
            %       再分别对其进行拟合，即拟合x=f(t),y=f(t),t∈[dt,1],dt=1/length(x)=1/length(y)
            %   因为这个改动，原先的数据处理可能会出错，如果出错，则需要该日期前的数据重新过一遍：
            %   obj = LS_skeleton_extraction_1D(obj,'fit_mode',2);
            [Temp1,id1]=sortd([x1,y1],1);[Temp2,id2]=sortd([x1,y1],-1);
            distance1=sum(vecnorm((Temp1(2:end,:)-Temp1(1:end-1,:))')');
            distance2=sum(vecnorm((Temp2(2:end,:)-Temp2(1:end-1,:))')');
            if distance1<=distance2
                x2=Temp1(:,1);y2=Temp1(:,2);
            elseif distance1>distance2
                x2=Temp2(:,1);y2=Temp2(:,2);
            end
            clear Temp1 Temp2 id1 id2
            obj.LS_Vox(i).curve_x = cp_extract_cspline([1:length(x2)]'/length(x2),x2,1-1e-6,'mode',2);
            obj.LS_Vox(i).curve_y = cp_extract_cspline([1:length(y2)]'/length(y2),y2,1-1e-6,'mode',2);
            if test_flag
                tempt=0:1e-5:1;
                fx=obj.LS_Vox(i).curve_x.curve_model;
                fy=obj.LS_Vox(i).curve_y.curve_model;
                plot(x1(1),y1(1),'ro',x1,y1,'k-',x2(1),y2(1),'bo',x2,y2,'r-',fx(tempt),fy(tempt),'b--')
                pause(2)
            end
    end
end
if test_flag
    hold off
end
%%  结束与标记
obj.syset.flags.read_flag_skcomp = 1;
end
%   手动选择
% tt = find(obj.PC_data_merged.fitted_PC.X(:,3)>-8);
% plot3(obj.PC_data_merged.fitted_PC.X(:,1),obj.PC_data_merged.fitted_PC.X(:,2),obj.PC_data_merged.fitted_PC.X(:,3),'b.')
% hold on
% plot3(obj.PC_data_merged.fitted_PC.X(tt,1),obj.PC_data_merged.fitted_PC.X(tt,2),obj.PC_data_merged.fitted_PC.X(tt,3),'r.')
% hold off
% view([1 0 0])
% view([0 0 1])
% tt = find(obj.PC_data_merged.fitted_PC.X(:,3)>h.BinEdges(find(aaa==min(aaa))+6));
% plot3(obj.PC_data_merged.fitted_PC.X(:,1),obj.PC_data_merged.fitted_PC.X(:,2),obj.PC_data_merged.fitted_PC.X(:,3),'b.')
% hold on
% plot3(obj.PC_data_merged.fitted_PC.X(tt,1),obj.PC_data_merged.fitted_PC.X(tt,2),obj.PC_data_merged.fitted_PC.X(tt,3),'r.')
% hold off
% [idx corepts]=dbscan(obj.PC_data_merged.fitted_PC.X(tt,1:3),1,50);
% numGroups = length(unique(idx));
% gscatter(obj.PC_data_merged.fitted_PC.X(tt,1),obj.PC_data_merged.fitted_PC.X(tt,2),idx,hsv(numGroups));
% % scatter3(obj.PC_data_merged.fitted_PC.X(tt,1),obj.PC_data_merged.fitted_PC.X(tt,2),obj.PC_data_merged.fitted_PC.X(tt,3),5,idx,'filled')
% legend()
% view([0 0 1])
% view([1 0 0])