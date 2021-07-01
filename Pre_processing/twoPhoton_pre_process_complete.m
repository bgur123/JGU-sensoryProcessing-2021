%% 2p pre-processing

% clear previous variables and figures
clearvars;
close all
%% add paths of functions etc.
addpath(genpath('/path of your assignment folder')); 
% This is similar to manually adding selected folders and subfolders

%% get filename and file type to read
% a pop-up window allows you to navigate and find the intended folder
dirPath=uigetdir(pwd, 'Select a folder with "image.." in its name'); 
cd(dirPath); 
folder = dir('*.xml');
filename = [folder.name];
if isempty(filename)
    xmlDir = dir('T*');
    xmlDirName = xmlDir([xmlDir.isdir]).name;
    cd(xmlDirName)
    folder = dir('*.xml');
    filename = [folder.name];
end
filetype = 'xml';
%% read metadata to know dimensions of the dataset
% An 'xml' file contains metadata for each time series. 
% We extract the relevant information, using getXmlInfo function.
[imagingInfo, scanInfo] = getXmlInfo(filename);
% imagingInfo has detailed information of every single frame (image);
% scanInfo is a rather general information on microscope settings.

nFrames = numel(imagingInfo.stimulusFrames); % Number of frames (images).
% Each image is similar to a 2D matrix of pixels with dimensions: rows and columns
height = str2double(scanInfo.linesPerFrame);% lines per frame (i.e. rows).
width = str2double(scanInfo.pixelsPerLine);% pixels per line (i.e. columns).
% note the conversion of data type (string to double)

%% Motion correction/ image alignment 
% read the TIFF image files in a single matrix
% how many dimensions such a matrix will have?
imageArray = readTwoPhotonTimeSeries(filename, imagingInfo); 

% make reference image of maximum intensity projections from first 30 frames and visualize
refFrame = max(imageArray(:,:,1:30), [], 3); 
% getting an error? replace x,y,z with correct indices and dim with correct dimension
figure;
imagesc(refFrame);
title('Reference frame (first 30 frames)')
colorbar;

% align each frame by maximizing image crosscorrelation in the fourier space
alignedImArray=fourierCrossCorrelAlignment_mk(imageArray,refFrame,filetype);
% a name mismatch inside the function '_mk2': 'referenceFrame' in function definition, but 'refFrame' in implementaion.
% correct the function and save it with a different name (fourierCrossCorrelAlignment_mk already in the folder)

% visualize the effects of alignment in a figure
figure;
subplot(211)
meanFraw=mean(imageArray,3);% mean image of the raw images (note the mean across time dimension)
imagesc(meanFraw);
title('Mean image from RAW dataset')
colorbar;
subplot(212)
meanFaligned=mean(alignedImArray,3);% mean image of aligned images 
imagesc(meanFaligned);
colorbar;
title('Mean image from ALIGNED dataset')

%  visualize the effects of alignment in a movie
%% make a movie of images
close all
frameRate=15; % change to fit your taste
% movie of raw images
makeTimeSeriesMovie_mk(imageArray,'raw_series_framerate15', 'mp4', 15);
% movie of aligned images
makeTimeSeriesMovie_mk(alignedImArray,'aligned_series_framerate15', 'mp4', 15);
%% Optional: plot simple image statistics, remove any trends if necessary
close all
meanFaligned2=mean(mean(alignedImArray));% mean fluorescence time series (note the mean across all pixels of a frame)
figure;
plot(squeeze(meanFaligned2)); % do you get an error here? Can you fix it?

% % If the meanfluorescence gradually increases or decreases over time, you
% % may consider removing this trend. Uncomment the following:
% detrendedIm=detrend3(alignedImArray);
% meanFdetrended=mean(mean(detrendedIm));% mean fluorescence time series after detrending
% % compare the new time series by plotting it on the same graph
% hold on
% plot(squeeze(meanFdetrended));
% xlabel('time frames');
% ylabel('mean fluorescence (arbitrary units)')
% legend('aligned only','aligned and detrended')

%% ROI selection
% In order to see how neurons respond, we need to first select the 
% neuron regions (in this case, axon terminals). 
% For this we need a 'representative' image of our dataset.
% The 'reference image' created above for alignment can be used, however, 
% the average image is mostly used for this purpose since it tends to show
% neuron structures more robustly and won't have noise (due to averaging over many images).
avgImage = squeeze( sum( alignedImArray,3 ) ) / nFrames; % The average image 

figH_ROI = figure();
axesH_ROI = axes();
imagesc( avgImage , 'parent' , axesH_ROI );
title('Press Double click to confirm ROI after selection, ENTER to finish selection')

done = 0; 
ROInum = 0;
roi_colors = colormap('lines');
colormap gray
while ( ~done )
    
    ROInum = ROInum + 1 ;
    masks{ ROInum } = roipoly;
    % if mistakenly clicked 1 or 2 points
    if isempty(find(masks{ ROInum }))
        warning('Single point clicked, not taking ROI')
        continue
    end 
    currentColor = roi_colors(ROInum,:);
    alphamask( masks{ ROInum } , ...
        [currentColor(1) currentColor(2) currentColor(3)] , 0.33 );
    hold on ;
    done = waitforbuttonpress;
end
nMasks = ROInum;
close all
%% ------- Select background region --------
figH_BG = figure(); 
axesH_BG = axes();
imagesc( avgImage , 'parent' , axesH_BG );
colormap gray;
title('select background region');
BGMask = roipoly;
close all

%% ------- Extract ROI signals --------

% We need to extract signals one by one
maskSignals = zeros(nMasks,nFrames);
% maskSignals1Line = zeros(nMasks,nframes);
for iMask = 1:nMasks
    currMask = masks{iMask};  
    for iFrame = 1:nFrames
        currFrame = alignedImArray(:,:,iFrame);
        maskSignals(iMask,iFrame) = mean(currFrame(currMask));
    end
    % getting an error? replace x,y,z with correct variables acting as indices
    
%     [row,col] = ind2sub(size(currMask),find(currMask));
%     maskSignals1Line(iMask,:) = ...
%         squeeze(mean(alignedImArray(row,col,:),[1,2]));
end

%% Process stimulus file
cd(dirPath)
stim_file = dir('_stimulus_output*');
stimulusTrace = processStimInfo(stim_file,nFrames);

%% Visualize raw ROI traces against the stimulus trace
figure;
title('ROI signals')
plot(stimulusTrace'*max(max(maskSignals)),'--k','LineWidth',3,...
    'DisplayName','stimulus')
legend()
hold on;
plot(maskSignals','LineWidth',1.5)
% notice the ' operator to transpose the matrix. Why was it necessary? Try plotting without the transpose
xlabel('Frames')
ylabel('Raw signal (AU)')

%% ------- Save data --------
cd(dirPath)

% Create a data structure for saving necessary data
processedData = struct();
processedData.avgImage = avgImage;
processedData.masks = masks;
processedData.signals = maskSignals;
processedData.stimTrace = stimulusTrace;
processedData.BGMask=BGMask;

%Save the data
stringTimeSeries = split(filename,'.');
timeSeriesName = stringTimeSeries{1};
saveName = sprintf('%s_processed',timeSeriesName);
save(saveName,'processedData')
