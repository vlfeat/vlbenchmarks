classdef VggAffine < localFeatures.GenericLocalFeatureExtractor ...
    & helpers.GenericInstaller
% VGGAFFINE class to wrap around the VGG affine co-variant detectors.
%   VGGAFFINE('Option','OptionValue',...) Constructs the object of the
%   wrapper. 
%
%   This version of VGG descriptor calculation internaly compute with 
%   magnification factor equal 3 and cannot be adjusted in the binary
%   parameters. Therefore these parameters are 'simulated' in this wrapper.
%
%   Only supported architectures are GLNX86 and GLNXA64 as for these the
%   binaries are avaialable.
%
%   The constructor call above takes the following options:
%
%   Detector:: 'hesaff'
%     One of {'hesaff', 'haraff', 'heslap', 'harlap','har'} which are
%     supported by the binary:
%     ./data/software/vggAffine/extract_features.ln
%
%   Descriptor:: 'sift'
%     One of {'sift','jla','gloh','mom','koen','kf','sc','spin','pca','cc'}.
%     See help string of the binary in
%     ./data/software/vggAffine/compute_descriptors.ln
%
%   Threshold:: -1
%     Cornerness threshold.
%
%   NoAngle:: false
%     Compute rotation variant descriptors if true (no rotation esimation)
%
%   Magnification:: 3
%     Magnification of the measurement region for the descriptor
%     calculation.
%
%   CropFrames :: true
%   Crop frames which after magnification overlap the image borders.

  properties (SetAccess=private, GetAccess=public)
    opts = struct(...
      'detector', 'hesaff',...
      'threshold', -1,...
      'noAngle', false,...
      'descriptor', 'sift',...
      'magnification', 3,...
      'cropFrames', true...
      );
  end
  
  properties (Constant)
    binDir = fullfile('data','software','vggAffine','');
    detBinPath = fullfile(localFeatures.VggAffine.binDir,'h_affine.ln');
    descrBinPath = fullfile(localFeatures.VggAffine.binDir,'compute_descriptors.ln');
    detUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/h_affine.ln.gz';
    descUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/compute_descriptors.ln.gz'
    validDetectors = {'hesaff', 'haraff', 'heslap', 'harlap','har'};
    validDescriptors = {'sift','jla','gloh','mom','koen','kf','sc',...
      'spin','pca','cc'};
    builtInMagnification = 3;
    supportedImageFormats = {'.png','.ppm','.pgm'};
  end

  methods
    % The constructor is used to set the options for VggAffine
    function obj = VggAffine(varargin)
      import localFeatures.*;
      import helpers.*;

      if ~obj.isInstalled(),
        obj.warn('Not found installed');
        obj.install();
      end
      [obj.opts varargin] = vl_argparse(obj.opts,varargin);
      if ~ismember(obj.opts.detector, obj.validDetectors)
        obj.error('Invalid detector');
      end
      if ~ismember(obj.opts.descriptor, obj.validDescriptors)
        obj.error('Invalid descriptor');
      end
      obj.name = ['VGG ' obj.opts.detector ' ' obj.opts.descriptor];
      obj.detectorName = ['VGG ' obj.opts.detector];
      obj.descriptorName = ['VGG ' obj.opts.descriptor];
      obj.extractsDescriptors = true;
      % Check platform dependence
      machineType = computer();
      if ~ismember(machineType,{'GLNX86','GLNXA64'})
          obj.error('Arch: %s not supported by VGG Affine.',machineType);
      end
      obj.configureLogger(obj.name,varargin);
    end

    function [frames descriptors] = extractFeatures(obj, origImagePath)
      import helpers.*;
      import localFeatures.*;

      [frames descriptors] = obj.loadFeatures(origImagePath,nargout > 1);
      if numel(frames) > 0; return; end;
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(origImagePath));
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(origImagePath));
      end
      % Check whether image is of supported format
      [imagePath imIsTmp] = helpers.ensureImageFormat(origImagePath, ...
        obj.supportedImageFormats);
      if imIsTmp, obj.debug('Input image converted to %s',imagePath); end

      tmpName = tempname;
      framesFile = [tmpName '.' obj.opts.detector];
      detArgs = '';
      if obj.opts.threshold >= 0
        detArgs = sprintf('-thres %f ',obj.opts.threshold);
      end
      detArgs = sprintf('%s-%s -i "%s" -o "%s" %s',...
                     detArgs, obj.opts.detector,...
                     imagePath,framesFile);

      detCmd = [obj.detBinPath ' ' detArgs];
      startTime = tic;
      [status,msg] = system(detCmd);
      timeElapsed = toc(startTime);
      if status
        error('%d: %s: %s', status, detCmd, msg) ;
      end
      frames = helpers.readFramesFile(framesFile);
      if nargout ==2
        if obj.opts.magnification == obj.builtInMagnification ...
            && ~obj.opts.cropFrames
          % When frames does not have to be magnified or cropped, process
          % directly the file from the frames detector.
          [frames descriptors] = obj.computeDescriptors(imagePath,framesFile);
        else
          [frames descriptors] = obj.extractDescriptors(imagePath,frames);
        end
      end
      delete(framesFile);
      if imIsTmp, delete(imagePath); end;
      obj.debug('Image %s processed in %gs',...
        getFileName(origImagePath),timeElapsed);
      obj.storeFeatures(origImagePath, frames, descriptors);
    end

    function [frames descriptors] = extractDescriptors(obj, imagePath, frames)
      % EXTRACTDESCRIPTORS Compute SIFT descriptors using 
      %   compute_descriptors.ln binary.
      %
      %  frames can be both array of frames or path to a frames file.
      import localFeatures.*;
      magFactor = 1;
      tmpName = tempname;
      if size(frames,1) ~= 5
        frames = helpers.frameToEllipse(frames);
      end

      if obj.opts.cropFrames
        imgSize = size(imread(imagePath));
        imgbox = [1 1 imgSize(2)+1 imgSize(1)+1];
        mf = obj.opts.magnification ^ 2;
        magFrames = [frames(1:2,:) ; frames(3:5,:) .* mf];
        isVisible = benchmarks.helpers.isEllipseInBBox(imgbox,magFrames);
        frames = frames(:,isVisible);
      end

      if obj.opts.magnification ~= obj.builtInMagnification
        % Magnify the frames accordnig to set magnif. factor
        magFactor = obj.opts.magnification / obj.builtInMagnification;
        magFactor = magFactor ^ 2;
        frames(3:5,:) = frames(3:5,:) .* magFactor;
      end

      framesFile = [tmpName '.frames'];
      helpers.writeFeatures(framesFile,frames,[],'Format','oxford');
      [frames descriptors] = obj.computeDescriptors(imagePath,framesFile);
      if obj.opts.magnification ~= obj.builtInMagnification
        % Resize the frames back to their size
        frames(3:5,:) = frames(3:5,:) ./ magFactor;
      end
    end

    function [frames descriptors] = computeDescriptors(obj, origImagePath, ...
        framesFile)
      % COMPUTEDESCRIPTORS Compute descriptors from frames stored in a file
      import localFeatures.*;
      tmpName = tempname;
      outDescFile = [tmpName '.descs'];

      [imagePath imIsTmp] = helpers.ensureImageFormat(origImagePath, ...
        obj.supportedImageFormats);
      if imIsTmp, obj.debug('Input image converted to %s',imagePath); end
      % Prepare the options
      descrArgs = sprintf('-%s -i "%s" -p1 "%s" -o1 "%s"', ...
        obj.opts.descriptor, imagePath, framesFile, outDescFile);

      if obj.opts.noAngle
        descrArgs = strcat(descrArgs,' -noangle');
      end             
      descrCmd = [obj.descrBinPath ' ' descrArgs];
      obj.info('Computing descriptors.');
      startTime = tic;
      [status,msg] = system(descrCmd);
      elapsedTime = toc(startTime);
      if status
        error('%d: %s: %s', status, descrCmd, msg) ;
      end
      [frames descriptors] = vl_ubcread(outDescFile,'format','oxford');
      obj.debug('Descriptors computed in %gs',elapsedTime);
      delete(outDescFile);
      if imIsTmp, delete(imagePath); end;
    end

    function sign = getSignature(obj)
      signList = {helpers.fileSignature(obj.detBinPath) ... 
        helpers.fileSignature(obj.descrBinPath) ...
        helpers.struct2str(obj.opts)};
      sign = helpers.cell2str(signList);
    end
  end

  methods (Static)
    function [urls dstPaths] = getTarballsList()
      import localFeatures.*;
      urls = {VggAffine.detUrl VggAffine.descUrl};
      dstPaths = {VggAffine.binDir VggAffine.binDir};
    end

    function compile()
      import localFeatures.*;
      % When unpacked, binaries are not executable
      chmodCmds = {sprintf('chmod +x %s',VggAffine.detBinPath) ...
        sprintf('chmod +x %s',VggAffine.descrBinPath)}; 
      for cmd = chmodCmds
        [status msg] = system(cmd{:});
        if status ~= 0, error(msg); end
      end
    end
  end % ---- end of static methods ----
end % ----- end of class definition ----
