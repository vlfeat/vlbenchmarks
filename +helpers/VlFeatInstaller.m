classdef VlFeatInstaller < helpers.GenericInstaller
% VLFEATINSTALLER Downloads and installs VLFeat library
%    See or adjust constant class arguments for details about the 
%    library version or location.
%
%    The MEXFLAGS constant property can be used for your mexFiles
%    which depend and link to the VLFeat library.
    
  properties (Constant)
    installVersion = '0.9.14';
    installDir = fullfile('data','software','vlfeat');
    name = ['vlfeat-' helpers.VlFeatInstaller.installVersion];
    dir = fullfile(pwd,helpers.VlFeatInstaller.installDir,...
      helpers.VlFeatInstaller.name,'');
    url = sprintf('http://www.vlfeat.org/download/vlfeat-%s-bin.tar.gz',...
      helpers.VlFeatInstaller.installVersion);
    mexDir = fullfile(helpers.VlFeatInstaller.dir,'toolbox','mex',mexext);
    makeCmd = 'make';
    
    % Flags for mex files which link to VLFeat
    MEXFLAGS = sprintf('LDFLAGS=''"\\$LDFLAGS -Wl,-rpath,%s"'' -L%s -lvl -I%s',...
      helpers.VlFeatInstaller.mexDir,helpers.VlFeatInstaller.mexDir,...
      helpers.VlFeatInstaller.dir);
  end
  
  methods
    function obj = VlFeatInstaller(minVersion)
      % VLFEATINSTALLER VLFeat library installer
      % VLFEATINSTALLER(MIN_VERSION) Construct VLFeat installer and check
      % whether atl least the MIN_VERSION of VlFeat is available.
      if ~exist('minVersion','var'), return; end;
      numVersion =  str2double(char(regexp(obj.installVersion,'\.','split'))');
      numMinVersion = str2double(char(regexp(minVersion,'\.','split'))');
      if numVersion < numMinVersion
        error('VlFeat version >= %s not available. Change the version in file %s.',...
          numMinVersion,mfilename);
      end
	  if obj.isInstalled()
        obj.setup();
      end
	end

    function setup(obj)
      if(~exist('vl_demo','file')),
        vlFeatDir = helpers.VlFeatInstaller.dir;
        if(exist(vlFeatDir,'dir'))
          run(fullfile(vlFeatDir,'toolbox','vl_setup.m'));
        else
          error('VLFeat not found, cannot setup properly.\n');
        end
      end
    end
  end

  methods (Access=protected)
    function [urls dstPaths] = getTarballsList(obj)
      import helpers.*;
      urls = {VlFeatInstaller.url};
      dstPaths = {VlFeatInstaller.installDir};
    end
    
    function compile(obj)
      import helpers.*;
      if obj.isCompiled()
        return;
      end
      
      fprintf('Compiling vlfeat\n');
      
      prevDir = pwd;
      cd(VlFeatInstaller.dir);

      status = system(VlFeatInstaller.makeCmd);
      cd(prevDir);
      
      if status ~= 0
        error('VLFeat compilation was not succesfull.\n');
      end
	  obj.setup();
    end
    
    function res = isCompiled(obj)
      import helpers.*;
      res = exist(VlFeatInstaller.mexDir,'dir');
    end

    function deps = getDependencies(obj)
      deps = {helpers.Installer};
    end
  end
end

