classdef MROGH < localFeatures.GenericLocalFeatureExtractor ...
    & helpers.GenericInstaller

% Authors: Karel Lenc, Varun Gulshan

% AUTORIGHTS
  properties (SetAccess=private, GetAccess=public)
    Opts = struct(...
      'ndir',8,... % -Dir
      'order',6,... % -Order
      'multiRegionNum',4,... % -R
      'magnification', 1,...
      'cropFrames', true...
      );
  end

  properties (Constant, Hidden)
    BinDir = fullfile('data','software','mrogh','');
    SrcDir = fullfile('data','software','mrogh','src_mrogh','');
    DescrBinPath = fullfile(localFeatures.MROGH.BinDir,'mrogh');
    DescUrl = 'http://sourceforge.net/projects/openpr/files/code\ for\ an\ individual\ algorithm/src_mrogh.zip'
    BuiltInMagnification = 1;
    % This old binary tends to segfault sometimes, number of repetetive
    % executions.
    BinExecNumTrials = 5;
    Cxx = mex.getCompilerConfigurations('C++','Selected').Details.CompilerExecutable;
    MakeCmds = {...
      sprintf('%s -O3 -c -o mrogh.o -I%s mrogh.cpp',localFeatures.MROGH.Cxx,fullfile(helpers.OpenCVInstaller.IncludeDir,'opencv')),...
      sprintf('%s -O3 -c -o main.o -I%s main.cpp',localFeatures.MROGH.Cxx,fullfile(helpers.OpenCVInstaller.IncludeDir,'opencv')),...
      sprintf('%s %s main.o mrogh.o -o mrogh',localFeatures.MROGH.Cxx,helpers.OpenCVInstaller.getCompileFlags())};
  end

  methods
    % The constructor is used to set the options for MROGH
    function obj = MROGH(varargin)
      import localFeatures.*;
      import helpers.*;
      % Check platform dependence
      machineType = computer();
      if ~ismember(machineType,{'GLNX86','GLNXA64'})
        error('Binary not available for arch. %s .',machineType);
      end
      varargin = obj.checkInstall(varargin);
      [obj.Opts varargin] = vl_argparse(obj.Opts,varargin);
      obj.Name = 'MROGH desc.';
      obj.ExtractsDescriptors = true;
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
        isVisible = helpers.isEllipseInBBox(imgbox,magFrames);
        frames = frames(:,isVisible);
      end
      if isempty(frames), descriptors = []; return; end;

      if obj.Opts.magnification ~= obj.BuiltInMagnification
        % Magnify the frames accordnig to set magnif. factor
        magFactor = obj.Opts.magnification / obj.BuiltInMagnification;
        magFactor = magFactor ^ 2;
        frames(3:5,:) = frames(3:5,:) .* magFactor;
      end

      framesFile = [tmpName '.frames'];
      helpers.writeFeatures(framesFile,frames,[],'Format','oxford');
      [frames descriptors] = obj.computeDescriptors(imagePath,framesFile);
      delete(framesFile);

      if obj.Opts.magnification ~= obj.BuiltInMagnification
        % Resize the frames back to their size
        frames(3:5,:) = frames(3:5,:) ./ magFactor;
      end
    end

    function [frames descriptors] = computeDescriptors(obj, origImagePath, ...
        framesFile)
      % COMPUTEDESCRIPTORS Compute descriptors from frames stored in a file
      import localFeatures.*;
      import localFeatures.helpers.*;
      tmpName = tempname;
      outDescFile = [tmpName '.descs'];

      [imagePath imIsTmp] = obj.ensureImageFormat(origImagePath);
      if imIsTmp, obj.debug('Input image converted to %s',imagePath); end
      % Prepare the options
      descrArgs = sprintf(' -i "%s" -f "%s" -o "%s" -Dir %d -Order %d -R %d', ...
        imagePath, framesFile, outDescFile,obj.Opts.ndir,obj.Opts.order,...
        obj.Opts.multiRegionNum);

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
      [frames descriptors] = readFeaturesFile(outDescFile,'floatDesc',true);
      obj.debug('%d Descriptors computed in %gs',size(frames,2),elapsedTime);
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
      urls = {MROGH.DescUrl};
      dstPaths = {MROGH.BinDir};
    end

    function compile(obj)
      import localFeatures.*;
      import helpers.*;
      curDir = pwd;
      cd(MROGH.SrcDir);
      try
        for ci = 1:numel(obj.MakeCmds)
          display(obj.MakeCmds{ci})
          system(obj.MakeCmds{ci}, '-echo');
        end
        cd(curDir);
      catch err
        cd(curDir);
        throw(err);
      end
      
      copyfile(fullfile(MROGH.SrcDir,'mrogh'),MROGH.DescrBinPath);
    end
    
    function res = isCompiled(obj)
      res = exist(localFeatures.MROGH.DescrBinPath,'file');
    end

    function deps = getDependencies(obj)
      deps = {helpers.OpenCVInstaller()};
    end
  end
end
