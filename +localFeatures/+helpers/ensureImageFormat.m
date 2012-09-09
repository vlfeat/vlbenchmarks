function [imagePath isTemp] = ensureImageFormat(imagePath, supportedFormats)
  % ENSUREIMAGEFORMAT Ensure that image format is supported
  % NIMAGE_PATH = ENSUREIMAGEFORMAT(IMG_PATH, SUPPORTED) checks
  %   whether image format, defined by its extension of IMG_PATH is
  %   supported, i.e. the extension is in SUPPORTED. If not, new
  %   temporary image '.ppm' or '.pgm' is created.
  %   This script suppose that at least the '.pgm' format is supported.
  % [NIMAGE_PATH IS_TMP] = ENSUREIMAGEFORMAT(IMG_PATH, SUPPORTED)
  %   IS_TMP is true when temporary image is created as this image
  %   should be deleted in the end.
  import helpers.*;
  [path name ext] = fileparts(imagePath);
  if ismember(ext, supportedFormats)
    isTemp = false;
    return;
  else
    isTemp = true;
    tmpName = tempname;
    image = imread(imagePath);
    if size(image,3) == 3
      if ismember('.ppm',supportedFormats)
        imagePath = [tmpName,'.ppm'];
        helpers.writenetpbm(image, imagePath);
      else
        imagePath = [tmpName,'.pgm'];
        image = rgb2gray(image);
        helpers.writenetpbm(image, imagePath);
      end
    elseif size(image,3) == 1
      imagePath = [tmpName,'.pgm'];
      image = rgb2gray(image);
      helpers.writenetpbm(image, imagePath);
    end
  end
end