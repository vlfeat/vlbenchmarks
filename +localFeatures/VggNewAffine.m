classdef VggNewAffine < localFeatures.GenericLocalFeatureExtractor
% VggNewAffine class to wrap around the VGG new affine co-variant detectors.
%   VggNewAffine('Option','OptionValue',...) Creates object which wraps 
%   around Philbin's modified VGG Affine detector.
%
%   Only supported architectures are GLNX86 and GLNXA64 as for these the
%   binaries are avaialable.
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

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    DetBinPath;
    DescrBinPath;
    Opts = struct(...
      'detector', hessian',...
      'threshold', -1,...
      'noAngle', false,...
      'magnification', 3,...
      'descType', 'sift'...
      );
  end

  properties (Constant)
    rootInstallDir = fullfile('data','software','vggNewAffine','');
    detBinName = 'detect_points_2.ln';
    descBinName = 'compute_descriptors_2.ln';
  end

  methods
    % The constructor is used to set the options for vggNewAffine
    function obj = VggNewAffine(varargin)
      import localFeatures.*;
      import helpers.*;
      % Check platform dependence
      machineType = computer();
      switch(machineType)
        case {'GLNXA64','GLNX86'}
          obj.DetBinPath = fullfile(obj.rootInstallDir,...
            obj.detBinName);
          obj.DescrBinPath = fullfile(obj.rootInstallDir,...
            obj.descBinName);
        otherwise
          error('Arch: %s not supported by VggNewAffine',machineType);
      end
      varargin = obj.checkInstall(varargin);
      varargin = obj.configureLogger(obj.Name,varargin);
      obj.Opts = vl_argparse(obj.Opts,varargin);
      switch(lower(obj.Opts.detector))
        case 'hessian'
          obj.Opts.detectorType = 'hesaff';
        case 'harris'
          obj.Opts.detectorType = 'haraff';
        otherwise
          error('Invalid detector type: %s\n',obj.Opts.detector);
      end
      obj.Name = ['newVGG' obj.Opts.detector '-affine'];
      obj.ExtractsDescriptors = true;
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      import localFeatures.*;

      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      if numel(frames) > 0; return; end;
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(imagePath));
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(imagePath));
      end
      tmpName = tempname;
      framesFile = [tmpName '.' obj.Opts.detectorType];
      detArgs = '';
      if obj.Opts.threshold >= 0
        detArgs = sprintf('-thres %f ',obj.Opts.threshold);
      end
      detArgs = sprintf('%s-%s -i "%s" -o "%s" %s',...
                     detArgs, obj.Opts.detectorType,...
                     imagePath,framesFile);
      detCmd = [obj.DetBinPath ' ' detArgs];
      obj.debug('Executing: %s',detCmd);
      startTime = tic;
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
      obj.debug('Image %s processed in %gs',...
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
        obj.Opts.descType, imagePath, framesFile, outDescFile);
      if obj.Opts.magnification > 0
        descrArgs = [descrArgs,' -scale-mult ', ...
          num2str(obj.Opts.magnification)];
      end
      if obj.Opts.noAngle
        descrArgs = strcat(descrArgs,' -noangle');
      end             
      descrCmd = [obj.DescrBinPath ' ' descrArgs];

      obj.info('Computing descriptors.');
      obj.debug('Executing: %s',descrCmd);
      startTime = tic;
      [status,msg] = system(descrCmd);
      if status
        error('%d: %s: %s', status, descrCmd, msg) ;
      end
      [frames descriptors] = vl_ubcread(outDescFile,'format','oxford');
      timeElapsed = toc(startTime);
      obj.debug('Descriptors computed in %gs',timeElapsed);
      delete(outDescFile);

      % Remove the magnification from frames scale
      factor = obj.Opts.magnification^2;
      frames(3:5,:) = frames(3:5,:) ./ factor;
    end

    function sign = getSignature(obj)
      signList = {helpers.fileSignature(obj.DetBinPath) ... 
        helpers.fileSignature(obj.DescrBinPath) ...
        helpers.struct2str(obj.Opts)};
      sign = helpers.cell2str(signList);
    end
  end

  methods (Access=protected)
    function response = isInstalled(obj)
      import localFeatures.*;
      installDir = VggNewAffine.rootInstallDir;
      if(exist(installDir,'dir')),  response = true;
      else response = false; end
    end
  end % ---- end of static methods ----
end % ----- end of class definition ----
