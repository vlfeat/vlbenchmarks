classdef Logger < handle
  %LOGGER Helper class implementing simple logging framework.
  %  Supports both prinitng of messages to the stdout or writing
  %  to a log file with different verbosity level.
  %  To use the logging framework, define this class as a superclass
  %  and call method configureLogger with the rest of the constructor
  %  arguments. 
  %
  %  Supports the following verbosity levels:
  %  
  %  helpers.Logger.TRACE - Tracing minute detail of the execution.
  %  helpers.Logger.DEBUG - Debugging information.
  %  helpers.Logger.INFO  - Information about execution state
  %  helpers.Logger.WARN  - Warnings, calls warn function.
  %  helpers.Logger.ERROR - Errors, calls error function.
  %  helpers.Logger.OFF   - Ignore everything.
  %
  %  To log, call method trace(msg), debug(msg), info(msg), warn(msg)
  %  or error(msg) according to the importance of the event.
  %
  %  Supports these arguments as ('Name',value) pairs (see vl_argparse)
  %
  %  VerboseLevel :: [helpers.Logger.DEBUG]
  %    Verbose level of messages sent to stdout. If set to OFF all 
  %    messages are ignored, even errors would not stop the program
  %    execution.
  %
  %   FileVerboseLevel :: [helpers.Logger.OFF]
  %     Verbose level of messages which are written into a log file.
  %
  %   LogFile :: [./data/log]
  %   Path to a log file.
  %
  
  properties
    % Verbose level of messages printed to stdout
    verboseLevel = helpers.Logger.DEBUG;
    % Verbose level of messages written to a log file
    fileVerboseLevel = helpers.Logger.OFF;
    % Path to a log file
    logFile = fullfile('data','log');
    % Log label used as a preamble of all messages
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
 
  methods (Access = protected)
    function varargin = configureLogger(obj,logLabel,varargin)
    % args = configureLogger(logLabel, varargin)
    %   Configures the logger. LogLabel defines the preamble of
    %   all the log messages and usually is the name of the class.
    %   varargin are arguments in the vl_argparse ('Name', value)
    %   format, see Logger domuentation for details.
      import helpers.*;
      obj.logLabel = logLabel;
      opts.verbose = obj.verboseLevel;
      opts.fileVerbose = obj.fileVerboseLevel;
      opts.logFile = obj.logFile;
      [opts varargin] = vl_argparse(opts,varargin{:});
      obj.verboseLevel = opts.verbose; 
      obj.fileVerboseLevel = opts.fileVerbose;
      obj.logFile = opts.logFile;
    end
    
    function trace(obj, varargin)
    % trace(varargin) Log a trace message, same args as fprintf.
      obj.log(obj.TRACE,varargin{:});
    end
    
    function debug(obj, varargin)
      % debug(varargin) Log a debug message, same args as fprintf.
      obj.log(obj.DEBUG,varargin{:});
    end
    
    function info(obj, varargin)
    % info(varargin) Log an info message, same args as fprintf.
      obj.log(obj.INFO,varargin{:});
    end
    
    function warn(obj, varargin)
    % warn(varargin) Log a warning message, same args as fprintf. If
    %   the VerboseLevel >= WARN, calls warning function.
      obj.log(obj.WARN,varargin{:});
    end
    
    function error(obj, varargin)
    % ERROR(varargin) Log an error message, same args as fprintf. If
    %   the VerboseLevel >= ERROR, calls error function.
      obj.log(obj.ERROR,varargin{:});      
    end
  end
  
  methods (Access = private)
    function log(obj, level, varargin)
      if level <= obj.verboseLevel
        obj.displayLog(level,varargin{:});
      end
      if ~isempty(obj.logFile) && level <= obj.fileVerboseLevel
        obj.logToFile(level,varargin)
      end
    end
    
    function displayLog(obj,level,varargin)
      % Change this method if you want to change the format
      % of displayed log messages.
      import helpers.*;
      str = sprintf(varargin{:});
      if level == obj.WARN
        warning(str);
      elseif level == obj.ERROR
        error(str);
      else
        % Adjust this to modify your output to stdout
        display(sprintf('(%s)\t%s:\t%s',obj.levelStr(level),...
          obj.logLabel,str));
      end
    end
    
    function logToFile(obj,level,varargin)
      % Change this method if you want to change the format of log
      % messages stored in a log file.
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

