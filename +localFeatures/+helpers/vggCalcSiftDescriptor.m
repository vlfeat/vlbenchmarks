function [ validFrames descriptors ] = vggCalcSiftDescriptor( imagePath, frames, varargin )
%VGGCALCSIFTDESCRIPTORS Calc SIFT descriptors with VGG binary
%   [validFrames descriptors] = vggCalcSiftDescriptor( imagePath, frames,... )
%   Calculates descriptors of frames on an input image image using the vgg
%   'compute_descriptors_2.ln'. Variable frames can be matrix of frames or
%   filename of frames file. Variable validFrames then contains valid
%   frames for which descriptors were succesfully computed.
%
%   vggCalcSiftDescriptor( imagePath, frames, 'OptionName', OptionValue,...)
%   Specify further options.
%
%   Supported options:
%
%   Magnification:: [3]
%     Magnification factor of the regions size which is used for descriptor
%     calculation.
%
%   NoAngle:: [false]
%     When true, upright SIFT descriptors are calculated.

import localFeatures.*;

opts.magnification = 3;
opts.noAngle = false;
opts = vl_argparse(opts,varargin);
machineType = computer();
switch(machineType)
  case {'GLNXA64','GLNX86'}
    descrBinPath = fullfile(vggNewAffine.rootInstallDir,'compute_descriptors_2.ln');
  otherwise
    warning('Arch: %s not supported by vggCalcSiftDescriptor',machineType);
end

tmpName = tempname;
outDescFile = [tmpName '.sift'];

if size(frames,1) == 1 && exist(frames,'file')
  framesFile = frames;
elseif exist('frames','var')
  framesFile = [tmpName '.frames'];
  localFeatures.helpers.writeFeatures(framesFile,frames,[],'Format','oxford');
end

descrArgs = sprintf('-sift -i "%s" -p1 "%s" -o1 "%s"', ...
                     imagePath,framesFile, outDescFile);

if opts.magnification > 0
  descrArgs = [descrArgs,' -scale-mult ', num2str(opts.magnification)];
end

if opts.noAngle
  descrArgs = strcat(descrArgs,' -noangle');
end             

descrCmd = [descrBinPath ' ' descrArgs];

[status,msg] = system(descrCmd);
if status
  error('%d: %s: %s', status, descrCmd, msg) ;
end
[validFrames descriptors] = vl_ubcread(outDescFile,'format','oxford');
delete(outDescFile);

end

