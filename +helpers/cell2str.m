function str = cell2str(c,separator)
% CELL2STR Convert  cell arr. of mat. and strings to a string.
%   out = cell2str(cellArray, separator) 
%   Convert cell array of mat. arrays and strings to a single string
%   String is formated as ($ as separator):
%     str(c(1))$str(c(2))$...
%   If cell content is not a string, mat2str is called. 
%
%   out = cell2str(cellArray) convert to a string, values seprated 
%   by ';'
%
if nargin == 1
  separator = ';';
end
  
chars = cellfun(@tostr, reshape(c,1,[]),'UniformOutput',false);
chars(2,:) = {separator};
if ~isempty(chars)
  chars(2,end) = {''};
end
str = [chars{:}];


  function str = tostr(m)
    if ischar(m)
      str = m;
    else
      str = mat2str(m);
    end
  end
end