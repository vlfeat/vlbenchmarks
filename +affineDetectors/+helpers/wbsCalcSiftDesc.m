function [ validFrames descriptors ] = wbsCalcSiftDesc( image, frames, calcOrientation )
%CALCSIFTDESC Calculate SIFT descriptors of frames
%
% [validFrames descriptors] = calcSiftDesc(image, frames,...) Calculates 
% SIFT descriptors using the VlFeat covariant frames detector. The number 
% of output frames in 'validFrames' and number of descriptors can differ
% from the number of input frames.


numValues = size(frames,1);

if numValues < 3 || numValues > 6
  error('Invalid frames format');
end

if(size(image,3)>1), image = rgb2gray(image); end

numFrames = size(frames,2);
numValues = size(frames,1);
for i=1:numFrames
  sFrames(i).x = frames(1,i);
  sFrames(i).y = frames(2,i);
  sFrames(i).s = frames(3,i) .* 3;
  if numValues > 3
    sFrames(i).angle = frames(4,i);
  end
end


p.desc_factor=1;% - scale factor of measurement region.
p.estimate_angle=calcOrientation;% - (0 - no, 1 - SIFT, 2 - gravity vector).
p.compute_descriptor=1;% - (0 - no, 1 - SIFT, 2 - DCT).
p.output_format=0;% - (0 - keypoint structure, 1 - LAF structure).
%p.ignore_gradient_sign
p.verbose=0; %- verbose output.

[outFrames]  = affpatch(image, sFrames,p);

if calcOrientation
  validFrames = [[outFrames.x];[outFrames.y];[outFrames.s];[outFrames.angle];];
else
  validFrames = [[outFrames.x];[outFrames.y];[outFrames.s];[outFrames.angle];];
end

descriptors = reshape([outFrames(:).desc]',128,numel(outFrames));
end

