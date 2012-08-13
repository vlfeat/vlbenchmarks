function [ fileName ] = getFileName( path )
%SEPARATEFILENAME Get the file name from the path

[path fileName exp] = fileparts(path);

fileName = [fileName exp];
end

