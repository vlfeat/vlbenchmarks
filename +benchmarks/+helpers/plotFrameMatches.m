function plotFrameMatches(bestMatches,reprojFrames,varargin)
% PLOTFRAMEMATCHES Visualise matched frames in original images.
%   PLOTFRAMEMATCHES(BEST_MATCHES, REPROJ_FRAMES) 
%     Plots matches between frames stored in cell array REPROJ_FRAMES with
%     the following contents:
%
%     REPROJ_FRAMES = {FRAMES_A,FRAMES_B,REPROJ_FRAMES_A,REPROJ_FRAMES_B}
%
%     BEST_MATCHES is an matrix of size [1 size(framesA,2)] where
%     value BEST_MATCHES(iFrameA) is an index of matched frame in
%     FRAMES_B of FRAMES_A(:,iFrameA) or zero if frame is not matched.
%     Matched ellipses are visualised with lines connecting their
%     centres when 'PlotMatchLine' is true.
%
%   PLOTFRAMEMATCHES(...,'OptionName',OptionValue) 
%     Specify further options.
%
%   Available options:
%
%   IsReferenceImage:: true
%     When true, plot matches as in the reference image. When false, plot
%     as when in the tested image (using reprojected frames).
%
%   PlotUnmatched:: true;
%
%   PlotLegend:: true
%     Plot legend.
%
%   PlotMatchLine:: false
%     Plot line between the centres of the matched frames.
%
% See also: plot, helpers.vl_plotframe

% Author: Karel Lenc

% AUTORIGHTS

refImMatchedStyle = {'Color',[0.1 0.1 0.9],'LineWidth',2};
refImUnmatchedStyle = {'Color',[0.2 0.2 0.5],'LineWidth',1};
testImMatchedStyle = {'Color',[0.1 0.9 0.1],'LineWidth',2};
testImUnmatchedStyle = {'Color',[0.2 0.5 0.2],'LineWidth',1};
matchedBgFramesStyle = {'k','LineWidth',4};
matchLineStyle = {'bx-'};
opts.plotUnmatched = true;
opts.plotMatchLine = false;
opts.isReferenceImage = true;
opts.plotLegend = true;
opts = helpers.vl_argparse(opts, varargin);

[framesA,framesB,reprojFramesA,reprojFramesB] = reprojFrames{:};
hold on;

matchBFrames = bestMatches(1,(bestMatches(1,:)~=0));
matchAFrames = find(bestMatches(1,:)~=0);
unmatchAFrames = setdiff(1:size(framesA,2),matchAFrames);
unmatchBFrames = setdiff(1:size(framesB,2),matchBFrames);

if opts.isReferenceImage
  framesB = reprojFramesB;
else
  framesA = reprojFramesA;
end

% Plot the matches in the tested image
if opts.plotUnmatched
  uAF = vl_plotframe(framesA(:,unmatchAFrames),refImUnmatchedStyle{:});
  uBF = vl_plotframe(framesB(:,unmatchBFrames),testImUnmatchedStyle{:});
end
vl_plotframe(framesA(:,matchAFrames),matchedBgFramesStyle{:});
mAF = vl_plotframe(framesA(:,matchAFrames),refImMatchedStyle{:});
vl_plotframe(framesB(:,matchBFrames),matchedBgFramesStyle{:});
mBF = vl_plotframe(framesB(:,matchBFrames),testImMatchedStyle{:});
if opts.plotMatchLine
  for i=1:numel(matchAFrames)
    plot([framesA(1,matchAFrames(i))' framesB(1,matchBFrames(i))'],...
      [framesA(2,matchAFrames(i))' framesB(2,matchBFrames(i))'],...
      matchLineStyle{:});
  end
end

if opts.plotLegend
  if opts.plotUnmatched
    legend([mAF uAF mBF uBF],'Matched ref. image frames', ...
      'Unmatched ref. image frames', 'Matched test image frames',...
      'Unmatched test image frames');
  else
    legend([mAF mBF],'Matched ref. image frames', ...
      'Matched test image frames');
  end
end
end