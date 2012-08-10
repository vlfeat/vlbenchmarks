function [ frames descriptors ] = vggCalcSiftDescriptor( imagePath, framesFile, magnification, noAngle )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

if nargin < 3
  noAngle = false;
elseif nargin < 2
  magnification = -1;
end

switch(machineType)
  case {'GLNXA64','GLNX86'}
    descrBinPath = fullfile(vggNewAffine.rootInstallDir,'compute_descriptors_2.ln');
  otherwise
    warning('Arch: %s not supported by vggCalcSiftDescriptor',machineType);
end

tmpName = tempname;
outDescFile = [tmpName '.sift'];

descrArgs = sprintf('-sift -i "%s" -p1 "%s" -o1 "%s"', ...
                     imagePath,framesFile, outDescFile);

if magnification > 0
  descrArgs = [desc_param,' -scale-mult ', num2str(magnification)];
end

if noAngle
  descrArgs = strcat(descrArgs,' -noangle');
end             

descrCmd = [descrBinPath ' ' descrArgs];

[status,msg] = system(descrCmd);
if status
  error('%d: %s: %s', status, descrCmd, msg) ;
end
[frames descriptors] = vl_ubcread(outDescFile,'format','oxford');
delete(outDescFile);

end

