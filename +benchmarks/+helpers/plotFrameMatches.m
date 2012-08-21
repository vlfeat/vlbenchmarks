function plotFrameMatches(bestMatches, reprojectedFrames,...
                          imageAPath, figA, imageBPath, figB)

  imageA = imread(imageAPath);
  imageB = imread(imageBPath);

  [framesA,framesB,reprojFramesA,reprojFramesB] = reprojectedFrames{:};

  figure(figA); imshow(imageA); colormap gray; hold on ; 
  aF = vl_plotframe(framesA,'linewidth', 1);
  % Plot the transformed and matched frames from B on A in blue
  matchedBFrames = bestMatches(1,(bestMatches(1,:)~=0));
  mBF = vl_plotframe(reprojFramesB(:,matchedBFrames),'b','linewidth',1);
  % Plot the remaining frames from B on A in red
  unmatchedBFrames = setdiff(1:size(framesB,2),matchedBFrames);
  uBF = vl_plotframe(reprojFramesB(:,unmatchedBFrames),'r','linewidth',1);
  title('Reference image detections');
  legend([aF mBF uBF],'Det. frames in Ref. Image', ... 
    'Matched transf. image frames','Unmatched transf. image frames');

  if nargin > 4
    figure(figB); imshow(imageB);  colormap gray; hold on ; 
    bF = vl_plotframe(framesB,'linewidth', 1);
    % Plot the transformed and matched frames from A on B in blue
    matchedAFrames = find(bestMatches(1,:)~=0);
    mAF = vl_plotframe(reprojFramesA(:,matchedAFrames), 'b', 'linewidth', 1);
    unmatchedAFrames = setdiff(1:size(framesA,2),matchedAFrames);
    uAF = vl_plotframe(reprojFramesA(:,unmatchedAFrames),'r','linewidth',1);
    title('Transformed image detections');
    legend([bF mAF uAF],'Det. frames in Transf. Image', ... 
    'Matched ref. image frames','Unmatched ref. image frames');
  end
end