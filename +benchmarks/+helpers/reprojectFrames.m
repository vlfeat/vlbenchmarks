function [reprojFramesA,reprojFramesB] = reprojectFrames(framesA,framesB,tfs)
  import benchmarks.helpers.*;

  % Change from Matlab origin
  framesA(1:2,:) = framesA(1:2,:) - 1 ;
  framesB(1:2,:) = framesB(1:2,:) - 1 ;
  
  % Reproject
  reprojFramesA = warpEllipse(tfs,framesA) ;
  reprojFramesB = warpEllipse(inv(tfs),framesB) ;

  % Move reprojected frames back to Matlab origin
  reprojFramesA(1:2,:) = reprojFramesA(1:2,:) + 1 ;
  reprojFramesB(1:2,:) = reprojFramesB(1:2,:) + 1 ;
end