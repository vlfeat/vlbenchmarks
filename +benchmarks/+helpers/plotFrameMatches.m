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
%   PlotLegend:: true
%     Plot legend.
%
%   PlotMatchLine:: true
%     Plot line between the centres of the matched frames.
%
%   MatchLineStyle:: {'bx-'}
%     Style of the match line. Cell array passed to plot function.
%
%   RefImMatchedStyle:: {'Color',[0.1 0.1 0.9],'LineWidth',2}
%     Style of the matched frames from the reference image. Cell array
%     passed to vl_plotframe function.
%
%   RefImUnmatchedStyle:: {'Color',[0.1 0.1 0.4],'LineWidth',1}
%     Style of the unmatched frames from the reference image. Cell array
%     passed to vl_plotframe function.
%
%   TestImMatchedStyle:: {'Color',[0.1 0.9 0.1],'LineWidth',2};
%     Style of the matched frames from the tested image. Cell array
%     passed to vl_plotframe function.
%
%   TestImUnmatchedStyle:: {'Color',[0.1 0.4 0.1],'LineWidth',1};
%     Style of the unmatched frames from the tested image. Cell array
%     passed to vl_plotframe function.
%
% See also: plot, helpers.vl_plotframe

% AUTORIGHTS

opts.refImMatchedStyle = {'Color',[0.1 0.1 0.9],'LineWidth',2};
opts.refImUnmatchedStyle = {'Color',[0.1 0.1 0.4],'LineWidth',1};
opts.testImMatchedStyle = {'Color',[0.1 0.9 0.1],'LineWidth',2};
opts.testImUnmatchedStyle = {'Color',[0.1 0.4 0.1],'LineWidth',1};
opts.plotMatchLine = true;
opts.matchLineStyle = {'bx-'};
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
  uBF = vl_plotframe(reprojFramesB(:,unmatchBFrames),opts.testImUnmatchedStyle{:});
  uAF = vl_plotframe(framesA(:,unmatchAFrames),opts.refImUnmatchedStyle{:});
  mBF = vl_plotframe(reprojFramesB(:,matchBFrames),opts.testImMatchedStyle{:});
  mAF = vl_plotframe(framesA(:,matchAFrames),opts.refImMatchedStyle{:});
  % Plot the connecting lines between matches
  if opts.plotMatchLine
    for i=1:numel(matchAFrames)
      plot([framesA(1,matchAFrames(i))' reprojFramesB(1,matchBFrames(i))'],...
        [framesA(2,matchAFrames(i))' reprojFramesB(2,matchBFrames(i))'],...
        opts.matchLineStyle{:});
    end
  end
else
  % Plot the matches in the tested image
  uAF = vl_plotframe(reprojFramesA(:,unmatchAFrames),opts.refImUnmatchedStyle{:});
  uBF = vl_plotframe(framesB(:,unmatchBFrames),opts.testImUnmatchedStyle{:});
  mAF = vl_plotframe(reprojFramesA(:,matchAFrames),opts.refImMatchedStyle{:});
  mBF = vl_plotframe(framesB(:,matchBFrames),opts.testImMatchedStyle{:});
  if opts.plotMatchLine
    for i=1:numel(matchAFrames)
      plot([reprojFramesA(1,matchAFrames(i))' framesB(1,matchBFrames(i))'],...
        [reprojFramesA(2,matchAFrames(i))' framesB(2,matchBFrames(i))'],...
        opts.matchLineStyle{:});
    end
  end
end

if opts.plotLegend
  legend([mAF uAF mBF uBF],'Matched ref. image frames', ...
    'Unmatched ref. image frames', 'Matched test image frames',...
    'Unmatched test image frames');
end
end