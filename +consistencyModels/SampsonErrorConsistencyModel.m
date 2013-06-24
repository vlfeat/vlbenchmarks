classdef SampsonErrorConsistencyModel < consistencyModels.GenericConsistencyModel ...
  & helpers.Logger
%UNTITLED4 Summary of this class goes here
  
  properties
    Opts = struct('maxError', 10);
  end
  
  methods
    function obj = SampsonErrorConsistencyModel(varargin)
      varargin = obj.configureLogger('SampsonErr CM',varargin);
      obj.Opts = vl_argparse(obj.Opts, varargin);
    end
    
    function [corresps consistency subsres] = findConsistentCorresps(obj, ...
        sceneGeometry, framesA, framesB)
      
      subsres = struct();
      % Calculate number of possible correct matches (correspondences)
      [A B] = meshgrid(1:size(framesA,2),1:size(framesB,2)); % all A-B frames combinations
      errs_all = obj.sampsonError(sceneGeometry.F,framesA(1:2,A(:)), framesB(1:2,B(:)));
      hasCorresp = errs_all <  obj.Opts.maxError^2;
      corresps = [A(hasCorresp);B(hasCorresp)];
      consistency = -errs_all(hasCorresp);
    end
    
    function signature = getSignature(obj)
      signature = [helpers.struct2str(obj.Opts)];
    end
  end
  
  methods (Static)
    function sceneGeometry = createSceneGeometry(F)
      sceneGeometry = struct('F', F);
    end
    
    function err = sampsonError( F, u1, u2 )
      % SAMPSONERROR Calculate sampson error of image correspondences
      %   ERRORS = SAMPSONERROR(F, U1, U2) Computes sampson errors ERRORS for
      %   all image correspondeces U1, U2 (where size(U1,2) == size(U2,2))
      %   using the fundamental matrix F.

      if size(u1,2) ~= size(u2,2), obj.error('Invalid correspondeces'); end;
      if size(u1,1) == 2, u1 = [u1;ones(1,size(u1,2))]; end;
      if size(u2,1) == 2, u2 = [u2;ones(1,size(u2,2))]; end;

      nom = sum((u2' * F)'.*u1).^2;
      fu1 = (F * u1).^2;
      fu2 = (F' * u2).^2;
      den = sum(fu1(1:2,:)) + sum(fu2(1:2,:));
      err = nom ./ den;
    end
  end
end

