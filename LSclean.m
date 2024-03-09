function LSclean(obj,mode)
if exist("mode")
    switch mode
        case 0 % 清理所有
            LSclean(obj,1);
            LSclean(obj,2);
            LSclean(obj,3);
        case 1 % 清理LaserScan类
            temp_dir = dir(obj.syset.path);
            if length(temp_dir)>2
                for i=3:length(temp_dir)
                    delete(fullfile(temp_dir(i).folder,temp_dir(i).name));
                end
            end
        case 2 % 清理pointCloud类输出目录
            temp_dir = dir(obj.syset.path_pc_out);
            if length(temp_dir)>2
                for i=3:length(temp_dir)
                    delete(fullfile(temp_dir(i).folder,temp_dir(i).name));
                end
            end
        case 3 % 清理pointCloud类缓存目录
            temp_dir = dir(obj.syset.path_pc_tmp);
            if length(temp_dir)>2
                for i=3:length(temp_dir)
                    delete(fullfile(temp_dir(i).folder,temp_dir(i).name));
                end
            end
    end
else
    warning("mode does not exist, please check")
end