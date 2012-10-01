function [ fileName ] = getFileName( path )
%GETFILENAME Get file name from its path

[drop fileName exp] = fileparts(path);
fileName = [fileName exp];
end