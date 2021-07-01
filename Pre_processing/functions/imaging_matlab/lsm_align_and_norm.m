function  lsm_align_and_norm(filename, ref, pre_stim )

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

% read reference image
im = tiffread(filename, ref*2-1);
f = im2double(im.data);

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
    
    % median filter - needed for normalization
    fm = medfilt2(g_reg, [5 5]);
    I(:,j) = reshape(fm, nr*nc,1)+1;
end

ImSeq = reshape(I,[lsminf.DimensionY,lsminf.DimensionX,num_img]);
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
