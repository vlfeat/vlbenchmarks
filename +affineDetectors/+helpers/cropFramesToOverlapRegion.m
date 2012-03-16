function [framesA,framesB,framesA_,framesB_] = ...
    cropFramesToOverlapRegion(framesA,framesB,tfs,imageA,imageB)
% This function transforms ellipses in A to B (and vice versa), and crops
% them according to their visibility in the transformed frame

  import affineDetectors.*;

  framesA = helpers.frameToEllipse(framesA) ;
  framesB = helpers.frameToEllipse(framesB) ;

  framesA_ = helpers.warpEllipse(tfs,framesA) ;
  framesB_ = helpers.warpEllipse(inv(tfs),framesB) ;

  % find frames fully visible in both images
  bboxA = [1 1 size(imageA, 2) size(imageA, 1)] ;
  bboxB = [1 1 size(imageB, 2) size(imageB, 1)] ;

  selA = helpers.isEllipseInBBox(bboxA, framesA ) & ...
         helpers.isEllipseInBBox(bboxB, framesA_);

  selB = helpers.isEllipseInBBox(bboxA, framesB_) & ...
         helpers.isEllipseInBBox(bboxB, framesB );

  framesA  = framesA(:, selA);
  framesA_ = framesA_(:, selA);
  framesB  = framesB(:, selB);
  framesB_ = framesB_(:, selB);


