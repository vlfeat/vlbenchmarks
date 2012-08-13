function [ validFrames descriptors ] = vlCalcSiftDescriptors( imagePath, frames, varargin )
%CALCSIFTDESC Calculate SIFT descriptors of frames
%
% [validFrames descriptors] = vlCalcSiftDescriptors(imagePath, frames,...) 
%  Calculates SIFT descriptors using the VlFeat covariant frames detector. 
%  The number of output frames in 'validFrames' and number of descriptors 
%  can differ from the number of input frames. Variable frames can be array
%  of frames or file with stored frames. Please note that for disc frames 
%  Gauss. scale-space is used for descriptors calculation.
%
%  vlCalcSiftDescriptors( imagePath, frames, 'OptionName', OptionValue,...)
%   Specify further options.
%
%   Supported options:
%
%   Magnification:: [3]
%     Magnification factor of the regions size which is used for descriptor
%     calculation.
%
%   ForceOrientation:: [false]
%     When true, orientation invariant SIFT descriptors are calculated even
%     for unoriented frames. Returned validFrames are also oriented.

opts.forceOrientation = false;
opts.magnification = 3;
opts = vl_argparse(opts,varargin);

if exist('frames','file')
  [frames] = vl_ubcread(frames);
end

numValues = size(frames,1);

if numValues < 3 || numValues > 6
  error('Invalid frames format');
end

hasAffineShape = numValues > 4;
hasOrientation = numValues == 4 || numValues == 6;
if nargin >= 3
  if opts.forceOrientation
    hasOrientation = true; % force calculating orientations
  end
end

image = imread(imagePath);
if(size(image,3)>1), image = rgb2gray(image); end
image = single(image); % If not already in uint8, then convert

[validFrames descriptors] = vl_covdet(image, 'Frames', frames,...
    'AffineAdaptation', hasAffineShape, 'Orientation', hasOrientation,...
    'Magnif',opts.magnification);

end

