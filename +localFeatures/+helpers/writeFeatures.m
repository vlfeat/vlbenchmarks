function writeFeatures(file, frames, descriptors, varargin)
% WRITEFEATURES Write image features to a file
%   WRITEFEATURES(FILE_PATH, FRAMES, DESCRIPTORS) Write FRAMES and DESCRIPTORS
%   to a file specified by FILE_PATH.
%
%   Features are written in a Oxford format:
%
%   <descriptor length size(descriptors,1)>\n
%   <num features size(frames,2)>\n
%   <Ellipse frame in format 'x_c y_c a b c' s.t. x' [a b ; b c] x = 1>
%   <frame descriptor>\n
%   ...

% Authors: Karel Lenc, Andrea Vedaldi

% AUTORIGHTS
import helpers.*;

opts.verbosity = 0 ;
opts.format = 'oxford';
opts = vl_argparse(opts, varargin) ;

g = fopen(file, 'w');
if g == -1
    error(['Could not open file ''', file, '''.']) ;
end

framesDim = size(frames,1);
if framesDim < 3 || framesDim > 6
  error('Invalid frames format, dimensionality of a frame must be <3,6>');
end

numFrames = size(frames,2);
descrLen = size(descriptors,1);

if numFrames == 0
  fclose(g);
  exit
end

if descrLen > 0 && size(descriptors,2) ~= numFrames
  error('Number of frames and associated descriptors must agree.');
end

% Write header
switch opts.format
  case 'ubc'
    fprintf(g,'%d\n%d\n',numFrames,descrLen);
  case 'oxford'
    fprintf(g,'%d\n%d\n',descrLen,numFrames);
  otherwise
    error('Unknown format ''%s''.', opts.format) ;
end

if(opts.verbosity > 0)
	fprintf('%d keypoints, %d descriptor length.\n', numFrames, descrLen) ;
end

switch opts.format
  case 'ubc'
    % Record format: i,j,s,th
    % TODO implement
    error('Not implemented');

  case 'oxford'
    % Record format: x, y, a, b, c such that x' [a b ; b c] x = 1
    frames  = localFeatures.helpers.frameToEllipse(frames);
    frames(1:2,:) = frames(1:2,:) - 1 ; % change from matlab origin
    frames(3:5,:) = inv2x2(frames(3:5,:)) ; % Inverse the shape matrix
    
    if descrLen == 0
      fprintf(g,'%g %g %g %g %g\n',frames);
    else
      for i=1:size(frames,2)
        fprintf(g,'%g ', frames(:,i)');
        fprintf(g,'%g ', descriptors(:,i)');
        fprintf(g,'\n');
      end
    end 
end
fclose(g) ;
end


% --------------------------------------------------------------------
function S = inv2x2(C)
% --------------------------------------------------------------------
den = C(1,:) .* C(3,:) - C(2,:) .* C(2,:) ;
S = [C(3,:) ; -C(2,:) ; C(1,:)] ./ den([1 1 1], :) ;
end
