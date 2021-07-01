%% Analysis of L2 and L3 responses to 5 s full-field flashes

clearvars;
close all;

%% specify CONSTANTS
stimulusCode = 'LocalCircle_5sec_220deg_0degAz_0degEl_Sequential_LumDec_LumInc';
REGION = 'AT';  % AT for axon terminals. Some experiments may require imaging soma or dendrites instead.
neuronType = 'L2'; % L2 or L3

%% add paths of the code and specify the folder of pData
addpath(genpath('/your_code_path')) % or manually add the main folder and subfolders
pDataPath=uigetdir('select the pData folder');
%% background subtraction and saving the new signals
% do this for each fly folder one by one
done=0;
while (~done)
    % fetch the .mat file saved on the last step
    dirPath=uigetdir(pwd, 'Select a folder with "image.." in its name');
    cd(dirPath)
    filePattern=fullfile(pwd,'TSeries*processed.mat');
    allFiles = dir(filePattern);
    if length(allFiles)==1
        load(allFiles.name)
    elseif length(allFiles)>1
        fprintf('More than one processed data files in this folder!')
%         continue
    else
        fprintf('No processed data files in this folder!')
%         continue
    end
    
    % retrieve the aligned images and remaining info
    [alignedImArray,xml] = retrieve_necessary_variables(dirPath);
    
    % subtract background signal from averaged ROI signals
    dSignals = zeros(size(processedData.signals));
  
    for iFrame = 1:size(processedData.signals,2)
        currFrame = alignedImArray(:,:,iFrame);
        dSignals(:,iFrame) = processedData.signals(:,iFrame) - mean(currFrame(processedData.BGMask));
    end
    processedData.dSignals=dSignals;
    processedData.xml=xml;
    % save the new data with a proper filename
    nameParts=split(dirPath,"/");
    save(fullfile(pDataPath,[nameParts{end-1},'_',nameParts{end},'_pData.mat']),'processedData');
    done=input('Done processing all .mat files? enter 1 for yes, 0 for no');
end

%% find processed data files for specified neuron type and 5s fff stimulus
% The spreadsheet Summary_database.xlsx contains information for each processed data file.
% This section identifies the files that have matching stimulus and driver line information. 
if  strcmp(neuronType,'L2')
    genotype_string = ['L2 >> GCaMP6f, region: ' REGION];
    driverCode = 'UASGCaMP6F_L221DhhGal4_cross_to_w';    
elseif strcmp(neuronType,'L3')
    genotype_string = ['L3 >> GCaMP6f, region: ' REGION];
    driverCode = 'UASGCaMP6f_L3MH56Gal4_cross_to_w';
else
    fprintf('This script does not analyse your neurons')
end

inds_summaryFile  = database_select_samples_ks(stimulusCode,driverCode);


%% read data from those files and aggregate for stimulus epochs
cd(pDataPath);

% create structures for each neuron
neurStructs = create_neuron_structure_all_ks(inds_summaryFile);

% interpolate data to bring it in the 10Hz format
neurData = load_neuron_data10Hz_byRegion(neurStructs,pDataPath, REGION);

% aggregate data by stimulus epochs
data = aggregate_fffall_means10Hz_BleedThruFix(neurData);

%% Separate data with positive and negative correlation with the stimulus
% negative correlation: 'normal' responses, positive correlation: 'inverted' responses
% correlate with stimulus to select normal and inverted ROIs
iRATE = 10; %rate at which data are interpolated
dur = size(data.rats,2);
DURS = 2;


% start with all the data
cur_mat = data.rats;
cur_IDs = data.flyID;
%clean up by zeros-only datasets and NaN dataset
inds = find(sum(cur_mat,2)~=0);
cur_mat = cur_mat(inds,:);
cur_IDs = cur_IDs(inds);
inds = ~isnan(sum(cur_mat,2));%ms: added these two lines, because there were NaN in dataset
cur_mat = cur_mat(inds,:);
cur_IDs = cur_IDs(inds);

cur_t = [1:size(cur_mat,2)]/iRATE;


%positive correlation with stimulus
Q = corr(nanmean(data.stims)',cur_mat');
% Q = corr(mean(mTm9LexA.stims)',cur_mat');
inds = find(Q>0.5); %finds the cells whose response correlates well with the stimulus 
cur_mat_pos = cur_mat(inds,:);
cur_IDs_pos = cur_IDs(inds);

%calculating means across flies for positive correlation
[x_pos,m_pos,e_pos] = mean_cat_full(cur_mat_pos,1,cur_IDs_pos);
%calculating the max for each trace
max_pos = max(x_pos,[],2)-1;


%negative correlation with stimulus
Q = corr(nanmean(data.stims)',cur_mat');
inds = find(Q<-0.5);
size(inds)
cur_mat_neg = cur_mat(inds,:);
cur_IDs_neg = cur_IDs(inds);

%calculating means across flies for negative correlation
[x_neg,m_neg,e_neg] = mean_cat_full(cur_mat_neg,1,cur_IDs_neg);
max_neg = max(x_neg,[],2)-1;

%% plot and visualize negatively correlated 'normal' responses
%plot negatively correlated cells, mean across flies
figure; hold on
subplot(2,1,1); 
cm=colormap('lines');
h2 = plot_err_patch_v2(cur_t,m_neg,e_neg,[0 0.5 0],[0 0.80 0]); %green
title([genotype_string ', neg corr, mean by fly']);
legend(h2,sprintf([genotype_string ', N = %d ( %d )'],size(x_neg,1),size(cur_mat_neg,1)),...
    'location','northeast');
plot(cur_t, (round(mean(data.stims))*0.1)+0.6)
ylim([-1.0 2.5]);
line([0 4],[0 0],'color',[0 0 0]); %for 2 s

% plot negatively correlated cells, individual flies
subplot(2,1,2);
t = [1:dur]/10;
plot(t,x_neg)
title('individual fly means');
ylim([-1.0 2.5]);
line([DURS DURS],[-0.6 0.6],'color',[0 0 0],'linestyle','--');
line([0 DURS],[0 0],'color',[0 0 0]);
set(gcf,'Color','w');
% niceaxes;

% plot negatively correlated cells, mean across ROIs
mROI_neg = mean(cur_mat_neg);
eROI_neg = std(cur_mat_neg,[],1)/sqrt(size(cur_mat_neg,1)); %S.E.M

figure; hold on
subplot(2,1,1);
cm=colormap('lines');
if strcmp(neuronType,'L2')
    h2 = plot_err_patch_v2(cur_t,mROI_neg-1,eROI_neg,[0.75 0 0.75],[0.75 0.5 0.75]);
elseif strcmp(neuronType,'L3')
    h2 = plot_err_patch_v2(cur_t,mROI_neg,eROI_neg,[0 0.5 0],[0 0.80 0]);
end
title([genotype_string ', neg corr, mean by ROI']);
legend(h2,sprintf([genotype_string ', N = %d ( %d )'],size(x_neg,1),size(cur_mat_neg,1)),...
    'location','northeast');
plot(cur_t, (round(mean(data.stims))*0.1)+0.6)
ylim([-0.8 2.0]); 
line([0 10],[0 0],'color',[0 0 0]); 

% plot negatively correlated cells, individual flies
subplot(2,1,2);
plot(t,cur_mat_neg)
title('individual fly means');
ylim([-0.8 3.0]);
line([DURS DURS],[-0.6 0.6],'color',[0 0 0],'linestyle','--');
line([0 DURS],[0 0],'color',[0 0 0]);
set(gcf,'Color','w');

%% plot and visualize positively correlated 'inverted' responses
%plot negatively correlated cells, mean across flies
figure; hold on
subplot(2,1,1); 
cm=colormap('lines');
h2 = plot_err_patch_v2(cur_t,m_pos,e_pos,[0 0.5 0],[0 0.80 0]); %green
title([genotype_string ', positive corr, mean by fly']);
legend(h2,sprintf([genotype_string ', N = %d ( %d )'],size(x_pos,1),size(cur_mat_pos,1)),...
    'location','northeast');
plot(cur_t, (round(mean(data.stims))*0.1)+0.6)
ylim([-1.0 2.5]);
line([0 4],[0 0],'color',[0 0 0]); %for 2 s

% plot negatively correlated cells, individual flies
subplot(2,1,2);
t = [1:dur]/10;
plot(t,x_pos)
title('individual fly means');
ylim([-1.0 2.5]);
line([DURS DURS],[-0.6 0.6],'color',[0 0 0],'linestyle','--');
line([0 DURS],[0 0],'color',[0 0 0]);
set(gcf,'Color','w');
% niceaxes;

% plot negatively correlated cells, mean across ROIs
mROI_neg = mean(cur_mat_pos);
eROI_neg = std(cur_mat_pos,[],1)/sqrt(size(cur_mat_pos,1)); %S.E.M

figure; hold on
subplot(2,1,1);
cm=colormap('lines');
if strcmp(neuronType,'L2')
    h2 = plot_err_patch_v2(cur_t,mROI_pos-1,eROI_pos,[0.75 0 0.75],[0.75 0.5 0.75]);
elseif strcmp(neuronType,'L3')
    h2 = plot_err_patch_v2(cur_t,mROI_pos,eROI_pos,[0 0.5 0],[0 0.80 0]);
end
title([genotype_string ', positive corr, mean by ROI']);
legend(h2,sprintf([genotype_string ', N = %d ( %d )'],size(x_pos,1),size(cur_mat_pos,1)),...
    'location','northeast');
plot(cur_t, (round(mean(data.stims))*0.1)+0.6)
ylim([-0.8 2.0]); 
line([0 10],[0 0],'color',[0 0 0]); 

% plot negatively correlated cells, individual flies
subplot(2,1,2);
plot(t,cur_mat_pos)
title('individual fly means');
ylim([-0.8 3.0]);
line([DURS DURS],[-0.6 0.6],'color',[0 0 0],'linestyle','--');
line([0 DURS],[0 0],'color',[0 0 0]);
set(gcf,'Color','w');