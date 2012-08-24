% VGGNEWAFFINE class to wrap around the VGG new affine co-variant detectors.
%
%   obj = affineDetectors.vggNewAffine('Option','OptionValue',...);
%   frames = obj.detectPoints(img)
%
%   obj class implements the genericDetector interface and wraps around the
%   vgg implementation of harris and hessian affine detectors (Philbin
%   version).
%
%   The constructor call above takes the following options:
%
%   Detector:: ['hessian']
%     One of 'hessian' or 'harris' to select what type of corner detector 
%     to use
%
%   threshold:: [-1]
%     Cornerness threshold.
%
%   noAngle:: [false]
%     Compute rotation variant descriptors if true (no rotation esimation)
%
%   Magnification:: [3]
%     Magnification of the measurement region for the descriptor
%     calculation.
%

classdef vggNewAffine < localFeatures.genericLocalFeatureExtractor
  properties (SetAccess=private, GetAccess=public)
    opts
    detBinPath
    descrBinPath
  end
  
  properties (Constant)
    rootInstallDir = fullfile('data','software','vggNewAffine','');
    detBinName = 'detect_points_2.ln';
    descBinName = 'compute_descriptors_2.ln';
  end

  methods
    % The constructor is used to set the options for vggNewAffine
    function obj = vggNewAffine(varargin)
      import localFeatures.*;
      import helpers.*;

      if ~vggNewAffine.isInstalled(),
        obj.isOk = false;
        obj.errMsg = 'vggNewAffine not found installed';
        return;
      end

      % Default options
      obj.opts.detector= 'hessian';
      obj.opts.threshold = -1;
      obj.opts.noAngle = false;
      obj.opts.magnification = 3;
      obj.opts.descType = 'sift';
      [obj.opts varargin] = vl_argparse(obj.opts,varargin);

      switch(lower(obj.opts.detector))
        case 'hessian'
          obj.opts.detectorType = 'hesaff';
        case 'harris'
          obj.opts.detectorType = 'haraff';
        otherwise
          error('Invalid detector type: %s\n',obj.opts.detector);
      end
      obj.detectorName = [obj.opts.detector '-affine(new vgg)'];
  
      % Check platform dependence
      machineType = computer();
      obj.detBinPath = '';
      switch(machineType)
        case {'GLNXA64','GLNX86'}
          obj.detBinPath = fullfile(obj.rootInstallDir,...
            obj.detBinName);
          obj.descrBinPath = fullfile(obj.rootInstallDir,...
            obj.descBinName);
        otherwise
          obj.isOk = false;
          obj.errMsg = sprintf('Arch: %s not supported by vggNewAffine',...
                                machineType);
      end
      obj.configureLogger(obj.detectorName,varargin);
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      import localFeatures.*;
      if ~obj.isOk, frames = zeros(5,0); return; end

      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      if numel(frames) > 0; return; end;

      startTime = tic;
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(imagePath));
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(imagePath));
      end
      
      tmpName = tempname;
      framesFile = [tmpName '.' obj.opts.detectorType];
      
      detArgs = '';
      if obj.opts.threshold >= 0
        detArgs = sprintf('-thres %f ',obj.opts.threshold);
      end
      detArgs = sprintf('%s-%s -i "%s" -o "%s" %s',...
                     detArgs, obj.opts.detectorType,...
                     imagePath,framesFile);

      detCmd = [obj.detBinPath ' ' detArgs];

      [status,msg] = system(detCmd);
      if status
        error('%d: %s: %s', status, detCmd, msg) ;
      end
      
      if nargout ==2
        [frames descriptors] = obj.extractDescriptors(imagePath,framesFile);
      else
        frames = helpers.readFramesFile(framesFile);
      end
      
      delete(framesFile);
      
      timeElapsed = toc(startTime);
      obj.debug('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed);
      
      obj.storeFeatures(imagePath, frames, descriptors);
    end
  
    function [frames descriptors] = extractDescriptors(obj, imagePath, frames)
      % EXTRACTDESCRIPTORS Compute SIFT descriptors using 
      %   compute_descriptors_2.ln binary.
      %
      %  frames can be both array of frames or path to a frames file.
      import localFeatures.*;

      tmpName = tempname;
      outDescFile = [tmpName '.descs'];

      if size(frames,1) == 1 && exist(frames,'file')
        framesFile = frames;
      elseif exist('frames','var')
        framesFile = [tmpName '.frames'];
        helpers.writeFeatures(framesFile,frames,[],'Format','oxford');
      end

      % Prepare the options
      descrArgs = sprintf('-%s -i "%s" -p1 "%s" -o1 "%s"', ...
        obj.opts.descType, imagePath, framesFile, outDescFile);

      if obj.opts.magnification > 0
        descrArgs = [descrArgs,' -scale-mult ', ...
          num2str(obj.opts.magnification)];
      end

      if obj.opts.noAngle
        descrArgs = strcat(descrArgs,' -noangle');
      end             

      descrCmd = [obj.descrBinPath ' ' descrArgs];

      startTime = tic;
      obj.info('Computing descriptors of %d frames.',size(frames,2));
      [status,msg] = system(descrCmd);
      if status
        error('%d: %s: %s', status, descrCmd, msg) ;
      end
      [frames descriptors] = vl_ubcread(outDescFile,'format','oxford');
      timeElapsed = toc(startTime);
      obj.debug('Descriptors computed in %gs',timeElapsed);
      delete(outDescFile);

      % Remove the magnification from frames scale
      factor = obj.opts.magnification^2;
      frames(3:5,:) = frames(3:5,:) ./ factor;
    end
    
    function sign = getSignature(obj)
      signList = {helpers.fileSignature(obj.detBinPath) ... 
        helpers.fileSignature(obj.descrBinPath) ...
        helpers.struct2str(obj.opts)};
      sign = helpers.cell2str(signList);
    end
  end

  methods (Static)

    function response = isInstalled()
      import localFeatures.*;
      installDir = vggNewAffine.rootInstallDir;
      if(exist(installDir,'dir')),  response = true;
      else response = false; end
    end

  end % ---- end of static methods ----

end % ----- end of class definition ----
