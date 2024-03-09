classdef LaserScan
    properties
        syset
        Devinfo
        TJ_data
        PT_data
        LJ_data
        PC_data
        PC_data_merged
        Surface
        LS_plot
        LS_Vox
        LS_profile
        LS_deviation
        LS_model
        LS_compensation
    end
    
    %   example
    %   obj = LaserScan(0.1,'192.168.1.101');

    methods
        % Constructor
        function obj = LaserScan(c,ip)
            obj.Devinfo.inplt = c;                   %密化精度
            obj.Devinfo.inplt_p=1;                   %轨迹离散精度
            obj.Devinfo.ip = ip;                     %传感器ip地址
            
            %   保存基本信息
            load('Config.mat','path')

            obj.syset.seed = num2str(randi([1 999],1,1),'%03i');     % 创建1-999的随机种子数
            obj.syset.path = [path,'\temp\tp4lj\',char(datetime('today')),'_',obj.syset.seed];  % 路径：工作路径\temp\tp4lj\yyyy-mm-dd_随机种子数
            obj.syset.path_plotmp = [obj.syset.path,'\plot_temp\']; % 绘图文件路径
            obj.syset.path_output = [obj.syset.path,'\output\'];    % 输出路径
            obj.syset.path_outfig = [obj.syset.path_output,'fig\']; % 输出图片路径
            obj.syset.path_outcod = [obj.syset.path_output,'cod\']; % 输出代码路径
            obj.syset.path_pc_out = [path,'\temp\tp4op\']; % 路径: pointCloud output path
            obj.syset.path_pc_tmp = [path,'\temp\tp4tp\']; % 路径: pointCloud temp path
            try
                Safemkdir(obj.syset.path);  % 安全创建路径，如果已存在会返回一个error（一般不会），不存在则创建路径
                addpath(obj.syset.path);    % 把创建的路径添加到工作路径中
                Safemkdir(obj.syset.path_plotmp);  % 安全创建路径，如果已存在会返回一个error（一般不会），不存在则创建路径
                addpath(obj.syset.path_plotmp);    % 把创建的路径添加到工作路径中
                Safemkdir(obj.syset.path_output);  % 安全创建路径，如果已存在会返回一个error（一般不会），不存在则创建路径
                addpath(obj.syset.path_output);    % 把创建的路径添加到工作路径中
                Safemkdir(obj.syset.path_outfig);  % 安全创建路径，如果已存在会返回一个error（一般不会），不存在则创建路径
                addpath(obj.syset.path_outfig);    % 把创建的路径添加到工作路径中
                Safemkdir(obj.syset.path_outcod);  % 安全创建路径，如果已存在会返回一个error（一般不会），不存在则创建路径
                addpath(obj.syset.path_outcod);    % 把创建的路径添加到工作路径中
            catch ME
                warning(ME)
            end
            obj.syset.file      = 'LaserScanClass.mat'; % 全部文件名称 LaserScanClass.mat
            obj.syset.file_data = 'LaserScanData.mat';  % 数据文件名称
            obj.syset.file_cofg = 'LaserScanCfig.mat';  % 配置文件名称
            
            obj.syset.flags.test_flag = 1;           %全局测试标志
            obj.syset.flags.test_inplt= 0;           %密化函数跳过标志
            obj.syset.flags.test_flag_tj = 0;        %全局测试标志

            obj.syset.flags.read_flag_dxf = 0;       %dxf就绪标志
            obj.syset.flags.read_flag_trajectory = 0;%轨迹提取标志
            obj.syset.flags.read_flag_scaner = 0;    %扫描完成标志
            obj.syset.flags.read_flag_pc = 0;        %点云拼接完成标志
            obj.syset.flags.read_flag_pf = 0;        %平面拟合完成标志
            obj.syset.flags.read_flag_sf = 0;        %曲面拟合完成标志
            obj.syset.flags.read_flag_af = 0;        %倾角矫正完成标志
            obj.syset.flags.read_flag_tjcomp = 0;    %轨迹比对完成标志
            obj.syset.flags.read_flag_histog = 0;    %直方图已绘制标志
            obj.syset.flags.read_flag_sdextr = 0;    %线条提取完成标志
            obj.syset.flags.read_flag_sdgrou = 0;    %线条分组完成标志
            obj.syset.flags.read_flag_vox = 0;       %体素处理完成标志
            obj.syset.flags.read_flag_skcomp = 0;    %骨架提取完成标志
            obj.syset.flags.read_flag_profiletxra=0; %截面提取完成标志
            obj.syset.flags.read_flag_profileansy=0; %截面分析完成标志
            obj.syset.flags.cacu_flag_deviation  =0; %偏差计算完成标志
            obj.syset.flags.read_flag_sccmload   =0; %截面模型读取标志
            obj.syset.flags.flag_adjusted_traj   =0; %轨迹优化完成标志
            obj.syset.flags.flag_adjusted_para   =0; %参数优化完成标志
            
            obj.Devinfo.printer.s = [];              %打印机对象
            obj.Devinfo.printer.statue = 0;          %打印机状态 0: offline 1:online 2:busy
            obj.Devinfo.scanner.t = [];              %扫描仪对象
            obj.Devinfo.scanner.statue = 0;          %扫描仪状态 0: offline 1:online 2:busy
            
            %   轨迹提取相关设定
            start_point = [0 0 0 0 0 0 0 0]';        %打印/扫描起止点
            %   row 1-2: first motion point [x,y] for printer
            %   row 3-4: first design point [x,y] for printer. 
            %            need to be consistent with it when designing.
            start_point(3:4) = [0 0]';
            %   row 5-6: first motion point [x,y] for scanner
            %   row 7-8: first design point [x,y] for scanner
            %            need to be consistent with it when designing.
            start_point(7:8) = [0 0]';
            obj.Devinfo.trajectory.start_point= start_point;      %打印/扫描起止点
            clear start_point
            feed_rate = [0 0 0]';   
            feed_rate(1) = 1200;    % mm/min travel speed
            feed_rate(2) = 600;     % mm/min printer moving speed
            feed_rate(3) = 300;     % mm/min scanner moving speed
            obj.Devinfo.trajectory.feed_rate= feed_rate;          %速度设定
            clear feed_rate
            obj.Devinfo.trajectory.layer_height = 0.6;            %层高设定

            %   打印机相关设定
            obj.Devinfo.printer.printeroffset = [0 0 0 0 0 0];    %轨迹偏置 mm, degree
            obj.Devinfo.printer.axis_mode     = [1 1 1 0 0 0];    %使用几个轴
            obj.Devinfo.nozzle_diameter       = 0.84;             %喷嘴内径 mm
            obj.Devinfo.extruderate=obj.Devinfo.trajectory.feed_rate(2);%挤出速率 mm/min 假设值

            %   扫描仪相关设定
            obj.Devinfo.scanner.scanneroffset = [0 0 0 0 0 0];    %扫描偏置 mm, degree 相对于喷嘴
            obj.Devinfo.scanner.struct_type   = 3;                %安装方式：1. 112实验室；2.113实验室五轴；3.NUS平台
            switch obj.Devinfo.scanner.struct_type                %结构系数，用于计算轮廓
                case 1
                    obj.Devinfo.scanner.structure_factor = -1;
                case 2
                    obj.Devinfo.scanner.structure_factor = 1;
                case 3
                    obj.Devinfo.scanner.structure_factor = -1;
                otherwise
                    warning('unknow device, set structure_factor as default value')
                    obj.Devinfo.scanner.structure_factor = -1;
            end
            
            obj.TJ_data = [];
            obj.PT_data = [];
            obj.LJ_data = [];
            obj.PC_data = [];
            obj.PC_data_merged = [];
            obj.Surface = [];

            % 初始化完成后先保存一下
            obj.LSsave;
            obj.LSclean(2);
            obj.LSclean(3);
        end

        % Method

        % Include myMethod from external file
        %   测试
        test(obj);
        
        %   基础功能
        LSsave(obj);                                %   保存类文件
        LSclean(obj,mode)                           %   清理缓存文件
        LSsaveprofile(obj,varargin);                %   保存截面图片

        %   通讯功能
        obj = CP4Printer(obj);                      %   连接打印机
        obj = DC4Printer(obj);                      %   断开打印机
        obj = CP4Scanner(obj);                      %   连接扫描仪
        obj = DC4Scanner(obj);                      %   断开扫描仪
        
        %   轨迹处理
        obj = loadDXF(obj);                         %   读取dxf文件
        obj = getTrajectory(obj);                   %   轨迹提取
        obj = goInterpolation(obj);                 %   轨迹加密
        obj = saveCode4Print(obj);                  %   保存gcode4print
        obj = saveModifiedGcode(obj,varargin);      %   保存gcode4print
        obj = saveCode4Scan(obj);                   %   保存gcode4scan

        %   扫描相关
        obj = goScanning(obj);                      %   线条扫描
        [coordinate,profile]=getProfile(obj,a);     %   获取截面
        [data_coordin,data_profile] = LJ_G5000_P_cmd(obj,A,test_flag);%   处理原始数据

        %   拐角处理
        %   线条处理
        %   延迟处理
        
        
        %   数据处理
        obj = PC_process(obj,plot_flag);            %   点云拼接-自动精调 obj = PC_process(obj,1); 
        pc  = PC_process_adv(obj,pc,n,o,m);         %   点云拼接-手动粗调 obj = PC_process(obj,1); 
        obj = LS_plane_fitting(obj,plot_flag);      %   平面拟合 obj = LS_plane_fitting(obj,1); 
        obj = LS_surface_fitting(obj,plot_flag);    %   曲面拟合 obj = LS_surface_fitting(obj,1);
        obj = LS_tilt_correction(obj,plot_flag);    %   倾角矫正 obj = LS_tilt_correction(obj,1);
        obj = LS_trajectory_comparison(obj,adjust); %   轨迹对比 obj = LS_trajectory_comparison(obj,[0 0 0 0 0 0]);
        obj = LShistogram(obj);                     %   绘制数据直方图 obj = LShistogram(obj);
        obj = LS_strand_extraction(obj);            %   线条提取 obj = LS_strand_extraction(obj); 
        obj = LS_strand_grouping(obj,eps,minpts);   %   线条分组 obj = LS_strand_grouping(obj,0.5,220); 
        obj = LS_group_selection(obj,slct);         %   分组数据选择 obj = LS_group_selection(obj,[1 2]);
        obj = LS_voxelization(obj);                 %   体素处理 obj = LS_voxelization(obj);
        obj = LS_skeleton_extraction_1D(obj,varargin);% 骨架提取 obj = LS_skeleton_extraction_1D(obj); %mode2还不能用
        obj = LS_skeleton_extraction_3D(obj,varargin);% 骨架提取 obj = LS_skeleton_extraction_3D(obj); %还不能用
        obj = LS_profile_extruction(obj,varargin);  %   截面提取 obj = LS_profile_extruction(obj);  
        obj = LS_profile_process(obj,varargin);     %   截面分析 obj = LS_profile_process(obj,'mode',1); obj = LS_profile_process(obj,'mode',2);
        obj = LS_deviation_calculation(obj,varargin);%  偏差计算 obj = LS_deviation_calculation(obj);
        obj = LS_strand_model(obj,varargin);        %   截面模型 obj = LS_strand_model(obj);
        obj = LS_trajectory_modification(obj,varargin);%轨迹优化 obj = LS_trajectory_modification(obj);
        obj = LS_process_optimization(obj,varargin);%   参数优化 处理密度较高，这里需要进行离散化处理，
        % f = LS_surface_fitting_gen(A);           %   曲面拟合 obj = LS_surface_fitting(obj,1);

        %   绘图

    end
end