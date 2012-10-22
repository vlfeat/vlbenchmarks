function [frames descriptors] = readFeaturesFile(featuresFile, varargin)
% READFEATURESFILE Read file exported by some of the older frame detectors.
%   FRAMES = READFEATURESFILE(FRAME_FILE_PATH) Reads FRAMES from a file
%   defined by FRAME_FILE_PATH
%
%   vl_ubcread cannot be used because some older detectors produce files
%   which contain length of the descriptors = 1 which the vl_ubcread function 
%   is not able to handle.
%
% Function accepts the following options:
%   'FloatDesc' ::
%      Feature file contains floating point descriptors.
% 

% Authors: Karel Lenc

% AUTORIGHTS
  import helpers.*;
  opts.floatDesc = false;
  opts = vl_argparse(opts, varargin);

  fid = fopen(featuresFile,'r');
  if fid==-1
    error('Could not read file: %s\n',featuresFile);
  end
  [header,count] = fscanf(fid,'%f',2);
  if count~= 2,
    error('Invalid frames file: %s\n',featuresFile);
  end
  descrLen = header(1);
  numFeatures = header(2);
  frames = zeros(5,numFeatures);
  if descrLen == 0 || descrLen == 1
    [frames,count] = fscanf(fid,'%f',[5 numFeatures]);
    if count~=5*numFeatures,
      error('Invalid frames file %s\n',featuresFile);
    end
  else
    descriptors = zeros(descrLen,numFeatures);
    for k = 1:numFeatures
      [frames(:,k), count] = fscanf(fid, '%f', [1 5]);
      if count ~= 5
        error('Invalid keypoint file (parsing keypoint %d, frame part)',k);
      end
      if opts.floatDesc
        [descriptors(:,k), count] = fscanf(fid, '%f', [1 descrLen]);
      else
        [descriptors(:,k), count] = fscanf(fid, '%d', [1 descrLen]);
      end
      if count ~= descrLen
        error('Invalid keypoint file (parsing keypoint %d, descriptor part)',k);
      end
    end
  end

  % Transform the frame properly
  frames(1:2,:) = frames(1:2,:) + 1;
  C = frames(3:5,:);
  den = C(1,:) .* C(3,:) - C(2,:) .* C(2,:) ;
  S = [C(3,:) ; -C(2,:) ; C(1,:)] ./ den([1 1 1], :) ;
  frames(3:5,:) = S;

  fclose(fid);
end