classdef Logger < handle
% helpers.Logger A simple logger class
%  Logger supports both printing of messages to the console or writing
%  them to a log file with different verbosity levels. To use the
%  logging framework, define this class as a superclass and call
%  method configureLogger(LogLabel).
%
%  Logger supports the following verbosity levels:
%
%    helpers.Logger.TRACE - Tracing minute detail of the execution.
%    helpers.Logger.DEBUG - Debugging information.
%    helpers.Logger.INFO  - Information about execution state
%    helpers.Logger.WARN  - Warnings, calls warn function.
%    helpers.Logger.ERROR - Errors, calls error function.
%    helpers.Logger.OFF   - Ignore everything.
%
%  To log a message, call method trace(msg), debug(msg), info(msg),
%  warn(msg) or error(msg) according to the importance of the event.
%
%  Method configureLogger(LogLabel, 'OptionName', OptionValue) accepts
%  the following options:
%
%  VerboseLevel:: [helpers.Logger.DEBUG]
%    Verbosity level of messages sent to stdout. If set to OFF all
%    messages are ignored, even errors would not stop the program
%    execution.
%
%  FileVerboseLevel:: [helpers.Logger.OFF]
%    Verbosity level of messages which are written into a log file.
%
%  LogFile :: [./data/log]
%     Path to a log file.

% Author: Karel Lenc

% AUTORIGHTS

  properties (GetAccess=public, SetAccess = protected)
    % Verbose level of messages printed to stdout
    VerboseLevel = helpers.Logger.DEBUG;
    % Verbose level of messages written to a log file
    FileVerboseLevel = helpers.Logger.OFF;
    % Path to a log file. If you want to distinguish between the hosts
    % on which the the static values were created you can use something
    % like:
    % LogFile = fullfile('data',['log-',helpers.hostname(),...
    %   randsample(char(97:122),5)]);
    LogFile = fullfile('data','log');
    % Log label used as a preamble of all messages
    LogLabel = '';
  end

  properties (Constant, Hidden)
    ALL = 4; % Log all
    TRACE = 3; % Log tracing events
    DEBUG = 2; % Log debugging events
    INFO = 1; % Log informative events
    WARN = 0; % Log warnings
    ERROR = -1; % Log errors only
    OFF = -2; % Do not log

    levelStr = containers.Map(...
      {helpers.Logger.TRACE,helpers.Logger.DEBUG,helpers.Logger.INFO, ...
      helpers.Logger.WARN,helpers.Logger.ERROR},...
      {'TRACE','DEBUG','INFO','WARN','ERROR'});
  end

  methods (Access = protected, Hidden)
    function varargin = configureLogger(obj,LogLabel,varargin)
    % configureLogger Configure logger options
    %   remArgs = obj.configureLogger(LogLabel, varargin)
    %   Configures the logger. LogLabel defines the preamble of
    %   all the log messages and usually is the name of the class.
    %   varargin are arguments in the vl_argparse ('Name', value)
    %   format, see Logger documentation for details.
      import helpers.*;
      obj.LogLabel = LogLabel;
      opts.verbose = obj.VerboseLevel;
      opts.fileVerbose = obj.FileVerboseLevel;
      opts.logFile = obj.LogFile;
      [opts varargin] = vl_argparse(opts,varargin{:});
      obj.VerboseLevel = opts.verbose;
      obj.FileVerboseLevel = opts.fileVerbose;
      obj.LogFile = opts.logFile;
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
      if level <= obj.VerboseLevel
        obj.displayLog(level,varargin{:});
      end
      if ~isempty(obj.LogFile) && level <= obj.FileVerboseLevel
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
          obj.LogLabel,str));
      end
    end

    function logToFile(obj,level,varargin)
      % Change this method if you want to change the format of log
      % messages stored in a log file.
      lFile = fopen(obj.LogFile,'a');
      name = obj.getName();
      str = srpintf(varargin{:});
      % Adjust this to modify the output to log file
      fprintf(lFile,'%s \t %s:%s %s\n',...
        datestr(clock),obj.levelStr(level),name,str);
      fclose(lFile);
    end
  end
end
