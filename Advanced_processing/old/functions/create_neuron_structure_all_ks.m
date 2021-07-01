function out=create_neuron_structure_all_ks(inds)

T=readtable('Summary_database.xlsx','ReadVariableNames',1);
fname=T.fname;

out=[];

count=1;
for iInd=1:length(inds)
    %     ns=str2num(activecells{inds(ii)});
    if exist(fname{inds(iInd)})
        %         if (length(ns)==0)
        x=load(fname{inds(iInd)});
        nROIs=size(x.processedData.signals,1);
        %         end
        for iROI=1:nROIs
            out(count).name=fname{inds(iInd)};
            out(count).cell=iROI;
            count=count+1;
        end
    end
end



