function writenetpbm( image, imPath )
% WRITENETPBM Write image into a ppm/pgm file with a correct header
%  WRITENETPBM(IMAGE, PATH) Writes image IMAGE to a ppm/pgm file PATH 
%    using Matlab's imwrite and fixes the file header.
%    This function was created as Matlab-created ppm/pgm files does not use
%    correct headers (they are missing '\n') which cause failures of some
%    binary detectors.

% Authors: Karel Lenc

% AUTORIGHTS
[pth name ext] = fileparts(imPath);
if strcmp(ext,'.ppm')
  format = 'P6';
elseif strcmp(ext,'.pgm')
  format = 'P5';
else
  error('Invalid image file extension.');
end

imwrite(image, imPath);

imFile = fopen(imPath,'r+');
fseek(imFile, 0, 'bof');
fprintf(imFile, [format '\n']);
fprintf(imFile, '%d %d\n',size(image,2),size(image,1));
fprintf(imFile, '255\n');
fclose(imFile);
end
