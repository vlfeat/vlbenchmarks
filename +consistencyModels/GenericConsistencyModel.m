classdef GenericConsistencyModel < handle
  %UNTITLED3 Summary of this class goes here
  %   Detailed explanation goes here
  
  methods
    [corresps consistency subsres] = findConsistentCorresps(obj, ...
      sceneGeometry, refFrames, frames);
  end
  
  methods (Static)
     sceneGeometry = createSceneGeometry(obj);
  end
  
end

