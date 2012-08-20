classdef Logger < handle
  %LOGGER Abstract class implementing different levels of verbosity of a
  %  class.
  
  properties
    verboseLevel = helpers.Logger.DEBUG;  % Log level of messages to stdout
    fileVerboseLevel = helpers.Logger.OFF;     % Lof level of messages to logFile
    logFile = fullfile('data','log'); % Path to log file
    logLabel = '';
  end
  
  properties (Constant)
    % Verbose levels
    ALL = 4;
    TRACE = 3;
    DEBUG = 2;
    INFO = 1;
    WARN = 0;
    ERROR = -1;
    OFF = -2;
    
    levelStr = containers.Map(...
      {helpers.Logger.TRACE,helpers.Logger.DEBUG,helpers.Logger.INFO, ...
      helpers.Logger.WARN,helpers.Logger.ERROR},...
      {'TRACE','DEBUG','INFO','WARN','ERROR'});
  end
 
  methods
    function remArgs = configureLogger(obj,logLabel,varargin)
      import helpers.*;
      obj.logLabel = logLabel;
      opts.verbose = obj.verboseLevel;
      opts.fileVerbose = obj.fileVerboseLevel;
      opts.logFile = obj.logFile;
      [opts remArgs] = vl_argparse(opts,varargin{:});
      obj.verboseLevel = opts.verbose; 
      obj.fileVerboseLevel = opts.fileVerbose;
      obj.logFile = opts.logFile;
    end
    
    function trace(obj, varargin)
      obj.log(obj.TRACE,varargin{:});
    end
    
    function debug(obj, varargin)
      obj.log(obj.DEBUG,varargin{:});
    end
    
    function info(obj, varargin)
      obj.log(obj.INFO,varargin{:});
    end
    
    function warn(obj, varargin)
      obj.log(obj.WARN,varargin{:});
    end
    
    function error(obj, varargin)
      obj.log(obj.ERROR,varargin{:});      
    end
  end
  
  methods (Access = protected)
    function log(obj, level, varargin)
      if level <= obj.verboseLevel
        obj.displayLog(level,varargin{:});
      end
      if ~isempty(obj.logFile) && level <= obj.fileVerboseLevel
        obj.logToFile(level,varargin)
      end
    end
    
    function displayLog(obj,level,varargin)
      import helpers.*;
      str = sprintf(varargin{:});
      if level == obj.WARN
        warning(str);
      elseif level == obj.ERROR
        error(str);
      else
        % Adjust this to modify your output to stdout
        display(sprintf('(%s)\t%s:\t%s',obj.levelStr(level),obj.logLabel,str));
      end
    end
    
    function logToFile(obj,level,varargin)
      lFile = fopen(obj.logFile,'a');
      name = obj.getName();
      str = srpintf(varargin{:});
      % Adjust this to modify the output to log file
      fprintf(lFile,'%s \t %s:%s %s\n',...
        datestr(clock),obj.levelStr(level),name,str);
      fclose(lFile);
    end
  end
end

