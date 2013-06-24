classdef GenericConsistencyModel < handle

% Authors: Karel Lenc

% AUTORIGHTS
  
  methods
    [corresps consistency subsres] = findConsistentCorresps(obj, ...
      sceneGeometry, refFrames, frames);
  end
  
  methods (Static)
     sceneGeometry = createSceneGeometry(obj);
  end
  
end

