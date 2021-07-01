function [alignedImArray,xml] = retrieve_necessary_variables(dirPath)
% This function was created only to compensate for the deficit in the
% preprocessing code compiled for the Sensory processng course 2020.
% (deficit=BG time trace not saved.)
% Extremely inefficient if used otherwise.
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

[imagingInfo, scanInfo] = getXmlInfo(filename);
xml=scanInfo;
%% Motion correction/ image alignment 
imageArray = readTwoPhotonTimeSeries(filename, imagingInfo); 

% make reference image of maximum intensity projections from first 30 frames and visualize
refFrame = max(imageArray(:,:,1:30), [], 3); 

% align each frame by maximizing image crosscorrelation in the fourier space
alignedImArray=fourierCrossCorrelAlignment_mk(imageArray,refFrame,filetype);

%%
cd(dirPath)
end