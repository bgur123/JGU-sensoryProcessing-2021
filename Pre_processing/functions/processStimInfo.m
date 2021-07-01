function stimulusTrace = processStimInfo(d,nframes)

A = importdata(d.name);
ch3 = A.data(:,4); %was 3
frame_nums = A.data(:,8); %was 7

fid=fopen(d.name,'r');
currline=fgetl(fid);
ind = strfind(currline,'\');
stim_type = currline(ind(end)+1:end-5);
fclose(fid);

% Find average value of stimulus for each imaging frame.
nValidStimFrames = nframes;
avrstimval = zeros(nValidStimFrames,1); % 8s were all 7
stimulusTrace = zeros(nValidStimFrames,1);
fstimpos1 = zeros(nValidStimFrames,1);
fstimpos2 = zeros(nValidStimFrames,1);


 %How many total frames actually imaged
firstEntry = A.data(1,8);

for k = firstEntry:nValidStimFrames
    inds = find(A.data(:,8) == k);
    if(~isempty(inds))
        stimval = A.data(inds,4);
%         stimvalcont = A.data(inds,3); %could add this if needed
%         stimpos1 = A.data(inds,4);
%         stimpos2 = A.data(inds,6);
        stimpos1 = A.data(inds,5); %ms, for jl type stimulus output files
        stimpos2 = A.data(inds,7); %ms, for jl type stimulus output files
        avrstimval(k) = mean(stimval);
        stimulusTrace(k) = stimval(1);
        fstimpos1(k) = stimpos1(1);
        fstimpos2(k) = stimpos2(1);
        last_k_withStimEntries = k;

    %if scanning is faster than stimulus, use stimulus info of previous
    %frame that was written (last_k_withStimEntries):
    elseif(isempty(inds)) 
        inds = find(A.data(:,8) == last_k_withStimEntries); 
        stimval = A.data(inds,4);
%         stimvalcont = A.data(inds,3); %could add this if needed
%         stimpos1 = A.data(inds,4);
%         stimpos2 = A.data(inds,6);
        stimpos1 = A.data(inds,5); %ms, for jl type stimulus output files
        stimpos2 = A.data(inds,7); %ms, for jl type stimulus output files
        avrstimval(k) = mean(stimval);
        stimulusTrace(k) = stimval(1);
        fstimpos1(k) = stimpos1(1);
        fstimpos2(k) = stimpos2(1);
    end
end
end