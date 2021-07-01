function [] = Batch_Alignment_lsm()

% reference image for allignment
ref = 62;
% for image normalization
pre_stim = 3; % in seconds


folder_name = uigetdir(pwd);
if folder_name==0
    error('no folder selected')
end

display(folder_name);
files = dir([folder_name, '/*.lsm']);
num_lsm = size(files,1);
if num_lsm==0
    error('no LSM file available');
else
    a = dir([folder_name, '/aligned*']);
    if size(a,1)==0
        for i=1:num_lsm
            lsm_align_and_norm([folder_name, '/', files(i).name], ref, pre_stim);
%         tif_normalize(folder_name, saveit, plotit, fr, pre_stim)
        end
    else
        display('already aligned');
%         a = dir([folder_name, '/norm*']);
%         if size(a,1)==0
%             tif_normalize(folder_name, saveit, plotit, fr, pre_stim)
%         else
%             display('already normalized');
%         end
    end
end

end


