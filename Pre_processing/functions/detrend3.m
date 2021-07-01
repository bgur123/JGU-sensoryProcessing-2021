function A_detrended = detrend3(A,varargin) 
% detrend3 performs linear least squares detrending along the third dimension
% of a 3D matrix.
%% Author Info
% This function was written by Chad A. Greene of the University of Texas Institute 
% for Geophysics (UTIG), January 2017. http://www.chadagreene.com 
%% Error checks

assert(ndims(A)==3,'Input error: Matrix A must be 3 dimensional.') 
narginchk(1,2) 

%% Set defaults and parse inputs: 

N = size(A,3); % number of samples
t = (1:N)';    % default "time" vector

if nargin>1
   if isnumeric(varargin{1})
      t = squeeze(varargin{1}); 
      assert(isvector(t)==1,'Input error: Time reference vector t must be a vector.') 
   end
end

%% Perform mathematics: 

% Center and scale t to improve fit: 
t = (t(:)-mean(t))/std(t); 

% Reshape A such that each column contains a time series of a pixel: 
Ar = reshape(permute(A,[3 1 2]),size(A,3),[]);

% Detrend Ar by removing least squares trend: 
Ar = Ar - [t ones(N,1)]*([t ones(N,1)]\Ar); 

% Unreshape back to original size of A: 
A_detrended = ipermute(reshape(Ar,[size(A,3) size(A,1) size(A,2)]),[3 1 2]); 

end