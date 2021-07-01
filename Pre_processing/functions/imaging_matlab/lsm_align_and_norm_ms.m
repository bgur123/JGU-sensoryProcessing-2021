function  lsm_align_and_norm_ms

% function  lsm_align_and_norm_ms(filename)
% function  lsm_align_and_norm(filename, ref, pre_stim )

%ms: prompt for an image folder
[fname]=uigetdir;
e=dir(fname);
cd(fname);
out.fileloc = fname;
ind = strfind(out.fileloc,'/'); %Find the pattern / in string out.fileloc.
out.dataID = out.fileloc(ind(end-1)+1:(ind(end)-1));

% % % % % num=0;
% % % % % for i=3:length(e)
% % % % % %     if ((e(i).isdir)&&(e(i).name(1)=='I'))
% % % % %     if ((e(i).name(1)=='I'))
% % % % %         out.fileloc = [fname '/' e(i).name]
% % % % % %         basename = [fname '/' e(i).name];
% % % % % %         cd(basename);
% % % % % %         out.fileloc = basename;
% % % % %     end
% % % % % end

%ms: find the .lsm file 
d=dir('*.lsm');
% filename = [fname '/' d.name]
filename = [d.name];

[lsminf,scaninf,~] = lsminfo(filename);
% number of images
num_img = lsminf.TIMESTACKSIZE;
% image depth in bits
img_depth = scaninf.BITS_PER_SAMPLE;
% image size in # pixels
nr = scaninf.IMAGES_HEIGHT;
nc = scaninf.IMAGES_WIDTH;

% define output file
s = regexp(filename, '.lsm', 'split');
output_file = [s{1}, '_aligned.tif'];
% save time stamps
fout = [s{1} '_times.mat'];
ts = lsminf.TimeStamps.TimeStamps;
save(fout, 'ts');
fr = mean(diff(ts));

% % define ref
im = tiffread(filename,1:2:2*num_img);

ref_stack = zeros(nr,nc,30);
for ii = 1:30
    ref_stack(:,:,ii)=im(ii).data;
end
ref = max(ref_stack, [], 3);
% ref = uint8(ref);

% read reference image
% im = tiffread(filename, ref*2-1);
% f = im2double(im.data);
f = im.data;


im = tiffread(filename,1:2:2*num_img);
I = zeros(nr*nc, num_img);
for j = 1:num_img
    g = im2double(im(j).data);
    [output, Greg] = dftregistration(fft2(g),fft2(f),1);
    deltar = output(1,3);
    deltac = output(1,4);
    phase = output(1,2);
    Nr = ifftshift(-fix(nr/2):ceil(nr/2)-1);
    Nc = ifftshift(-fix(nc/2):ceil(nc/2)-1);
    [Nc, Nr] = meshgrid(Nc,Nr);
    g_reg = ifft2(fft2(g).*exp(1i*2*pi*(deltar*Nr/nr+deltac*Nc/nc))).*exp(-1i*phase);
    g_reg = uint8(g_reg*2^img_depth);
    if j==1
        imwrite(g_reg, output_file);
    else
        imwrite(g_reg, output_file, 'WriteMode', 'append');
    end
    
    % ms let's try this: put g_reg into a matrix and keep this in matlab
    % format
    unregIm(:,:,j) = g;
    regIm(:,:,j) = (g_reg);
   
    
    % median filter - needed for normalization
    fm = medfilt2(g_reg, [5 5]);
    I(:,j) = reshape(fm, nr*nc,1)+1;
end

%ms: could also use filtered Image Sequence:
ImSeq = reshape(I,[nr,nc,num_img]);
% out.ch1a = ImSeq;

%store unaligned image in output
out.ch1 = im2double(unregIm);

%store aligned image in output
out.ch1a = im2double(regIm);


%%
% read stimulus_output file and add stimulus information to out 
% (taken from read_roi_data_all_1ch_mac or clean_up_dir2 within) 


%imaging information from reading lsm file goes here.
%         out.xml.datetime = out.xml.datetime{1}(1:(ind{1}));

out.xml.frametime = fr; %time in s to scan a frame
%         temp = xml_read_1ch(d(2).name,'DimensionDescription DimID="T"',3);
%         out.xml.framerate = 1/temp;
out.xml.framerate = 1/out.xml.frametime; 
      
%         out.xml.zdepth = temp;
out.xml.zdepth = scaninf.SAMPLE_0Z;

%         temp = xml_read_1ch(d(2).name,'Voxel-Width',2);
%         out.xml.xres = temp/1000;
out.xml.xres = lsminf.VoxelSizeX;
%         
%         temp = xml_read_1ch(d(2).name,'Voxel-Height',2);
%         out.xml.yres = temp/1000;
out.xml.yres = lsminf.VoxelSizeY;

        
%         temp = xml_read_1ch(d(2).name,'Zoom',2);
%         out.xml.zoom = temp;
out.xml.zoom = scaninf.ZOOM_X;

out.xml.rotation = scaninf.ROTATION;
out.xml.detectorgain = scaninf.DETECTOR_GAIN;
out.xml.bitrate = scaninf.BITS_PER_SAMPLE;
out.xml.wavelength = scaninf.WAVELENGTH;
out.xml.laserpower = scaninf.POWER;
out.xml.objective = scaninf.ENTRY_OBJECTIVE;

%         temp=xml_read_1ch(d(2).name,'Scan Speed',2);
%         out.xml.scanper = temp;
%         

        
out.xml.pixperline = lsminf.DimensionX;
        
%         temp = xml_read_1ch(d(2).name,'Format-Height',2);
%         out.xml.linesperframe = temp;
out.xml.linesperframe = lsminf.DimensionY;
        
%         temp = xml_read_1ch(d(2).name,'<FrameCount>',1);
%         temp = temp{1};
%         bind = strfind(temp,' ');
%         out.xml.frames = str2num(temp(bind(end-1):bind(end)));
out.xml.frames = lsminf.TIMESTACKSIZE;

% %         temp = xml_read_1ch(d(1).name,'<Dwell_Time>',0);
%         out.xml.dwellt = (1/out.xml.scanper)*10^6/out.xml.pixperline; % temp!



%madhura: fix this to work for our stimulus output file (or just try to understand what's
%happening)


d = dir('_stimulus_output*');
A = importdata(d.name);
ch3 = A.data(:,4); %was 3
frame_nums = A.data(:,8); %was 7

fid=fopen(d.name,'r');
currline=fgetl(fid);
ind = strfind(currline,'\');
stim_type = currline(ind(end)+1:end-5);
fclose(fid);

%find average value of stimulus for each imaging frame
avrstimval = zeros(A.data(end,8),1); % 8s were all 7
fstimval = zeros(A.data(end,8),1);
fstimpos1 = zeros(A.data(end,8),1);
fstimpos2 = zeros(A.data(end,8),1);
for k = 1:(A.data(end,8))
    inds = find(A.data(:,8) == k);
    if(~isempty(inds))
        stimval = A.data(inds,4);
%         stimvalcont = A.data(inds,3); %could add this if needed
        stimpos1 = A.data(inds,5);
        stimpos2 = A.data(inds,7);
        avrstimval(k) = mean(stimval);
        fstimval(k) = stimval(1);
        fstimpos1(k) = stimpos1(1);
        fstimpos2(k) = stimpos2(1);
    end
end

save('stim','ch3','avrstimval','fstimval','frame_nums','stim_type','fstimpos1','fstimpos2');


% load('stim');
out.ch3 = ch3;
out.avrstimval = avrstimval;
out.fstimval = fstimval;
out.frame_nums = frame_nums;
out.stim_type = stim_type;
out.fstimpos1 = fstimpos1;
out.fstimpos2 = fstimpos2;
        
        
% % % % % %                 out.ch1a = zeros(out.xml.linesperframe,out.xml.pixperline,out.xml.frames,'uint16');
% % % % % % %         out.ch2a = zeros(out.xml.linesperframe,out.xml.pixperline,out.xml.frames,'uint16');
% % % % % %         %strs = {'CH1_aligned','CH2_tocoords'};
% % % % % %         strs = {'Ch1_aligned','Ch2_tocoords'};
% % % % % %         for j = 1%:2
% % % % % %             d=dir(sprintf('*%s.tif',strs{j}));
% % % % % %             if (length(d)==1)
% % % % % %                 for k = 1:out.xml.frames
% % % % % %                     str = sprintf('out.ch%da(:,:,k)=imread(d.name,k);',j);
% % % % % %                     eval(str);
% % % % % %                 end
% % % % % %             else
% % % % % %                 disp(['error in file set ' out.fileloc ' channel ' num2str(j)]);
% % % % % %             end
% % % % % %         end

        save('data_file','out');

        cd ..
%% play with aligned and non-aligned image sequences
% make movie of aligned image series and play

% %make movie of raw data
n=num_img;
for j=1:n
    image(im(j).data)
    N(j) = getframe;
end
% % movie(N)
% movie2avi(N,'original_image')
% 
% %make movie of aligned data before filtering
n=num_img;
for j=1:n
    imagesc(squeeze(regIm(:,:,j)))
    M(j) = getframe;
end
% % movie(M)
% movie2avi(N,'aligned_noFilter')
% 
% 
% %make movie of aligned data after median filtering
% n=num_img;
% for j=1:n
%     imagesc(squeeze(ImSeq(:,:,j)))
%     K(j) = getframe;
% end
% % movie(M)
% movie2avi(K,'aligned_and_medfilt2')

%% code from original function that claculates dF/Fs and creates another tiff that displays that
%relies on some prestim image that we typically don't record.



% % deltaF/F0
% Inorm = I;
% for k=1:nr*nc
%     I0(k) = mean(Inorm(k,1:round(pre_stim/fr)));
%     Inorm(k,:) = 100*(Inorm(k,:)-I0(k))/I0(k);
% end
% Imax = max(max(Inorm));
% Imin = min(min(Inorm));
% 
% % save normalized images
% output_file = [s{1}, '_aligned_norm.tif'];
% imwrite(uint8(reshape(I0, nr, nc)), output_file);
% for j=1:num_img
%     imwrite(uint8(reshape(Inorm(:,j), nr, nc)), output_file, 'WriteMode', 'append');
% end
% 
% end
% 
