function frames = readFramesFile(framesFile)
% READFRAMESFILE Read file exported by some of the older frame detectors.
% vl_ubscread cannot be used because these files contain length of the
% descriptors = 1 which this function is not able to handle.

  fid = fopen(framesFile,'r');
  if fid==-1
    error('Could not read file: %s\n',framesFile);
  end
  [header,count] = fscanf(fid,'%f',2);
  if count~= 2,
    error('Invalid vgg mser output in: %s\n',framesFile);
  end
  numPoints = header(2);
  %frames = zeros(5,numPoints);
  [frames,count] = fscanf(fid,'%f',[5 numPoints]);
  if count~=5*numPoints,
    error('Invalid mser output in %s\n',framesFile);
  end

  % Transform the frame properly
  frames(1:2,:) = frames(1:2,:) + 1;
  C = frames(3:5,:);
  den = C(1,:) .* C(3,:) - C(2,:) .* C(2,:) ;
  S = [C(3,:) ; -C(2,:) ; C(1,:)] ./ den([1 1 1], :) ;
  frames(3:5,:) = S;

  fclose(fid);

end