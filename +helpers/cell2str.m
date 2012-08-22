function str = cell2str(c,separator)
% STRUCT2STR Convert structure to a string
%   String is formated as ($ as separator):
%     field1_name$filed2_name...$s(1).field1_name$...$s(n).field1_name
%   i.e. filed names separated by seprator followed by all the values of
%   the structure array.

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