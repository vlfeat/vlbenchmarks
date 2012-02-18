% This class implements the genericDetector interface. The implementation
% wraps around the vgg implementation of MSER

classdef vggMser < affineDetectors.genericDetector
  properties (SetAccess=private, GetAccess=public)
    % The properties below correspond to parameters for vgg_mser

    % Yet to add options for detector

    softwareUrl
    binPath

  end

  methods
    % The constructor is used to set the options for vl_sift call
    % See help vl_sift for possible parameters
    % This varargin is passed directly to vl_sift
    function obj = vggMser(varargin)
      obj.detectorName = 'vggMser';
      % Do the third party software management here
      obj.softwareUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/mser.tar.gz';
      obj.binPath = 'thirdParty/vgg-mser/mser.ln';
    end

    function frames = detectPoints(obj,img)
      if(size(img,3) > 1), img = rgb2gray(img); end
      binDir = commonFns.extractDirPath(obj.binPath);

      tmpName = tempname;
      imgFile = [tmpName '.png'];
      featFile = [tmpName '.feat'];

      imwrite(img,imgFile);
      args = sprintf(' -t 2 -es 2 -i ''%s'' -o ''%s''', imgFile, featFile);
      cwd=commonFns.extractDirPath(mfilename('fullpath'));
      binPath = [cwd obj.binPath];
      cmd = [binPath ' ' args];

      [status,msg] = system(cmd);
      if status
        error('%d: %s: %s', status, cmd, message) ;
      end

      frames = obj.parseMserOutput(featFile);
      delete(imgFile); delete(featFile);
    end

  end

  methods (Static)
    function frames = parseMserOutput(featFile)
      fid = fopen(featFile,'r');
      if fid==-1
        error('Could not read file: %s\n',featFile);
      end
      [header,count] = fscanf(fid,'%f',2);
      if count~= 2,
        error('Invalid vgg mser output in: %s\n',featFile);
      end
      numPoints = header(2);
      %frames = zeros(5,numPoints);
      [frames,count] = fscanf(fid,'%f',[5 numPoints]);
      if count~=5*numPoints,
        error('Invalid mser output in %s\n',featFile);
      end

      % Transform the frame properly
      frames(1:2,:) = frames(1:2,:) + 1;
      C = frames(3:5,:);
      den = C(1,:) .* C(3,:) - C(2,:) .* C(2,:) ;
      S = [C(3,:) ; -C(2,:) ; C(1,:)] ./ den([1 1 1], :) ;
      frames(3:5,:) = S;

      fclose(fid);

    end

  end % ---- end of static methods ----

end % ----- end of class definition ----
