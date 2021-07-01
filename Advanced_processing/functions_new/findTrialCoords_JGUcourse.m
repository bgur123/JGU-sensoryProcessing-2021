function epochCoords = findTrialCoords_JGUcourse(stimTrace)
% findTrialCoords()  Finds the change of epochs in a given time series.
%   
%   epoch_coordinates = findTrialCoords(rois)
%   	IN1: roi -> a struct of ROI coming from the pData.
%       OUT1: epoch_coordinates -> cell array of epochs which contain 
%                                  time points of a given epoch's trials
%                                  arranged as -> [baseStart epochStart
%                                  epochEnd baseEnd]
%       
epoch_trace_frames = stimTrace;

% Find the baseline conditions
base_epoch_n = 0;
base_coords_beg = find(diff(epoch_trace_frames==base_epoch_n)==1) + 1;
base_coords_beg = [0; base_coords_beg];

base_coords_end = find(diff(epoch_trace_frames==base_epoch_n)==-1) ;
base_reps = min([length(base_coords_beg),length(base_coords_end)]);
base_coords_beg = base_coords_beg(1:base_reps);
base_coords_end = base_coords_end(1:base_reps);
base_length = mode(base_coords_end - base_coords_beg);

epochs = unique(epoch_trace_frames);
epoch_n = length(epochs);

for iEpoch = 1:epoch_n
    
    curr_epoch = sprintf('Epoch_%d',epochs(iEpoch));
    curr_epoch_n = epochs(iEpoch);
    
    epochCoords.(curr_epoch) = {};
    % Don't take the baseline epoch
    if curr_epoch_n == base_epoch_n
        for baseTrial = 1:base_reps
            epochCoords.(curr_epoch){baseTrial}= [nan nan base_coords_beg(baseTrial) base_coords_end(baseTrial)];
        continue
        end
    end
    
    % Find the trial start and ends
    epoch_beg = find(diff(epoch_trace_frames==curr_epoch_n)==1) + 1;
    epoch_end = find(diff(epoch_trace_frames==curr_epoch_n)==-1) ;
    completed_trial_n = min([length(epoch_beg),length(epoch_end)]); % Don't use if the trial ended prematurely

    % Arrange it in a list
    for iTrial = 1:completed_trial_n
        base_beg = epoch_beg(iTrial)-base_length;

        trial_beg = epoch_beg(iTrial);
        trial_end = epoch_end(iTrial);

        % Don't use the trial if it is not followed by a full baseline
        if epoch_end(iTrial)+base_length > length(epoch_trace_frames)
            continue
        else
            base_end = epoch_end(iTrial)+base_length;
        end

        epochCoords.(curr_epoch){iTrial} = [base_beg trial_beg trial_end base_end];
    end
end


