% CMPCENSURE

classdef cmpCensure < affineDetectors.genericDetector
  properties (SetAccess=public, GetAccess=public)
    opts
  end
  
  properties (SetAccess=private, GetAccess=public)
    binPath
  end

  methods
    function obj = cmpCensure(varargin)
      obj.detectorName = 'Censure';
      obj.calcDescs = false;
      cwd=commonFns.extractDirPath(mfilename('fullpath'));
      path = fullfile(cwd,'thirdParty/censure/');
      %addpath(path);
      obj.binPath = fullfile(path,'censure');
      
      obj.opts.respThr = 15;
      obj.opts.filterRatio = sqrt(sqrt(2));
      obj.opts.octRatio = sqrt(2);
      obj.opts.detectorType = 1; % Dense
      obj.opts.verbose = 0;
      obj.opts.gridRatio = 1;
      obj.opts.lineSuppThr = 10;
      obj.opts.numPlanes = -1;
      obj.opts.initRadius = 2.5;
      obj.opts.KPdef = 0; % Export simpts
      
      obj.opts = vl_argparse(obj.opts,varargin);
      
      if obj.opts.detectorType == 0
        obj.detectorName = [obj.detectorName ' Sparse'];
      else
        obj.detectorName = [obj.detectorName ' Dense'];
      end
    end

    function frames = detectPoints(obj,img)
      if(size(img,3)>1), img = rgb2gray(img); end
      img = im2uint8(img);

      [frames] = censure(img,obj.opts);
      
      if obj.opts.KPdef == 0
        frames = [[frames.x]; [frames.y]; [frames.s]];
      elseif obj.opts.KPdef == 1
        frames = [[frames.x]; [frames.y]; [frames.s]; [frames.angle]];
      elseif obj.opts.KPdef == 2
        frames = [[frames.x]; [frames.y]; [frames.a11]; [frames.a12]; ...
          [frames.a21]; [frames.a22]];
      end
    end
    
    function sign = signature(obj)
      sign = [commonFns.file_signature(obj.binPath) ';'...
              evalc('disp(obj.opts)')];
    end

  end

end
