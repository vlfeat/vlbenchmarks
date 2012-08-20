function [visibleFramesA visibleFramesB] = ...
    framesInOverlapRegions(framesA, reprojFramesA, framesB, reprojFramesB,imageASize,imageBSize)

  import benchmarks.helpers.*;

  % find frames fully visible in both images
  bboxA = [1 1 imageASize(2) imageASize(1)] ;
  bboxB = [1 1 imageBSize(2) imageBSize(1)] ;

  visibleFramesA = isEllipseInBBox(bboxA, framesA ) & ...
    isEllipseInBBox(bboxB, reprojFramesA);

  visibleFramesB = isEllipseInBBox(bboxA, reprojFramesB) & ...
    isEllipseInBBox(bboxB, framesB );
  
end