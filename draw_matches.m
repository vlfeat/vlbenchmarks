function draw_matches( image, frames1, frames2, frames1Matches, frames2Matches, firstDetectorName, secondDetectorName, datasetName )

  figure(1); clf;
  h=gcf;
  set(h,'PaperOrientation','landscape');
  set(h,'PaperUnits','normalized');
  set(h,'PaperPosition', [0 0 1 1]);
  colormap gray ;
  % Plot all the frames of the second detector in green
  hold on ; imshow(image);  axis image;
  title('Original image'); 
  drawnow;
  %print(sprintf('comp_%s_a.pdf',datasetName),'-dpdf');

% Plot the matched frames of the first detector
  vl_plotframe(frames2(:,(frames2Matches.matches ~= 0)),'linewidth',1);
  vl_plotframe(frames1(:,(frames1Matches.matches ~= 0)),'b','linewidth',1); 
  title(sprintf('Matched frames (max ov. err 0.1) blue - %s, green - %s',...
    firstDetectorName, secondDetectorName));
  drawnow;
%  print(sprintf('comp_%s_frms_3.pdf',datasetName),'-dpdf');

  
  figure(2); clf;
  colormap gray ;
  h=gcf;
  set(h,'PaperOrientation','landscape');
  set(h,'PaperUnits','normalized');
  set(h,'PaperPosition', [0 0 1 1]);
  hold on ; imshow(image); axis image;

  % Plot the unmatched frames of the first detector in red.
  vl_plotframe(frames1(:,(frames1Matches.matches == 0)),'r','linewidth',1);

  frames1_unmatched = sum(frames1Matches.matches ~= 0);
  fprintf('Frames detected only by %s: %d\n',...
    firstDetectorName,...
    size(frames1,2) - frames1_unmatched);
  
  % Plot the unmatched frames of the second detector in green.
  vl_plotframe(frames2(:,(frames2Matches.matches == 0)),'g','linewidth',1);

  frames2_unmatched = sum(frames2Matches.matches ~= 0);
  title(sprintf('(red - frames only by %s (%d), green - frames only by %s (%d)',...
  firstDetectorName,size(frames1,2) - frames1_unmatched,...
  secondDetectorName,size(frames2,2) - frames2_unmatched));
  drawnow;
  %print(sprintf('comp_%s_frms_4.pdf',datasetName),'-dpdf');

  fprintf('Frames detected only by %s: %d\n',...
    secondDetectorName,...
    size(frames2,2) - frames2_unmatched);


end

