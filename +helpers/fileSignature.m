function [ signature ] = fileSignature( varargin )
%FILESIGNATURE Compute a file signature
%   Computes file signature based on its name and modification date.
%   Returns a string "file_name;modification_date". The file_name
%   is without path and the modification date is in format of matlab dir
%   function date format.

signature = '';

for i = 1:nargin
  f_info = dir(varargin{i});
  signature = strcat(signature,sprintf('%s;%s;', f_info.name, f_info.date));
end

end

