classdef Log
  %UNTITLED Summary of this class goes here
  %   Detailed explanation goes here
  
  properties (Constant)
    displayLogLevel = 2;  % Log level of messages to stdout
    fileLogLevel = 7;     % Lof level of messages to logFile
    logFile = fullfile('data','log'); % Path to log file
    
    % Log levels - same as in log4j
    ALL = 0;
    TRACE = 1;
    DEBUG = 2;
    INFO = 3;
    WARN = 4;
    ERROR = 5;
    OFF = 6;
    
    levelStr = {'TRACE','DEBUG','INFO','WARN','ERROR','FATAL'};
  end
  
  methods(Static)
    function trace(name, str)
      import helpers.Log;
      Log.log(Log.TRACE,name,str);
    end
    
    function debug(name, str)
      import helpers.Log;
      Log.log(Log.DEBUG,name,str);
    end
    
    function info(name, str)
      import helpers.Log;
      Log.log(Log.INFO,name,str);
    end
    
    function warn(name, str)
      import helpers.Log;
      Log.log(Log.WARN,name,str);
    end
    
    function error(name, str)
      import helpers.Log;
      Log.log(Log.ERROR,name,str);      
    end
    
    function log(level, name, str)
      import helpers.Log;
      if level >= Log.displayLogLevel
        Log.displayLog(level,name,str);
      end
      
      if ~isempty(Log.logFile) && level >= Log.fileLogLevel
        Log.logToFile(level,name,str)
      end
    end
    
    function displayLog(level,name,str)
      import helpers.Log;
      if level == Log.WARN
        warning(str);
      elseif level == Log.ERROR
        error(str);
      else
        display(sprintf('(%s)\t%s:\t%s',Log.levelStr{level},name,str));
      end
    end
    
    function logToFile(level,name,str)
      import helpers.Log;
      lFile = fopen(Log.logFile,'a');
      fprintf(lFile,'%s \t %s:%s %s\n',...
        datestr(clock),Log.levelStr{level},name,str);
      fclose(lFile);
    end
  end
  
end

