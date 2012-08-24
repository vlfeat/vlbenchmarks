function plotFrameMatches(bestMatches, reprojectedFrames,...
  imageAPath, figA, imageBPath, figB)
  
  matchLineStyle = 'bx-';
                        
  imageA = imread(imageAPath);
  imageB = imread(imageBPath);

  [framesA,framesB,reprojFramesA,reprojFramesB] = reprojectedFrames{:};

  figure(figA); imshow(imageA); colormap gray; hold on ; 
  aF = vl_plotframe(framesA,'linewidth', 1);
  % Plot the transformed and matched frames from B on A in blue
  matchedBFrames = bestMatches(1,(bestMatches(1,:)~=0));
  matchedAFrames = find(bestMatches(1,:)~=0);
  % Plot the remaining frames from B on A in red
  unmatchedBFrames = setdiff(1:size(framesB,2),matchedBFrames);
  uBF = vl_plotframe(reprojFramesB(:,unmatchedBFrames),'r','linewidth',1);
  mBF = vl_plotframe(reprojFramesB(:,matchedBFrames),'b','linewidth',1);
  % Plot the connecting lines between matches
  for i=1:numel(matchedAFrames)
    plot([framesA(1,matchedAFrames(i))' reprojFramesB(1,matchedBFrames(i))'],...
      [framesA(2,matchedAFrames(i))' reprojFramesB(2,matchedBFrames(i))'],...
      matchLineStyle);
  end
  title('Reference image detections');
  legend([aF mBF uBF],'Det. frames in Ref. Image', ... 
    'Matched transf. image frames','Unmatched transf. image frames');

  if nargin > 4
    figure(figB); imshow(imageB);  colormap gray; hold on ; 
    bF = vl_plotframe(framesB,'linewidth', 1);
    unmatchedAFrames = setdiff(1:size(framesA,2),matchedAFrames);
    uAF = vl_plotframe(reprojFramesA(:,unmatchedAFrames),'r','linewidth',1);
    % Plot the transformed and matched frames from A on B in blue
    mAF = vl_plotframe(reprojFramesA(:,matchedAFrames), 'b', 'linewidth', 1);
    for i=1:numel(matchedAFrames)
      plot([reprojFramesA(1,matchedAFrames(i))' framesB(1,matchedBFrames(i))'],...
        [reprojFramesA(2,matchedAFrames(i))' framesB(2,matchedBFrames(i))'],...
        matchLineStyle);
    end
    title('Transformed image detections');
    legend([bF mAF uAF],'Det. frames in Transf. Image', ... 
    'Matched ref. image frames','Unmatched ref. image frames');
  end
end