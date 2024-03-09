function obj = LS_group_selection(obj,slct)
%   select group such as [2 1 3]
%   then 
%   group 2 will be set as group 1
%   group 1 will be set as group 2
%   group 3 will keep as group 3
tn = obj.PC_data_merged.group_data.act;
tt = -ones(size(tn));
for i = 1:length(slct)
    tp=tn==slct(i);
    tt(tp)=i;
end
obj.PC_data_merged.group_data.act = tt;
% obj.PC_data_merged.fitted_PC.act  = tt>0;
% temp = obj.PC_data_merged.fitted_PC.X;
% obj.PC_data_merged.extra_data.Z(tn<0,3)=min(temp(:,3));

figure(3)
tm = tt(tt>0);
h = gscatter(obj.PC_data_merged.fitted_PC.X(tt>0,1),...
    obj.PC_data_merged.fitted_PC.X(tt>0,2),...
    tt(tt>0),...
    hsv(length(unique(tt(tt>0)))));