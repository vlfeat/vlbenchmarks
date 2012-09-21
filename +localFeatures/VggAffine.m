classdef VggAffine < localFeatures.GenericLocalFeatureExtractor ...
    & helpers.GenericInstaller
% localFeatures.VggAffine VGG affine co-variant detectors wrapper
%   localFeatures.VggAffine('Option','OptionValue',...) Constructs the object
%   of the wrapper.
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
    Opts = struct(...
      'detector', 'hesaff',...
      'threshold', -1,...
      'noAngle', false,...
      'descriptor', 'sift',...
      'magnification', 3,...
      'cropFrames', true...
      );
  end
  properties (Constant)
    ValidDetectors = {'hesaff', 'haraff', 'heslap', 'harlap','har'};
    ValidDescriptors = {'sift','jla','gloh','mom','koen','kf','sc',...
      'spin','pca','cc'};
  end

  properties (Constant, Hidden)
    BinDir = fullfile('data','software','vggAffine','');
    DetBinPath = fullfile(localFeatures.VggAffine.BinDir,'h_affine.ln');
    DescrBinPath = fullfile(localFeatures.VggAffine.BinDir,'compute_descriptors.ln');
    DetUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/h_affine.ln.gz';
    DescUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/compute_descriptors.ln.gz'
    BuiltInMagnification = 3;
    SupportedImageFormats = {'.png','.ppm','.pgm'};
  end

  methods
    % The constructor is used to set the options for VggAffine
    function obj = VggAffine(varargin)
      import localFeatures.*;
      import helpers.*;
      % Check platform dependence
      machineType = computer();
      if ~ismember(machineType,{'GLNX86','GLNXA64'})
        error('Arch: %s not supported by VGG Affine.',machineType);
      end
      varargin = obj.checkInstall(varargin);
      [obj.Opts varargin] = vl_argparse(obj.Opts,varargin);
      if ~ismember(obj.Opts.detector, obj.ValidDetectors)
        obj.error('Invalid detector');
      end
      if ~ismember(obj.Opts.descriptor, obj.ValidDescriptors)
        obj.error('Invalid descriptor');
      end
      obj.Name = ['VGG ' obj.Opts.detector ' ' obj.Opts.descriptor];
      obj.DetectorName = ['VGG ' obj.Opts.detector];
      obj.DescriptorName = ['VGG ' obj.Opts.descriptor];
      obj.ExtractsDescriptors = true;
      obj.configureLogger(obj.Name,varargin);
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
        obj.SupportedImageFormats);
      if imIsTmp, obj.debug('Input image converted to %s',imagePath); end

      tmpName = tempname;
      framesFile = [tmpName '.' obj.Opts.detector];
      detArgs = '';
      if obj.Opts.threshold >= 0
        detArgs = sprintf('-thres %f ',obj.Opts.threshold);
      end
      detArgs = sprintf('%s-%s -i "%s" -o "%s" %s',...
                     detArgs, obj.Opts.detector,...
                     imagePath,framesFile);

      detCmd = [obj.DetBinPath ' ' detArgs];
      obj.debug('Executing: %s',detCmd);
      startTime = tic;
      [status,msg] = system(detCmd);
      timeElapsed = toc(startTime);
      if status
        error('%d: %s: %s', status, detCmd, msg) ;
      end
      frames = helpers.readFramesFile(framesFile);
      if nargout ==2
        if obj.Opts.magnification == obj.BuiltInMagnification ...
            && ~obj.Opts.cropFrames
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
      % extractDescriptors Compute SIFT descriptors
      %   [DFRAMES FRAMES] = obj.extractDescriptors(IMG_PATH, FRAMES) extracts
      %   DESCRIPTORS of FRAMES from image IMG_PATH using the
      %   compute_descriptors.ln.
      %
      %   [DFRAMES FRAMES] = obj.extractDescriptors(IMG_PATH, FRAMES_PATH)
      %   extracts DESCRIPTORS of frames stored in file FRAMES_PATH from image
      %   IMG_PATH .
      import localFeatures.*;
      magFactor = 1;
      tmpName = tempname;
      if size(frames,1) ~= 5
        frames = helpers.frameToEllipse(frames);
      end

      if obj.Opts.cropFrames
        imgSize = size(imread(imagePath));
        imgbox = [1 1 imgSize(2)+1 imgSize(1)+1];
        mf = obj.Opts.magnification ^ 2;
        magFrames = [frames(1:2,:) ; frames(3:5,:) .* mf];
        isVisible = benchmarks.helpers.isEllipseInBBox(imgbox,magFrames);
        frames = frames(:,isVisible);
      end

      if obj.Opts.magnification ~= obj.BuiltInMagnification
        % Magnify the frames accordnig to set magnif. factor
        magFactor = obj.Opts.magnification / obj.BuiltInMagnification;
        magFactor = magFactor ^ 2;
        frames(3:5,:) = frames(3:5,:) .* magFactor;
      end

      framesFile = [tmpName '.frames'];
      helpers.writeFeatures(framesFile,frames,[],'Format','oxford');
      [frames descriptors] = obj.computeDescriptors(imagePath,framesFile);
      if obj.Opts.magnification ~= obj.BuiltInMagnification
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
        obj.SupportedImageFormats);
      if imIsTmp, obj.debug('Input image converted to %s',imagePath); end
      % Prepare the options
      descrArgs = sprintf('-%s -i "%s" -p1 "%s" -o1 "%s"', ...
        obj.Opts.descriptor, imagePath, framesFile, outDescFile);

      if obj.Opts.noAngle
        descrArgs = strcat(descrArgs,' -noangle');
      end             
      descrCmd = [obj.DescrBinPath ' ' descrArgs];
      obj.info('Computing descriptors.');
      obj.debug('Executing: %s',descrCmd);
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
      signList = {helpers.fileSignature(obj.DetBinPath) ... 
        helpers.fileSignature(obj.DescrBinPath) ...
        helpers.struct2str(obj.Opts)};
      sign = helpers.cell2str(signList);
    end
  end

  methods  (Access=protected)
    function [urls dstPaths] = getTarballsList(obj)
      import localFeatures.*;
      urls = {VggAffine.DetUrl VggAffine.DescUrl};
      dstPaths = {VggAffine.BinDir VggAffine.BinDir};
    end

    function compile(obj)
      import localFeatures.*;
      % When unpacked, binaries are not executable
      helpers.setFileExecutable(VggAffine.DetBinPath);
      helpers.setFileExecutable(VggAffine.DescrBinPath);
    end
  end
end
