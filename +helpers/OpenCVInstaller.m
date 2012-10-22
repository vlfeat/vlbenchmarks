classdef OpenCVInstaller < helpers.GenericInstaller
% helpers.OpenCVInstaller Downloads and compiles OpenCV library
%   For compilation, cmake binary, which can be executed from
%   Matlab environment must be present in your PATH.
%   Downloads OpenCV Library and compiles it using the compiler 
%   specified in mex configuration. Because OpenCV uses a libstdc++
%   library, the compiler used for mex compilation must be using 
%   same or older version of the libstdc++ as Matlab does or the 
%   OpenCV would not be linked. The same holds for the cmake binary 
%   file. 
%   To change the version or cmake arguments see the  constant
%   properties of this class.
%   Your OpenCV distribution can be also compiled 'by hand' when
%   'make install' output files are located in 
%   './data/OpenCV-%VERSION%/install' folder. See constant properties.

% Author: Karel Lenc

% AUTORIGHTS
  properties (Constant)
    % Version of the installed OpenCV
    Version = '2.4.2';
    % Name of the OpenCV directory
    Name = sprintf('OpenCV-%s',helpers.OpenCVInstaller.Version);
    % Path to base OpenCV directory
    SoftwareDir = fullfile('data','software',helpers.OpenCVInstaller.Name);
    % URL with tarball with source code
    SoftwareUrl = sprintf('http://sourceforge.net/projects/opencvlibrary/files/opencv-unix/%s/OpenCV-%s.tar.bz2',...
      helpers.OpenCVInstaller.Version,helpers.OpenCVInstaller.Version);
    % Target directory for make install
    InstallDir = fullfile(pwd,helpers.OpenCVInstaller.SoftwareDir,'install');
    % Directory where sources are built
    BuildDir = fullfile(helpers.OpenCVInstaller.SoftwareDir,'build');
    % Location of OpenCV libraries
    LibDir = fullfile(helpers.OpenCVInstaller.InstallDir,'lib');
    % Location of OpenCV headers
    IncludeDir = fullfile(helpers.OpenCVInstaller.InstallDir,'include');
    
    % Make command
    MakeCommand = 'make';
    % CMake command
    CmakeCommand = 'cmake';
    % CMake build arguments
    CmakeArgs = {...
      sprintf('-DCMAKE_INSTALL_PREFIX:PATH="%s"',...
        helpers.OpenCVInstaller.InstallDir),...
      sprintf('-DCMAKE_CXX_COMPILER:FILEPATH="%s"',...
        mex.getCompilerConfigurations('C++','Selected').Details.CompilerExecutable),...
      sprintf('-DCMAKE_C_COMPILER:FILEPATH="%s"',...
        mex.getCompilerConfigurations('C','Selected').Details.CompilerExecutable),...
      '-DBUILD_ZLIB:BOOL="1"',...
      '-DBUILD_PACKAGE:BOOL="0"',...
      '-DBUILD_WITH_DEBUG_INFO:BOOL="0"',...
      '-DBUILD_PERF_TESTS:BOOL="0"',...
      '-DBUILD_DOCS:BOOL="0"', ...
      '-DBUILD_opencv_legacy:BOOL="0"',... 
      '-DBUILD_opencv_ml:BOOL="0"',...
      '-DBUILD_opencv_stitching:BOOL="0"',...
      '-DBUILD_opencv_highgui:BOOL="0"',...
      '-DBUILD_opencv_calib3d:BOOL="0"',...
      '-DBUILD_opencv_videostab:BOOL="0"',...
      '-DBUILD_opencv_gpu:BOOL="0"',...
      '-DBUILD_opencv_video:BOOL="0"',...
      '-DBUILD_opencv_photo:BOOL="0"',...
      '-DBUILD_opencv_ts:BOOL="0"',...
      '-DBUILD_opencv_objdetect:BOOL="0"'};
  end
  
  methods (Access=protected)
    function [urls dstPaths] = getTarballsList(obj)
      import helpers.*;
      urls = {OpenCVInstaller.SoftwareUrl};
      dstPaths = {OpenCVInstaller.SoftwareDir};
    end
    
    function compile(obj)
      % Run cmake; make and make install
      import helpers.*;
      if obj.isCompiled()
        return;
      end
      
      if ~exist(OpenCVInstaller.SoftwareDir,'dir')
        error('Source code of OpenCV not present in %s.',...
          OpenCVInstaller.SoftwareDir);
      end
      
      fprintf('Compiling OpenCV\n');
      
      srcDir = fullfile('..',OpenCVInstaller.Name);
      
      prevDir = pwd;
      vl_xmkdir(OpenCVInstaller.BuildDir);
      
      % Run cmake
      args = cell2str(OpenCVInstaller.CmakeArgs,' ');
      cmd = cell2str({OpenCVInstaller.CmakeCommand,srcDir,args},' ');
      
      % Run cmake with sys. libraries environment
      status = helpers.osExec(OpenCVInstaller.BuildDir,cmd,'-echo');
      
      if status ~= 0
        error('CMake was not succesfull, error status %d',status);
      end
      
      % Run Make
      cd(OpenCVInstaller.BuildDir);
      status = unix(OpenCVInstaller.MakeCommand,'-echo');
      cd(prevDir);
      
      if status ~= 0
        error('Make was not succesfull, error status %d',status);
      end
      
      % Run Make Install
      cd(OpenCVInstaller.BuildDir);
      status = unix([OpenCVInstaller.MakeCommand ' install'],'-echo');
      cd(prevDir);
      
      if status ~= 0
        error('Make install was not succesfull, error status %d',status);
      end
      
      cd(prevDir);
    end

    function res = isCompiled(obj)
      import helpers.*;
      res = exist(obj.LibDir,'dir') && exist(obj.IncludeDir,'dir');
    end

    function deps = getDependencies(obj)
      deps = {helpers.Installer};
    end
  end
  
  methods (Static)
    function mexflags = getMexFlags()
    % getMexFlags Get flags for compilation of mex files
    %   MEX_FLAGS = getMexFlags() Returns mex flags needed for compilation
    %   of mex files which link to OpenCV library.
      import helpers.*;
      switch computer()
        case {'GLNX86','GLNXA64'}
        mexflags = sprintf(...
          'LDFLAGS=''"\\$LDFLAGS -Wl,-rpath,%s"'' -L%s -lopencv_core -lopencv_imgproc -lopencv_features2d -lopencv_contrib -lopencv_nonfree -I%s',...
          OpenCVInstaller.LibDir,OpenCVInstaller.LibDir,...
          OpenCVInstaller.IncludeDir);
        otherwise
          warning('Architecture not supported yet.');
      end
    end
  end
end
