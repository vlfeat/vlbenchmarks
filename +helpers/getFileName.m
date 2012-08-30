function [ fileName ] = getFileName( path )
%GETFILENAME Get file name from the path

[drop fileName exp] = fileparts(path);
fileName = [fileName exp];
end