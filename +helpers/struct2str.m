function str = struct2str(s,separator)
% STRUCT2STR Convert structure to a string
%   STR = STRUCT2STR(STRUCT, SEPARATOR) Converts structure STRUCT to a string
%   STR. String is formatted as ($ as separator):
%
%     field1_name$filed2_name...$s(1).field1_name$...$s(n).field1_name
%
%   i.e. filed names separated with separator followed by all the values 
%   of the structure array.

% Authors: Karel Lenc

% AUTORIGHTS
if nargin == 1
  separator = ';';
end
  
names=fieldnames(s);
values=struct2cell(s);
 
str = helpers.cell2str([names' reshape(values,1,[])], separator);
end