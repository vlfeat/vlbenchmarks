function printFigure(path, fileName, R, ext)
% PRINTFIGURE Save figure to an *.eps image file
%   printFigure(PATH, IMG_FILE_NAME, R) Saves the actual figure to a file
%   fullfile(PATH,[IMG_FILE_NAME,'.eps']). The third parameter sets 
%   PaperPosition property of the current figure so that the width of 
%   the figure is the fraction R of a 'uslsetter' page.
%   If path is an empty string, nothing is done.
%
%   printFigure(PATH, IMG_FILE_NAME, R, EXT) Save in a format defined by
%   EXT. Default value is 'eps';
%
%   See also: vl_printsize
  
% Authors: Karel Lenc

% AUTORIGHTS
if isempty(path), return; end;
if ~exist(path, 'dir')
  mkdir(path) ;
end
if ~exist('R','var')
  R = 0.75;
end
vl_printsize(gcf, R) ;

if ~exist('ext','var')
  ext = 'eps';
end
filePath = fullfile(path, [fileName '.' ext]) ;
extArgs = containers.Map({'eps','png','jpeg','jpg','ps'},...
  {'-depsc2','-dpng','-djpeg90','-djpeg90','-dpsc2'});

print(gcf,extArgs(ext),filePath) ;
fprintf('%s: wrote file ''%s''\n', mfilename,  filePath) ;
end