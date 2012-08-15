function str = struct2str(s,separator)
% STRUCT2STR Convert structure to a string
%   String is formated as ($ as separator):
%     field1_name$filed2_name...$s(1).field1_name$...$s(n).field1_name
%   i.e. filed names separated by seprator followed by all the values of
%   the structure array.

if nargin == 1
  separator = ';';
end
  
names=fieldnames(s);
values=struct2cell(s);
 
chars = cellfun(@mat2str,[names' reshape(values,1,[])],'UniformOutput',false);
chars(2,:) = {separator};
chars(2,end) = {''};
str = [chars{:}];
end