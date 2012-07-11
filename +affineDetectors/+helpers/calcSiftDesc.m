function [ validFrames descriptors ] = calcSiftDesc( image, frames, varargin )
%CALCSIFTDESC Calculate SIFT descriptors of frames
%
% [validFrames descriptors] = calcSiftDesc(image, frames,...) Calculates 
% SIFT descriptors using the VlFeat covariant frames detector. The number 
% of output frames in 'validFrames' and number of descriptors can differ
% from the number of input frames. Further arguments are passed to
% vl_covdet function call.

numValues = size(frames,1);

if numValues < 3 || numValues > 6
  error('Invalid frames format');
end

hasAffineShape = numValues > 4;
hasOrientation = numValues == 4 || numValues == 6;

if(size(image,3)>1), image = rgb2gray(image); end
image = single(image); % If not already in uint8, then convert

[validFrames descriptors] = vl_covdet(image, 'Frames', frames,...
    'AffineAdaptation', hasAffineShape, 'Orientation', hasOrientation,...
    varargin{:});

end

