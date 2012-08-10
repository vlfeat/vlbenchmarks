% VGGNEWAFFINE class to wrap around the VGG new affine co-variant detectors.
%
%   obj = affineDetectors.vggNewAffine('Option','OptionValue',...);
%   frames = obj.detectPoints(img)
%
%   This class implements the genericDetector interface and wraps around the
%   vgg implementation of harris and hessian affine detectors (Philbin
%   version).
%
%   The constructor call above takes the following options:
%
%   Detector:: ['hessian']
%     One of 'hessian' or 'harris' to select what type of corner detector to use
%
%   thresh:: [10]
%     Threshold for harris corner detection (only used when detector is 'harris')
%
%   noAngle:: [false]
%     Compute rotation variant descriptors if true (no rotation esimation)
%
%   Magnification:: [binary default]
%     Magnification of the measurement region for the descriptor
%     calculation.
%



classdef vggNewAffine < affineDetectors.genericDetector
  properties (SetAccess=private, GetAccess=public)
    opts
    detBinPath
    descrBinPath
  end

  methods
    % The constructor is used to set the options for vggNewAffine
    function this = vggNewAffine(varargin)
      import affineDetectors.*;
      import commonFns.*;
      this.calcDescs = true;

      if ~vggNewAffine.isInstalled(),
        this.isOk = false;
        this.errMsg = 'vggNewAffine not found installed';
        return;
      end

      % Parse the passed options
      this.opts.detector= 'hessian';
      this.opts.thresh = -1;
      this.opts.noAngle = false;
      this.opts.magnification = -1;
      this.opts = vl_argparse(this.opts,varargin);

      switch(lower(this.opts.detector))
        case 'hessian'
          this.opts.detectorType = 'hesaff';
        case 'harris'
          this.opts.detectorType = 'haraff';
        otherwise
          error('Invalid detector type: %s\n',this.opts.detector);
      end
      this.detectorName = [this.opts.detector '-affine(new vgg)' ];

      % Check platform dependence
      cwd=commonFns.extractDirPath(mfilename('fullpath'));
      machineType = computer();
      this.detBinPath = '';
      this.descrBinPath = '';
      switch(machineType)
        case {'GLNXA64'}
          this.detBinPath = fullfile(cwd,vggNewAffine.rootInstallDir,...
                             'detect_points_2.ln');
          this.descrBinPath = fullfile(cwd,vggNewAffine.rootInstallDir,...
                             'compute_descriptors_2.ln');
        otherwise
          this.isOk = false;
          this.errMsg = sprintf('Arch: %s not supported by vggNewAffine',...
                                machineType);
      end
    end

    function [frames descrs] = detectPoints(this,img)
      if ~this.isOk, frames = zeros(5,0); return; end
      
      tmpName = tempname;
      imgFile = [tmpName '.ppm'];
      outFrmFile = [tmpName '.ppm.' this.opts.detectorType];
      outDescFile = [tmpName '.ppm.' this.opts.detectorType '.sift'];
      
      desc_param = '';
      
      if this.opts.magnification > 0
        desc_param = [desc_param,' -scale-mult ', ...
          num2str(this.opts.magnification)];
      end

      imwrite(uint8(img),imgFile);
      detArgs = '';
      if this.opts.thresh >= 0
        detArgs = sprintf('-thres %f ',this.opts.thresh);
      end
      detArgs = sprintf('%s-%s -i "%s" -o "%s" %s',...
                     detArgs, this.opts.detectorType,...
                     imgFile,outFrmFile);
      descrArgs = sprintf('-sift -i "%s" -p1 "%s" -o1 "%s" %s',...
                     imgFile,outFrmFile, outDescFile,desc_param);
      if this.opts.noAngle
        descrArgs = strcat(descrArgs,' -noangle');
      end
      detCmd = [this.detBinPath ' ' detArgs];
      descrCmd = [this.descrBinPath ' ' descrArgs];

      [status,msg] = system(detCmd);
      if status
        error('%d: %s: %s', status, detCmd, msg) ;
      end
      
      if nargout ==2
        [status,msg] = system(descrCmd);
        if status
          error('%d: %s: %s', status, descrCmd, msg) ;
        end
        [frames descrs] = vl_ubcread(outDescFile,'format','oxford');
        delete(outDescFile);
      else
        % read the frames in own way because the output files are not
        % correct (descr. size is set to 1 even when it is zero...).
        fid = fopen(outFrmFile, 'r');
        dim=fscanf(fid, '%f',1);
        if dim==1
          dim=0;
        end
        nb=fscanf(fid, '%d',1);
        frames = fscanf(fid, '%f', [5+dim, inf]);
        fclose(fid);
        
        % Compute the inverse of the shape matrix
        frames(1:2,:) = frames(1:2,:) + 1 ; % matlab origin
        den = frames(3,:) .* frames(5,:) - frames(4,:) .* frames(4,:) ;
        frames(3:5,:) = [frames(5,:) ; -frames(4,:) ; frames(3,:)] ./ den([1 1 1], :) ;    
      end
      
      delete(imgFile);  delete(outFrmFile);
    end
    
    function sign = signature(obj)
      sign = [commonFns.file_signature(obj.detBinPath) ';' ... 
              commonFns.file_signature(obj.descrBinPath) ';' ... 
              obj.opts.detectorType ';' ... 
              num2str(obj.opts.magnification) ';' ... 
              num2str(obj.opts.noAngle) ';' ... 
              num2str(obj.opts.thresh)];
    end

  end

  properties (Constant)
    rootInstallDir = 'thirdParty/vggNewAffine/';
  end

  methods (Static)

    function response = isInstalled()
      import affineDetectors.*;
      cwd = commonFns.extractDirPath(mfilename('fullpath'));
      installDir = fullfile(cwd,vggNewAffine.rootInstallDir);
      if(exist(installDir,'dir')),  response = true;
      else response = false; end
    end

  end % ---- end of static methods ----

end % ----- end of class definition ----
