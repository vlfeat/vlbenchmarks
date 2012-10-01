classdef TemplateWrapper < localFeatures.GenericLocalFeatureExtractor
% localFeatures.TemplateWrapper Feature detector wrapper template
%   Skeleton of image feature detector wrapper.
%
% See also: localFeatures.ExampleLocalFeatureExtractor

% Author: Your Name
  properties (SetAccess=private, GetAccess=public)
    % Detector options
    Opts = struct(...
      'OptionName','OptionValue'... % A detector option
      );
  end

  methods
    function obj = TemplateWrapper(varargin)
      % Set to true when extractDescriptors implemented
      obj.ExtractsDescriptors = true;
      obj.Name = ''; % Name of the wrapper

      % Parse class options
      obj.Opts = vl_argparse(obj.Opts,varargin);

      % Other constructor stuff...
    end

    function [frames descriptors] = extractFeatures(obj, imagePath)
      % Try to load features from cache
      [frames descriptors] = obj.loadFeatures(imagePath,nargout > 1);
      if numel(frames) > 0; return; end;

      frames = []; descriptors = [];
      if nargout == 1
        obj.info('Computing frames of image %s.',getFileName(imagePath));
        % Code for feature frame detection without descriptors
      else
        obj.info('Computing frames and descriptors of image %s.',...
          getFileName(imagePath));
        % Code for feature frame detection plus their descriptors. 
      end

      % Store features to cache
      obj.storeFeatures(imagePath, frames, descriptors);
    end

    function [frames descriptors] = extractDescriptors(obj, imagePath, frames)
      % Code to extract descriptors of given frames
      descriptors = [];
    end

    function signature = getSignature(obj)
      % Code for generation of detector unique signature
      signature = [helpers.struct2str(obj.Opts),';',...
        helpers.fileSignature(mfilename('fullpath'))];
    end
  end
end
