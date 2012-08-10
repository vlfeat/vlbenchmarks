classdef genericTest < handle
  %GENERICTEST Generic test of affine covariant detector.
  %   genericTest(framesStorage, test_name,'Option','OptionValue',...)
  %   This class implements mutual parts of affine covariant
  %   detectors test.
  %
  %   Options:
  %
  %   SaveResultss :: [true]
  %     Do save results. Saves both figures and computed scores.
  %
  %   SaveDir :: ['/test_name/']
  %     Directory where results are saved. 
  
  properties
    opts              % Affine test options
    framesStorage     % Handle of the frames storage
    test_name         % Name of the test shown in the results
    det_signatures    % Signatures of detectors used for stored results
  end
  
  methods (Abstract)
  
    runTest(obj)
    %RUNTEST
    % Do run the test and show the results.
    
    plotResults(obj)
    printResults(obj)
    
  end
  
  methods
    
    function obj=genericTest(framesStorage, test_name, varargin)
      obj.framesStorage = framesStorage;
      obj.test_name = test_name;
      
      % -------- create options ------------------------
      obj.opts.SaveResults = true;
      obj.opts.SaveDir = ['./' test_name '/'];
      if numel(varargin) > 0
        obj.opts = commonFns.vl_argparse(obj.opts,varargin);
      end
    end
    
    
    function printScores(obj,scores,outFile, name)
      % PRINTSCORES
      % Print the scores measured in the unified format to the standard 
      % output. If opts.SaveResults defined, save the results to 
      % opts.SaveDir/outFile.
      numDetectors = obj.framesStorage.numDetectors();
      detNames = obj.framesStorage.detectorsNames;

      if(obj.opts.SaveResults)
        datasetName = obj.framesStorage.dataset.datasetName;
        fH = fopen(fullfile(obj.opts.SaveDir,datasetName,outFile),'w');
        fidOut = [1 fH];
      else
        fidOut = 1;
      end

      maxNameLen = 0;
      for i = 1:numDetectors
        maxNameLen = max(maxNameLen,length(detNames{i}));
      end

      maxNameLen = max(length('Method name'),maxNameLen);
      obj.myprintf(fidOut,strcat('\nPriting ', name,':\n'));
      formatString = ['%' sprintf('%d',maxNameLen) 's:'];

      obj.myprintf(fidOut,formatString,'Method name');
      for i = 1:size(scores,2)
        obj.myprintf(fidOut,'\tImg#%02d',i);
      end
      obj.myprintf(fidOut,'\n');

      for i = 1:numDetectors
        obj.myprintf(fidOut,formatString,detNames{i});
        for j = 1:size(scores,2)
          obj.myprintf(fidOut,'\t%6s',sprintf('%.2f',scores(i,j)));
        end
        obj.myprintf(fidOut,'\n');
      end

      if(obj.opts.SaveResults)
        fclose(fH);
      end
    end

    function plotScores(obj, figureNum, outFile, score, title_text, ...
                        y_label, xstart)
      % PLOTSCORES
      % Plot the scores into unified figure number figureNum. If 
      % opts.SaveResults is true, save the figure to opts.SaveDir/outFile
      %
      % Parameters:
      %   figureNum   Output figure number
      %   name        Name of the figure, used 
      %   score       Data to plot
      %   title_text  Title of the figure
      %   y_label     Y label of the figure
      %   xstart      First X-value to plot
      if isempty(score)
        warning('No scores to plot.');
        return
      end
      
      if isempty(xstart)
          xstart = 1;
      end
      detectors = obj.framesStorage.detectors;
      dataset = obj.framesStorage.dataset;
      
      figure(figureNum) ; clf ;
      xend = size(score,2);
      x_label = dataset.imageLabelsTitle;
      x_ticks = dataset.imageLabels;
      plot(xstart:xend,score(:,xstart:xend)','linewidth', 3) ; hold on ;
      ylabel(y_label) ;
      xlabel(x_label);
      set(gca,'XTick',xstart:1:xend);
      set(gca,'XTickLabel',x_ticks);
      title(title_text);
      set(gca,'xtick',1:size(score,2));
      
      maxScore = max([max(max(score)) 1]);
      meanEndValue = mean(score(:,xend));
      legendLocation = 'SouthEast';
      if meanEndValue < maxScore/2
        legendLocation = 'NorthEast';
      end

      legendStr = cell(1,numel(detectors));
      for i = 1:numel(detectors) 
        legendStr{i} = detectors{i}.getName(); 
      end
      legend(legendStr,'Location',legendLocation);
      grid on ;
      axis([xstart xend 0 maxScore]);

      if(obj.opts.SaveResults)
        datasetName = obj.framesStorage.dataset.datasetName;
        vl_xmkdir(fullfile(obj.opts.SaveDir,datasetName));
        figFile = fullfile(obj.opts.SaveDir,datasetName,strcat(outFile,'.eps'));
        fprintf('\nSaving figure as eps graphics: %s\n',figFile);
        print('-depsc2',figFile);
        figFile = fullfile(obj.opts.SaveDir,datasetName,strcat(outFile,'.fig'));
        fprintf('Saving figure as matlab figure to: %s\n',figFile);
        saveas(gca,figFile);
      end
    end
    
    
    function has_changes = frames_has_changed(obj,iDetector)
      % HAS_CHANGES
      % Returns true, if the frames detected by detector of index iDetector
      % has changed from the last test evaluation.
      if iDetector > numel(obj.det_signatures)
        has_changes = true;
        return
      end
      
      local_det_signature = obj.det_signatures{iDetector};
      act_det_signature = obj.framesStorage.det_signatures{iDetector};
      has_changes = ~isequal(local_det_signature, act_det_signature);
    end
  end
  
  methods(Static)
    function myprintf(fids,format,varargin)
      % MYPRINTF
      % Helper extending printf to more outputs.
      % Parameters:
      %   fids    Array of output file idxs
      %   format, varargin See fprintf.
      for i = 1:numel(fids)
        fprintf(fids(i),format,varargin{:});
      end
    end
  end
  
end

