classdef YaelInstaller < helpers.GenericInstaller
% YAELINSTALLER Installer of Yael library
%
%   This script on default tries to download the binary. When no binary is
%   available for your architecture, it tries to compile it. However for
%   succesful compilation you need to have 'python-dev' and 'swig' packages
%   or similar available on your operating system.
%
%   Architectures with available binaries are 'GLNXA64' and 'MACIA64'.
%
%   Yael is not available for Microsoft Windows machines.
%
%   Map YaelInstaller.DistMetricParamMap contains mapping between abbrev.
%   of supported distance metrics to the argument values:
%
%     'L1' ,'L2', 'CHI2' (symmetric chi^2), ACHI2 (symmetric chi^2 with
%     absolute value), 'HI' (histogram intersection - sum of min values), 
%     'DP' (dot product), 'L2O' (optimised L2) and 'DPO' (optimised dot
%     product).
%   
%   See Yael reference manual for details.
%
%   See also: computer

% Authors: Karel Lenc

% AUTORIGHTS
  properties (Constant)
    InstallDir = fullfile('data','software','yael');
    GlnxA64Url = 'https://gforge.inria.fr/frs/download.php/30399/yael_matlab_linux64_v277.tar.gz';
    MaciA64Url = 'https://gforge.inria.fr/frs/download.php/30399/yael_matlab_linux64_v277.tar.gz';
    SrcUrl = 'https://gforge.inria.fr/frs/download.php/30394/yael_v277.tar.gz';

    MexDir = fullfile(helpers.YaelInstaller.InstallDir,'matlab');
    DistMetricParamMap = containers.Map(...
      {'L1','L2','CHI2','ACHI2','HI','DP','L20','DPO'},...
      {1,2,3,4,5,6,12,16});

    % Compilation
    ConfigCmd = './configure.sh';
    MakeCmd = 'make';
    MexMakeCmd = 'make';
  end

  methods
    function obj = YaelInstaller()
      if obj.isInstalled()
        obj.setup();
      end
    end
  end

  methods (Access=protected)
    function [urls dstPaths] = getTarballsList(obj)
      import helpers.*;
      arch = computer();
      switch arch
        case 'GLNXA64'
          urls = {YaelInstaller.GlnxA64Url};
          dstPaths = {YaelInstaller.MexDir};
        case 'MACI64'
          urls = {YaelInstaller.MaciA64Url};
          dstPaths = {YaelInstaller.MexDir};
        otherwise
          warning('Yael Binary for your architecture not available.');
          urls = {YaelInstaller.SrcUrl};
          dstPaths = {YaelInstaller.InstallDir};
      end
    end

    function compile(obj)
      import helpers.*;
      if obj.isCompiled()
        return;
      end
      fprintf('Compiling Yael\n');

      errHelpCmd = sprintf('Compile Yael by hand, located in %s\n',...
        obj.InstallDir);
      prevDir = pwd;
      cd(fullfile(pwd,obj.InstallDir));
      [status msg] = system(obj.ConfigCmd);
      if status ~= 0 
        cd(prevDir);
        error('Yael "%s" failed:\n%s\n%s\n',obj.ConfigCmd,msg,errHelpCmd);
        return;
      end
      [status msg] = system(obj.MakeCmd);
      if status ~= 0 
        cd(prevDir);
        error('Yael "%s" failed:\n%s\n%s\n',obj.MakeCmd,msg,errHelpCmd);
        return;
      end
      cd(fullfile(pwd,obj.MexDir));
      [status msg] = system(obj.MexMakeCmd);
      if status ~= 0 
        cd(prevDir);
        error('Yael "%s" failed:\n%s\n%s\n',obj.MexMakeCmd,msg,errHelpCmd);
        return;
      end
      cd(prevDir);
      obj.setup();
    end

    function res = isCompiled(obj)
      import helpers.*;
      nnBinFile = fullfile(obj.MexDir,['yael_nn.' mexext]);
      res = exist(nnBinFile,'file');
    end
  end
  
  methods 
    function setup(obj)
      addpath(fullfile(pwd,obj.MexDir));
    end
  end
end

