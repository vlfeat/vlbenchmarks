function [ img ] = genPersp( )
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
img = repmat(sin((1:1024)/10),1024,1);
tform = maketform('projective',...
                  [0 0.45 0.6 1; 0 1 1 0]', ...
                  [0 0    1    1; 0 1 1 0]');
imgSize = 512;
img = imtransform((img + img')/4+.5, tform, 'bicubic', 'udata', [0 1], 'vdata', [0 1], ...
                  'xdata', [0 1], 'ydata', [0 .65], 'size', [imgSize imgSize], 'fill', 0);


end

