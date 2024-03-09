function LSsave(obj)
try
    f1 = fullfile(obj.syset.path,obj.syset.file);
    % if ~exist(f1)
    %     save(f1)
    % else
    %     save(f1,"-append")
    % end
    save(f1)
    disp('file successful saved:')
    disp(f1)
catch ME
    disp(ME)
    error('failed to save file')
end