classdef Kaze < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller
% Authors: Karel Lenc

% AUTORIGHTS
  properties (SetAccess=public, GetAccess=public)
    Opts = struct(...
      'soffset', 1.6,...        % the base scale offset (sigma units)
      'omax', 8,...             % the coarsest nonlinear scale space level (sigma units)
      'nsublevels', 4,...       % number of sublevels per octave
      'dthreshold', 0.001,...   % Feature detector threshold response for accepting points
      'derivatives', 0,...      % Derivatives Type 0 -> Finite Differences, 1 -> Scharr
      'descriptor', 1,...       % Descriptor Type 0 -> SURF, 1 -> M-SURF
      'upright', 1,...          % 0 -> Rotation Invariant, 1 -> No Rotation Invariant
      'save_scale_space', 0 ... % 1 in case we want to save the nonlinear scale space images. 0 otherwise
      );
  end

  properties (Constant, Hidden)
    RootInstallDir = fullfile('data','software','kaze','');
    SrcDir = fullfile(localFeatures.Kaze.RootInstallDir,'kaze_features_1_0');
    SoftwareUrl = 'http://www.robesafe.com/personal/pablo.alcantarilla/code/kaze_features_1_0.tar.gz';
    BinPath = fullfile(localFeatures.Kaze.SrcDir,'kaze_features');
    % Patch which disables showing the results in a window
    PatchFile = fullfile(fileparts(mfilename('fullpath')),'kaze.patch');
    PatchCmd = sprintf('patch -f -b -p0 -d %s -i %s',...
      localFeatures.Kaze.PatchCmd,localFeatures.Kaze.SrcDir,...
      localFeatures.Kaze.PatchFile);
  end

  methods
    function obj = Kaze(varargin)
      import helpers.*;
      obj.Name = 'KAZE';
      obj.ExtractsDescriptors = true;
      varargin = obj.checkInstall(varargin);
      varargin = obj.configureLogger(obj.Name,varargin);
      obj.Opts = vl_argparse(obj.Opts, varargin);
    end

    function [frames descriptors] = extractFeatures(obj, origImagePath)
      import helpers.*;
      import localFeatures.helpers.*;
      [frames descriptors] = obj.loadFeatures(origImagePath,true);
      if numel(frames) > 0; return; end;      
      obj.info('Computing features of image %s.',...
        getFileName(origImagePath));
      [imagePath imIsTmp] = obj.ensureImageFormat(origImagePath);
      tmpName = tempname;
      outFeaturesFile = [tmpName '.kaze'];
      args = obj.buildArgs(imagePath, outFeaturesFile);
      cmd = [obj.BinPath ' ' args];
      obj.debug('Executing: %s',cmd);
      startTime = tic;
      [status,msg] = helpers.osExec('.',cmd,'-echo');
      if status ~= 0
        error('%d: %s: %s', status, cmd, msg) ;
      end
      timeElapsed = toc(startTime);
      [frames descriptors] = ...
        readFeaturesFile(outFeaturesFile,'FloatDesc',true);
      delete(outFeaturesFile);
      if imIsTmp, delete(imagePath); end;
      obj.debug('%d features from image %s computed in %gs',...
        size(frames,2),getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, descriptors);
    end

    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.BinPath) ';'...
              helpers.struct2str(obj.Opts)];
    end
  end

  methods (Access=protected)
    function args = buildArgs(obj, imagePath, outFile)
      % -nl - do not write the hessian keypoint type
      args = sprintf(' "%s" --output "%s"',...
        imagePath, outFile);
      fields = fieldnames(obj.Opts);
      for i = 1:numel(fields)
        val = obj.Opts.(fields{i});
        if ~isempty(val)
          args = [args,' --',fields{i},' ', num2str(val)];
        end
      end
    end

    function deps = getDependencies(obj)
      deps = {helpers.Installer()};
    end

    function [urls dstPaths] = getTarballsList(obj)
      import localFeatures.*;
      urls = {obj.SoftwareUrl};
      dstPaths = {obj.RootInstallDir};
    end

    function res = isCompiled(obj)
      res = exist(obj.BinPath,'file');
    end

    function compile(obj)
      % Run cmake; make and make install
      import helpers.*;
      if obj.isCompiled()
        return;
      end
      if ~exist(obj.SrcDir,'dir')
        error('Source code of Kaze feature detector not present in %s.',...
          obj.SrcDir);
      end
      fprintf('Patching Kaze - disabling showing the results\n');
      [status msg] = unix(obj.PatchCmd);
      if status ~= 0
        error('Patch error: \n%s',msg);
      end
      fprintf('Compiling Kaze\n');
      % Run cmake with sys. libraries environment
      [status msg] = helpers.osExec(obj.SrcDir,'cmake .','-echo');
      if status ~= 0
        error('CMake error: \n%s',msg);
      end
      % Run Make
      [status msg] = helpers.osExec(obj.SrcDir,'make','-echo');
      if status ~= 0
        error('Make error: \n%s',msg);
      end
    end
  end
end
