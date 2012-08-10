% STARDETECTOR

classdef starDetector < affineDetectors.genericDetector
  properties (SetAccess=public, GetAccess=public)
    opts
  end
  
  properties (SetAccess=private, GetAccess=public)
    binPath
  end

  methods
    function obj = starDetector(varargin)
      obj.detectorName = 'Star Detector';
      obj.calcDescs = false;
      cwd=commonFns.extractDirPath(mfilename('fullpath'));
      path = fullfile(cwd,'thirdParty/censure/');
      obj.binPath = fullfile(path,'star_detector');
      
      obj.opts.n = 7;
      obj.opts.response_threshold = 30;
      obj.opts.line_threshold_projected = 10;
      obj.opts.line_threshold_binarized = 8;
      obj.opts.verbose = 0;
      
      obj.opts = vl_argparse(obj.opts,varargin);
    end

    function frames = detectPoints(obj,img)
      if(size(img,3)>1), img = rgb2gray(img); end
      img = im2uint8(img);

      [frames] = star_detector(img,obj.opts);
      
      frames = [[frames.x]; [frames.y]; [frames.s]];
    end
    
    function sign = signature(obj)
      sign = [commonFns.file_signature(obj.binPath) ';'...
              evalc('disp(obj.opts)')];
    end

  end

end
