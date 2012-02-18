% This abstract class defines the interface for a generic dataset for evaluating
% affine detectors
% It inherits from the handle class, so that means you can maintain
% state inside an object of this class.

classdef genericDataset < handle
  properties (SetAccess=protected, GetAccess=public)
    datasetName % Set this property in the constructor
    numImages % Set in constructor
  end

  properties (SetAccess=public, GetAccess=public)
    % None here
  end

  methods(Abstract)
    imgPath = getImagePath(obj,imgIdx) % Return the full image
    % path of image number imgIdx in the dataset
    tfs = getTransformation(obj,imgIdx) % Return the 3x3 homograph
    % from image 1 to image imgIdx
  end

  methods(Static)

    % Over-ride this function to download and install data in the right location
    function installDeps()
      fprintf('No dependencies to install for this dataset class\n');
    end

  end

end % -------- end of class ---------
