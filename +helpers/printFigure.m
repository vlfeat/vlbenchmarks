function printFigure(path, fileName, R)
  % PRINTFIGURE Save figure to an *.eps image file
  %   printFigure(PATH, IMG_FILE_NAME, R) Saves the actual figure to a file
  %   fullfile(PATH,[IMG_FILE_NAME,'.eps']). The third parameter sets 
  %   PaperPosition property of the current figure so that the width of 
  %   the figure is the fraction R of a 'uslsetter' page.
  %   If path is an empty string, nothing is done.
  %
  %   See also: vl_printsize
  if isempty(path), return; end;
  if ~exist(path, 'dir')
    mkdir(path) ;
  end
  if ~exist('R','var')
    R = 0.75;
  end
  vl_printsize(gcf, R) ;
  filePath = fullfile(path, [fileName '.eps']) ;
  print(gcf, '-depsc2',filePath) ;
  fprintf('%s: wrote file ''%s''\n', mfilename,  filePath) ;
end