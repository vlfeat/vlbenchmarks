classdef OpenCVInstaller < helpers.GenericInstaller
    
  properties (Constant)
    % Version of the installed OpenCV
    version = '2.4.2';
    % Name of the OpenCV directory
    name = sprintf('OpenCV-%s',helpers.OpenCVInstaller.version);
    % Path to base OpenCV directory
    dir = fullfile('data','software',helpers.OpenCVInstaller.name);
    % URL with tarball with source code
    url = sprintf('http://sourceforge.net/projects/opencvlibrary/files/opencv-unix/%s/OpenCV-%s.tar.bz2',...
      helpers.OpenCVInstaller.version,helpers.OpenCVInstaller.version);
    % Target directory for make install
    installDir = fullfile(pwd,helpers.OpenCVInstaller.dir,'install');
    % Directory where sources are built
    buildDir = fullfile(helpers.OpenCVInstaller.dir,'build');
    % Location of OpenCV libraries
    libDir = fullfile(helpers.OpenCVInstaller.installDir,'lib');
    % Location of OpenCV headers
    includeDir = fullfile(helpers.OpenCVInstaller.installDir,'include');
    
    % LDFLAGS for mex compilation
    MEXFLAGS = sprintf('LDFLAGS=''"\\$LDFLAGS -Wl,-rpath,%s"'' -L%s -lopencv_core -lopencv_imgproc -lopencv_features2d -lopencv_nonfree -I%s',...
      helpers.OpenCVInstaller.libDir,helpers.OpenCVInstaller.libDir,...
      helpers.OpenCVInstaller.includeDir);
    
    % Make command
    makeCommand = 'make';
    % CMake command
    cmakeCommand = 'cmake';
    % CMake build arguments
    cmakeArgs = {...
      sprintf('-DCMAKE_INSTALL_PREFIX:PATH="%s"',helpers.OpenCVInstaller.installDir),...
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
  
  methods (Static)    
    function [urls dstPaths] = getTarballsList()
      import helpers.*;
      urls = {OpenCVInstaller.url};
      dstPaths = {OpenCVInstaller.dir};
    end
    
    function compile()
      import helpers.*;
      if OpenCVInstaller.isCompiled()
        return;
      end
      
      if ~exist(OpenCVInstaller.dir,'dir')
        error('Source code of OpenCV not present in %s.',...
          OpenCVInstaller.dir);
      end
      
      fprintf('Compiling OpenCV\n');
      
      srcDir = fullfile('..',OpenCVInstaller.name);
      
      prevDir = pwd;
      vl_xmkdir(OpenCVInstaller.buildDir);
      
      % Run cmake
      args = cell2str(OpenCVInstaller.cmakeArgs,' ');
      cmd = cell2str({OpenCVInstaller.cmakeCommand,srcDir,args},' ');
      
      cd(OpenCVInstaller.buildDir);
      status = unix(cmd,'-echo');
      cd(prevDir);
      
      if status ~= 0
        error('CMake was not succesfull, error status %d',status);
      end
      
      % Run Make
      cd(OpenCVInstaller.buildDir);
      status = unix(OpenCVInstaller.makeCommand,'-echo');
      cd(prevDir);
      
      if status ~= 0
        error('Make was not succesfull, error status %d',status);
      end
      
      % Run Make Install
      cd(OpenCVInstaller.buildDir);
      status = unix([OpenCVInstaller.makeCommand ' install'],'-echo');
      cd(prevDir);
      
      if status ~= 0
        error('Make install was not succesfull, error status %d',status);
      end
      
      cd(prevDir);
    end
    
    function res = isCompiled()
      import helpers.*;
      res = exist(OpenCVInstaller.libDir,'dir') ...
        && exist(OpenCVInstaller.includeDir,'dir');
    end
  end
    
end

