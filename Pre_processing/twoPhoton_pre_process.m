%% 2p pre-processing

% clear previous variables and create new hardcoded ones if any
clearvars;
% nChannels=2; % Katja's data will mostly have only one channel, namely ch 2
%% add paths of functions etc.
% addpath(genpath('/Users/burakgur/Documents/GitHub/JGU-sensory-processing/week2-ca-imaging/2p_preProcess'));

%% get filename and file type to read
dirPath=uigetdir(pwd, 'Select the image folder');
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
[imagingInfo, scanInfo] = getXmlInfo(filename);%information for every single frame, as well as scan settings
nFrames = numel(imagingInfo.stimulusFrames); % Number of frames.
height = str2double(scanInfo.linesPerFrame);% lines per frame.
width = str2double(scanInfo.pixelsPerLine);% pixels per line.
stimulusFrames = [imagingInfo.stimulusFrames{:}];

%% Motion correction/ image alignment 
% read the TIFF images in a single matrix
close all
imageArray = readTwoPhotonTimeSeries(filename, imagingInfo); 

% make reference image of maximum intensity projections from first 30 frames and visualize
refFrame = max(imageArray(:,:,1:30), [], 3); 
figure;
imagesc(refFrame);
colorbar;

% align each frame by maximizing image crosscorrelation in the fourier space
alignedImArray=fourierCrossCorrelAlignment_mk(imageArray,refFrame,filetype); 

% visualize the effects of alignment
subplot(211)
meanFraw=mean(imageArray,3);% mean raw images
imagesc(meanFraw);
title('Mean image from RAW dataset')
colorbar;
subplot(212)
meanFaligned=mean(alignedImArray,3);% mean aligned image (note the mean across time dimension)
imagesc(meanFaligned);
colorbar;
title('Mean image from ALIGNED dataset')


%% make a movie of aligned images
close all
frameRate=15; % change to fit your taste
makeTimeSeriesMovie_mk(alignedImArray,'aligned_series_16bit_framerate15', 'mp4', 15);

%% Process stimulus file
cd(dirPath)
stim_file = dir('_stimulus_output*');
stimulusTrace = processStimInfo(stim_file,nFrames);

%% ROI selection
% In order to select see how neurons respond, we need to first select the 
% neurons. For this we need a "representative" image of our dataset.
% The average image is mostly used for that purpose since it will show us
% the neuron structures and won't have noise (due to averaging over
% many images)
avgImage = squeeze( sum( alignedImArray,3 ) ) / nFrames; % The average image 
Image_max = max( alignedImArray,[],3 ) ; % The max image

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
%     [row,col] = ind2sub(size(currMask),find(currMask));
%     maskSignals1Line(iMask,:) = ...
%         squeeze(mean(alignedImArray(row,col,:),[1,2]));
end

figure;
title('ROI signals')
plot(stimulusTrace'*max(max(maskSignals))/max(stimulusTrace),'--k','LineWidth',3,...
    'DisplayName','stimulus')
legend()
hold on;
plot(maskSignals','LineWidth',1.5)
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
processedData.frameRate = 1/str2num(scanInfo.framePeriod);

%Save the data
stringTimeSeries = split(filename,'.');
timeSeriesName = stringTimeSeries{1};
saveName = sprintf('%s_processed',timeSeriesName);
save(saveName,'processedData')

