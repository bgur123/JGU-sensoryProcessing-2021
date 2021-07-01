function [frameInfo, microscopeSettings] = getXmlInfo(filename)

narginchk(1, 1);
if ~exist(filename, 'file'), error(['Could not find file: ' filename]); end

try
   tree = xmlread(filename);
catch
   error('Failed to read XML file %s.',filename);
end

%%

% Test file
% filename = 'TSeries-10282015-1006-427.xml';
% filename = 'TSeries-01132016-0936-020.xml';

xmlStruct = xml2struct(filename);

% First node is always PVScan.
xmlStruct = xmlStruct.PVScan;


%% Get parameters of microscope.
twoPhotonParamsStruct = xmlStruct.PVStateShard.PVStateValue;
nParameters = numel(twoPhotonParamsStruct);
fieldNameArray = {};
for iParam = 1: nParameters 
    % Get field names of structure to know if it has indexed values, e.g.
    % two values of laser power, main and 1040 lasers.
    fieldName = fieldnames(twoPhotonParamsStruct{iParam});
    fieldNameArray = [fieldNameArray; fieldName];
    fieldNameArray = unique(fieldNameArray);
    fieldName = fieldnames(twoPhotonParamsStruct{iParam});
    currentParam = twoPhotonParamsStruct{iParam};
    if ~sum(isfield(currentParam, {'IndexedValue', 'SubindexedValues'}))
        fieldName = currentParam.Attributes.key;
	    fieldValue = currentParam.Attributes.value;
	    microscopeSettings.(fieldName) = fieldValue;
    elseif isfield(currentParam, 'IndexedValue')
        parameterName = currentParam.Attributes.key;
        indexName = parameterName;
        paramIdxs = currentParam.IndexedValue;
        nIndexes = numel(paramIdxs);
        if nIndexes == 1
            hasDescription = isfield(paramIdxs.Attributes, 'description');
            index = paramIdxs.Attributes.index;
            hasNameOnIndex = ~(isempty(str2num(index)) || isnumeric(str2num(index)));
            if hasDescription
                indexName = paramIdxs.Attributes.description;
            elseif hasNameOnIndex
                indexName = paramIdxs.Attributes.index;
            end
            % Rename variables that always come with the same invalid name.
            if ~isvarname(indexName)
                switch indexName
                    case '1040'
                        indexName = 'secondary';
                    case 'insight control'
                        indexName = 'insightControl';
                    case 'PMT 1 HV'
                        indexName = 'PMT1_HV';
                    case 'PMT 2 HV'
                        indexName = 'PMT2_HV';
                    otherwise
                        error(['Variable name invalid,' ...
                               'parent variable not recognized: "' ...
                               indexName '"']);
                end
            end
%             if ~isvarname(indexName)
% 
%                 prompt = ['Invalid variable name for: "' indexName ...
%                         '" in parameter: "' parameterName ...
%                         '"\n Define valid name:\n \n' ];    
%                 indexName = input(prompt, 's');
%             end
            indexValue = paramIdxs.Attributes.value;
            if ~strcmp(indexName, parameterName)
                microscopeSettings.(parameterName).(indexName) = indexValue;
            else
                microscopeSettings.(parameterName) = indexValue;
            end                
        else
            for jIndexes = 1: nIndexes
                Attributes = paramIdxs{jIndexes}.Attributes;
                hasDescription = isfield(Attributes, 'description');
                index = paramIdxs{jIndexes}.Attributes.index;
                hasNameOnIndex = isempty(str2num(index));
                if hasDescription
                    indexName = paramIdxs{jIndexes}.Attributes.description;
                elseif hasNameOnIndex
                    indexName = paramIdxs{jIndexes}.Attributes.index;
                end
                % Rename variables that always come with the same invalid name.
                if ~isvarname(indexName)
                    switch indexName
                        case '1040'
                            indexName = 'secondary';
                        case 'insight control'
                            indexName = 'insightControl';
                        case 'PMT 1 HV'
                            indexName = 'PMT1_HV';
                        case 'PMT 2 HV'
                            indexName = 'PMT2_HV';
                        otherwise
                            indexName
                            error('Variable name invalid, parent variable not recognized');
                    end
                end
                    
%                 if ~isvarname(indexName)
%                     prompt = ['Invalid variable name for: ' indexName ...
%                             ' in parameter: ' parameterName ...
%                             '\n Define valid name:\n \n' ];    
%                     indexName = input(prompt, 's');
%                 end
                indexValue = paramIdxs{jIndexes}.Attributes.value;
                microscopeSettings.(parameterName).(indexName) = indexValue;
            end
        end
    else
        parameterName = currentParam.Attributes.key;
        indexName = parameterName;
        paramSubIdxs = currentParam.SubindexedValues;
        nSubIndexes = numel(paramSubIdxs);
        for jSubIndexes = 1: nSubIndexes
            if iscell(paramSubIdxs)
                Attributes = paramSubIdxs{jSubIndexes}.Attributes;
                index = paramSubIdxs{jSubIndexes}.Attributes.index;
            else
                Attributes = paramSubIdxs.Attributes;
                index = paramSubIdxs.Attributes.index;
            end
            hasDescription = isfield(Attributes, 'description');
            hasNameOnIndex = isempty(str2num(index));
            if hasDescription
                indexName = paramSubIdxs{jSubIndexes}.Attributes.description;
                SubindexedValue = paramSubIdxs{jSubIndexes}.SubindexedValue;
                indexValue = SubindexedValue.Attributes.value;
                microscopeSettings.(parameterName).(indexName) = indexValue;
            elseif hasNameOnIndex 
                indexName = paramSubIdxs{jSubIndexes}.Attributes.index;
                SubindexedValue = paramSubIdxs{jSubIndexes}.SubindexedValue;
                % Added after Bruker piezo installation on 12.01.2016.
                nSubIndexedValues = numel(SubindexedValue);
                if nSubIndexedValues == 1
                    indexValue = SubindexedValue.Attributes.value;
                    microscopeSettings.(parameterName).(indexName) = indexValue;
                else
                    for kSubIndexedValues = 1: nSubIndexedValues
                        Attributes = SubindexedValue{kSubIndexedValues}.Attributes;
                        indexValue = Attributes.value;
                        indexName = Attributes.description;
                        if not(isempty(strfind(indexName, 'Piezo')))
                            indexName = 'Piezo400Microns';
                        end
                        microscopeSettings.(parameterName).(indexName) = indexValue;
                    end
                end
            else
                paramSubIdxs = paramSubIdxs.SubindexedValue;
                nSubIndexes = numel(paramSubIdxs);
                for kSubIndexes = 1: nSubIndexes
                    Attributes = paramSubIdxs{kSubIndexes}.Attributes;
                    indexValue = Attributes.value;
                    indexName = Attributes.description;
                    microscopeSettings.(parameterName).(indexName) = indexValue;
                end
            end
        end
    end
    
    
        
end
%% Extract metadata from frames:


% Stimulus sequence.
stimulusFrames = xmlStruct.Sequence(1);
stimulusFrames = rmfield(stimulusFrames, 'PVStateShard');
nStimFrames = numel(stimulusFrames.Frame);
stimFrames{nStimFrames} = '';
for jStimFrame = 1 : nStimFrames
    currentFrame = stimulusFrames.Frame{jStimFrame};
    stimFrames{jStimFrame}.channel = currentFrame.File.Attributes.channel;
    stimFrames{jStimFrame}.channelName = currentFrame.File.Attributes.channelName;
    stimFrames{jStimFrame}.fileName = currentFrame.File.Attributes.filename;
    stimFrames{jStimFrame}.lastGoodFrame = currentFrame.ExtraParameters.Attributes.lastGoodFrame;
    stimFrames{jStimFrame}.absoluteTime = currentFrame.Attributes.absoluteTime;
    stimFrames{jStimFrame}.index = currentFrame.Attributes.index;
    stimFrames{jStimFrame}.parameterSet = currentFrame.Attributes.parameterSet;
    stimFrames{jStimFrame}.relativeTime = currentFrame.Attributes.relativeTime;
end


%% Save frame metadata.
frameInfo.stimulusFrames = stimFrames;

end