classdef VggDescriptor < localFeatures.GenericLocalFeatureExtractor ...
    & helpers.GenericInstaller
% localFeatures.VggDescriptor VGG compute_descriptors.ln binary wrapper
%   localFeatures.VggDescriptor('Option','OptionValue',...) Constructs 
%   the object of the wrapper.
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
%   Descriptor:: 'sift'
%     One of {'sift','jla','gloh','mom','koen','kf','sc','spin','pca','cc'}.
%     See help string of the binary in
%     ./data/software/VggDescriptor/compute_descriptors.ln
%
%   NoAngle:: false
%     Compute rotation variant descriptors if true (no rotation esimation)
%
%   Magnification:: 3
%     Magnification of the measurement region for the descriptor
%     calculation.
%
%   CropFrames :: true
%     Crop frames which after magnification overlap the image borders.

% Authors: Karel Lenc, Varun Gulshan

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    Opts = struct(...
      'noAngle', false,...
      'descriptor', 'sift',...
      'magnification', 3,...
      'cropFrames', true...
      );
  end
  properties (Constant)
    ValidDescriptors = {'sift','jla','gloh','mom','koen','kf','sc',...
      'spin','pca','cc'};
  end

  properties (Constant, Hidden)
    BinDir = fullfile('data','software','VggDescriptor','');
    DescrBinPath = fullfile(localFeatures.VggDescriptor.BinDir,'compute_descriptors.ln');
    DescUrl = 'http://www.robots.ox.ac.uk/~vgg/research/affine/det_eval_files/compute_descriptors.ln.gz'
    BuiltInMagnification = 3;
    % This old binary tends to segfault sometimes, number of repetetive
    % executions.
    BinExecNumTrials = 5; 
  end

  methods
    % The constructor is used to set the options for VggDescriptor
    function obj = VggDescriptor(varargin)
      import localFeatures.*;
      import helpers.*;
      % Check platform dependence
      machineType = computer();
      if ~ismember(machineType,{'GLNX86','GLNXA64'})
        error('Binary not available for arch. %s .',machineType);
      end
      varargin = obj.checkInstall(varargin);
      [obj.Opts varargin] = vl_argparse(obj.Opts,varargin);
      if ~ismember(obj.Opts.descriptor, obj.ValidDescriptors)
        obj.error('Invalid descriptor');
      end
      obj.Name = 'VGG desc.';
      obj.ExtractsDescriptors = true;
      obj.SupportedImgFormats = {'.png','.ppm','.pgm'};
      obj.configureLogger(obj.Name,varargin);
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
      if isempty(frames), descriptors = []; return; end;
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
      if isempty(frames), descriptors = []; return; end;

      if obj.Opts.magnification ~= obj.BuiltInMagnification
        % Magnify the frames accordnig to set magnif. factor
        magFactor = obj.Opts.magnification / obj.BuiltInMagnification;
        magFactor = magFactor ^ 2;
        frames(3:5,:) = frames(3:5,:) .* magFactor;
      end
      
      % Prevent segmentation fault when only 1 frame present
      oneFrameHack = false;
      if size(frames,2) == 1
        % Insert a dummy frame
        frames = [frames [1;1;1;0;1]];
        oneFrameHack = true;
      end

      framesFile = [tmpName '.frames'];
      helpers.writeFeatures(framesFile,frames,[],'Format','oxford');
      [frames descriptors] = obj.computeDescriptors(imagePath,framesFile);
      delete(framesFile);

      if oneFrameHack
        frames = frames(:,1:end-1);
      end

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

      [imagePath imIsTmp] = obj.ensureImageFormat(origImagePath);
      if imIsTmp, obj.debug('Input image converted to %s',imagePath); end
      % Prepare the options
      descrArgs = sprintf('-%s -i "%s" -p1 "%s" -o1 "%s"', ...
        obj.Opts.descriptor, imagePath, framesFile, outDescFile);

      if obj.Opts.noAngle
        descrArgs = strcat(descrArgs,' -noangle');
      end
      descrCmd = [obj.DescrBinPath ' ' descrArgs];
      obj.info('Computing descriptors.');
      startTime = tic;
      status = 1; numTrials = obj.BinExecNumTrials;
      while status ~= 0 && numTrials > 0
        obj.debug('Executing: %s',descrCmd);
        [status,msg] = system(descrCmd);
        if status == 130, break; end; % Handle Cntl-C
        if status 
          obj.warn('Command %s failed. Trying to rerun.',descrCmd);
        end
        numTrials = numTrials - 1;
      end
      elapsedTime = toc(startTime);
      if status
        error('Computing descriptors failed.\nOffending command: %s\n%s',descrCmd, msg);
      end
      [frames descriptors] = vl_ubcread(outDescFile,'format','oxford');
      obj.debug('%d Descriptors computed in %gs',elapsedTime,size(frames,2));
      delete(outDescFile);
      if imIsTmp, delete(imagePath); end;
    end

    function sign = getSignature(obj)
      signList = {helpers.fileSignature(obj.DescrBinPath) ...
        helpers.struct2str(obj.Opts)};
      sign = helpers.cell2str(signList);
    end
  end

  methods  (Access=protected)
    function [urls dstPaths] = getTarballsList(obj)
      import localFeatures.*;
      urls = {VggDescriptor.DescUrl};
      dstPaths = {VggDescriptor.BinDir};
    end

    function compile(obj)
      import localFeatures.*;
      % When unpacked, binaries are not executable
      helpers.setFileExecutable(VggDescriptor.DescrBinPath);
    end

    function deps = getDependencies(obj)
      deps = {helpers.VlFeatInstaller('0.9.13')};
    end
  end
end
