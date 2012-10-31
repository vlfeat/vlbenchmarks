classdef Surf < localFeatures.GenericLocalFeatureExtractor & ...
    helpers.GenericInstaller

% Authors: Karel Lenc

% AUTORIGHTS
  properties (Constant, Hidden)
    RootInstallDir = fullfile('data','software','surf','');
    BinPath = fullfile(localFeatures.Surf.RootInstallDir,'SURF-V1.0.9','surf.ln');
    SoftwareUrl = 'http://www.vision.ee.ethz.ch/~surf/SURF-V1.0.9.tar.gz';
  end
  
  properties (SetAccess=private, GetAccess=public)
    Opts = struct(...
      'thres', 1000,... % blob response threshold
      'ms', 3,...       % custom lobe size
      'ss', 2,...       % initial sampling step
      'oc', 4,...       % number of octaves
      'u', [],...    % U-SURF (not rotation invariant)
      'e',[],...      % extended descriptor (SURF-128)
      'in', 4);         % descriptor size
  end

  methods
    function obj = Surf(varargin)
      import localFeatures.*;
      import helpers.*;
      % Check platform dependence
      machineType = computer();
      if ~ismember(machineType,{'GLNX86','GLNXA64'})
          error('Arch: %s not supported by EBR',machineType);
      end
      obj.Name = 'SURF';
      varargin = obj.checkInstall(varargin);
      obj.configureLogger(obj.Name,varargin);
      obj.SupportedImgFormats = {'.pgm'};
    end

    function [frames descriptors] = extractFeatures(obj, origImagePath)
      import helpers.*;
      import localFeatures.helpers.*;
      [frames descriptors] = obj.loadFeatures(origImagePath,true);
      if numel(frames) > 0; return; end;      
      obj.info('Computing features of image %s.',getFileName(origImagePath));
      [imagePath imIsTmp] = obj.ensureImageFormat(origImagePath);
      tmpName = tempname;
      outFeaturesFile = [tmpName '.surf'];
      args = obj.buildArgs(imagePath, outFeaturesFile);
      cmd = [obj.BinPath ' ' args];
      obj.debug('Executing: %s',cmd);
      startTime = tic;
      [status,msg] = system(cmd,'-echo');
      if status ~= 0
        error('%d: %s: %s', status, cmd, msg) ;
      end
      timeElapsed = toc(startTime);
      [frames descriptors] = readFeaturesFile(outFeaturesFile,'FloatDesc',true);
      delete(outFeaturesFile);
      if imIsTmp, delete(imagePath); end;
      obj.debug('%d features from image %s computed in %gs',...
        size(frames,2),getFileName(imagePath),timeElapsed);
      obj.storeFeatures(imagePath, frames, descriptors);
    end
    
    function [frames descriptors] = extractDescriptors(obj, origImagePath, frames)
      import localFeatures.helpers.*;
      obj.info('Computing descriptors of %d frames.',size(frames,2));
      [imagePath imIsTmp] = obj.ensureImageFormat(origImagePath);
      tmpName = tempname;
      framesFile = [tmpName '.frames'];
      writeFeatures(framesFile, frames, []);
      outFeaturesFile = [tmpName '.surf'];
      args = obj.buildArgs(imagePath, outFeaturesFile);
      args = [args ' -p1 ',framesFile];
      cmd = [obj.BinPath ' ' args];
      obj.debug('Executing: %s',cmd);
      startTime = tic;
      [status,msg] = system(cmd,'-echo');
      if status ~= 0
        error('%d: %s: %s', status, cmd, msg) ;
      end
      [frames descriptors] = readFeaturesFile(outFeaturesFile,'FloatDesc',true);
      delete(outFeaturesFile);
      if imIsTmp, delete(imagePath); end;
      timeElapsed = toc(startTime);
      obj.debug('Descriptors of %d frames computed in %gs',...
        size(frames,2),timeElapsed);
    end

    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.BinPath)...
        helpers.struct2str(obj.Opts)];
    end
  end

  methods (Access=protected)
    function args = buildArgs(obj, imagePath, outFile)
      % -nl - do not write the hessian keypoint type
      args = sprintf('-nl -i "%s" -o "%s"',...
        imagePath, outFile);
      fields = fieldnames(obj.Opts);
      for i = 1:numel(fields)
        val = obj.Opts.(fields{i});
        if ~isempty(val)
          % Handle the bool options
          if ismember(fields{i},{'u','e'})
            if val
              args = [args,' -',fields{i}];
            end
          else
            args = [args,' -',fields{i},' ', num2str(val)];
          end
        end
      end
    end
    
    function [urls dstPaths] = getTarballsList(obj)
      import localFeatures.*;
      urls = {Surf.SoftwareUrl};
      dstPaths = {Surf.RootInstallDir};
    end

    function compile(obj)
      import localFeatures.*;
      % When unpacked, ebr is not executable
      helpers.setFileExecutable(Surf.BinPath);
    end
  end
end
