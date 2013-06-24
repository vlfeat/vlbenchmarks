function [ ext ] = getFileExtension( path )
%GETFILEEXTENSION Get file extension from its path.

[drop drop ext] = fileparts(path);
end