function writeppm( image, imPath )
% WRITEPPM Write image into a ppm file with a correct header
%  WRITEPPM(IMAGE, PATH) Writes image IMAGE to a ppm file PATH and fixes
%    the header.

[pth name ext] = fileparts(imPath);
if ~strcmp(ext,'.ppm')
  error('Invalid image file extension.');
end

imwrite(image, imPath);

imFile = fopen(imPath,'r+');
fseek(imFile, 0, 'bof');
fprintf(imFile, 'P6\n');
fprintf(imFile, '%d %d\n',size(image,2),size(image,1));
fprintf(imFile, '255\n');
fclose(imFile);

end

