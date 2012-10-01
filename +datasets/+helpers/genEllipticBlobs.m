function [ img ] = genEllipticBlobs(varargin)
% GENELLIPTICBLOBS Generate testing image with multi-variant Gauss. blobs
%   IMG = GENELLIPTICBLOBS('OptionName',OptionValue,...) Generates image IMG
%     with generated multivariate Gaussian blobs according to the settings.
%     There is generated 'NumDeformations' x 'NumDeformations' blobs which are
%     filling the whole image, with size 'Width' x 'Height' (with a certain 
%     border).
%     The size of the blobs is determined in order to fit into the image.
%     Output image is of type double and values are in interval [0;1].
%
%   Available options:
%
%   Width:: 800
%     Output image width
%
%   Height:: 800
%     Output image height
%
%   NumDeformations:: 5
%     Number of blobs in a column with decreasing scale.
%
%   MaxDeformation:: 1/3
%     Maximal blob deformation.

% Authors: Karel Lenc, Andrea Vedaldi

% AUTORIGHTS
opts.width = 800;
opts.height = 800;
opts.numDeformations = 5;
opts.maxDeformation = 1/3;
opts = vl_argparse(opts, varargin);

img = zeros(opts.height,opts.width) ;
border = 4; % Border size in the blobSpacing
blobSpacing = opts.width/opts.numDeformations/6;
xSigmas = linspace(border*blobSpacing,opts.width-border*blobSpacing,...
  opts.numDeformations);
ySigmas = linspace(border*blobSpacing,opts.height-border*blobSpacing,...
  opts.numDeformations);
deformations = linspace(1,opts.maxDeformation,opts.numDeformations);
[x,y]=meshgrid(1:opts.width,1:opts.height) ;

for i=1:opts.numDeformations
  for j=1:opts.numDeformations
    dx = (x - xSigmas(j)) / (blobSpacing*deformations(i)) ;
    dy = (y - ySigmas(i)) / (blobSpacing*deformations(i)*deformations(j)) ;
    d2 = dx.*dx + dy.*dy ;
    img = img + exp(-0.5*d2) ;
  end
end

end

