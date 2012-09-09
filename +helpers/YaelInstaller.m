classdef YaelInstaller < helpers.GenericInstaller
% YAELINSTALLER Installer of Yael library
%
%   Currently supported architectures are only 'GLNXA64' and 'MACIA64'.
%
%   Map YaelInstaller.distMetricParamMap contains mapping between abbrev.
%   of supported distance metrics to the argument values:
%
%     'L1' ,'L2', 'CHI2' (symmetric chi^2), ACHI2 (symmetric chi^2 with
%     absolute value), 'HI' (histogram intersection - sum of min values), 
%     'DP' (dot product), 'L2O' (optimised L2) and 'DPO' (optimised dot
%     product).
%   
%   See Yael reference manual for details.

  properties (Constant)
    installDir = fullfile('data','software','yael');
    glnxA64url = 'https://gforge.inria.fr/frs/download.php/30399/yael_matlab_linux64_v277.tar.gz';
    maciA64url = 'https://gforge.inria.fr/frs/download.php/30399/yael_matlab_linux64_v277.tar.gz';
    srcurl = 'https://gforge.inria.fr/frs/download.php/30394/yael_v277.tar.gz';
    
    mexDir = fullfile(helpers.YaelInstaller.installDir,'matlab');
    distMetricParamMap = containers.Map(...
      {'L1','L2','CHI2','ACHI2','HI','DP','L20','DPO'},...
      {1,2,3,4,5,6,12,16});
  end

  methods (Static)    
    function [urls dstPaths] = getTarballsList()
      import helpers.*;
      arch = computer();
      switch arch
        case 'GLNXA64'
          urls = {YaelInstaller.glnxA64url};
          dstPaths = {YaelInstaller.mexDir};
        case 'MACI64'
          urls = {YaelInstaller.glnxA64url};
          dstPaths = {YaelInstaller.mexDir};
        otherwise
          urls = {YaelInstaller.srcurl};
          dstPaths = {YaelInstaller.installDir};
      end
    end

    function compile()
      import helpers.*;
      if YaelInstaller.isCompiled()
        return;
      end
      error('Not supported architecture.');
    end

    function res = isCompiled()
      import helpers.*;
      nnBinFile = fullfile(YaelInstaller.mexDir,['yael_nn.' mexext]);
      res = exist(nnBinFile,'file');
    end

    function setup()
      addpath(fullfile(pwd,helpers.YaelInstaller.mexDir));
    end
  end
end

