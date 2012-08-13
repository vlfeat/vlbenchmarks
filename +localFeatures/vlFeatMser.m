% VLFEATMSER class to wrap around the VLFeat MSER implementation
%
%   obj = affineDetectors.vlFeatMser('Option','OptionValue',...);
%   frames = obj.detectPoints(img)
%
%   This class wraps aronud the MSER implementation of VLFeat
%
%   The options to the constructor are the same as that for vl_mser
%   See help vl_mser to see those options and their default values.
%
%   Additional options:
%
%   Magnification :: [3]
%     Magnification of the region size used for descriptor calculation.
%
%   See also: vl_mser


classdef vlFeatMser < localFeatures.genericLocalFeatureExtractor
  properties (SetAccess=private, GetAccess=public)
    % See help vl_mser for setting parameters for vl_mser
    vl_mser_arguments
    binPath
    opts
  end

  methods
    % The constructor is used to set the options for vl_mser call
    % See help vl_mser for possible parameters
    % The varargin is passed directly to vl_mser
    function obj = vlFeatMser(varargin)
      obj.detectorName = 'MSER(vlFeat)';
      obj.opts.magnification = 3;
      obj.opts.noAngle = false;
      [obj.opts varargin] = vl_argparse(obj.opts,varargin);
      obj.vl_mser_arguments = varargin;
      obj.binPath = which('vl_mser');
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      import helpers.*;
      import localFeatures.*;
      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      if numel(frames) > 0; return; end;
      
      startTime = tic;
      Log.info(obj.detectorName,...
        sprintf('computing frames for image %s.',getFileName(imagePath)));       
      
      img = imread(imagePath);
      if(size(img,3)>1), img = rgb2gray(img); end
      img = im2uint8(img); % If not already in uint8, then convert

      [xx brightOnDarkFrames] = vl_mser(img,obj.vl_mser_arguments{:});

      [xx darkOnBrightFrames] = vl_mser(255-img,obj.vl_mser_arguments{:});

      frames = vl_ertr([brightOnDarkFrames darkOnBrightFrames]);
      sel = frames(3,:).*frames(5,:) - frames(4,:).^2 >= 1 ;
      frames = frames(:, sel) ;
      
      if nargout == 2
        [ frames descriptors ] = helpers.vggCalcSiftDescriptor( imagePath, ...
                  frames, 'Magnification', obj.opts.magnification, ...
                  'NoAngle', obj.opts.noAngle );
      end
      
      timeElapsed = toc(startTime);
      Log.debug(obj.detectorName, ... 
        sprintf('Frames of image %s computed in %gs',...
        getFileName(imagePath),timeElapsed));
      
      obj.storeFeatures(imagePath, frames, descriptors);
    end
    
    function sign = getSignature(obj)
      sign = [helpers.fileSignature(obj.binPath) ';'...
              evalc('disp(obj.vl_mser_arguments)')];
    end

  end
end
