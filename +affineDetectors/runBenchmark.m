function runBenchmark(detector)
% Function to run a affine co-variant feature detector on
% dataset of images, and measure repeatibility

import affineDetectors.*;

conf.dataDir  = 'data' ; % TODO: make this relative to the current m file, ask Andrea if vlfeat has a fn
conf.imageSel = [1 2] ;

for i=1:6
  imagePaths{i} = fullfile(conf.dataDir, 'graf', sprintf('img%d.ppm',i)) ;
end

for i=1:6
  images{i} = imread(imagePaths{i}) ;
  tfs{i} = textread(fullfile(conf.dataDir, 'graf', sprintf('H1to%dp', i))) ;

  frames{i} = detector(images{i});

  figure(i) ; clf ; imagesc(tmp) ; colormap gray ;
  vl_plotframe(helpers.frametoellipse(frames{i})) ;
end

repeat = [1] ;
repeat_ = repeat ;
vggRepeat = repeat ;

for i=2:6
  framesA = helpers.frametoellipse(frames{1}) ;
  framesB = helpers.frametoellipse(frames{i}) ;

  framesA_ = helpers.ellwhomog(tfs{i},      framesA) ;
  framesB_ = ellwhomog(inv(tfs{i}), framesB) ;

  % find frames fully visible in both images
  bboxA = [1 1 size(images{1}, 2) size(images{1}, 1)] ;
  bboxB = [1 1 size(images{i}, 2) size(images{i}, 1)] ;
  selA = find(ellclip(bboxA, framesA ) & ellclip(bboxB, framesA_)) ;
  selB = find(ellclip(bboxA, framesB_) & ellclip(bboxB, framesB )) ;

  framesA  = framesA(:, selA) ;
  framesA_ = framesA_(:, selA) ;
  framesB  = framesB(:, selB) ;
  framesB_ = framesB_(:, selB) ;

  figure(i) ; clf ;
  subplot(1,2,1) ; imagesc(images{1}) ; colormap gray ;
  hold on ; vl_plotframe(framesA) ; axis equal ;

  subplot(1,2,2) ; imagesc(images{i}) ;
  hold on ; vl_plotframe(framesA_) ; axis equal ;
  vl_plotframe(framesB, 'b', 'linewidth', 1) ;

  ev = evalFrameStability(framesB_, framesA ) ;

  matches = [] ;
  wout_ = zeros(length(framesB_), length(framesA)) ;
  good = zeros(1, size(framesA, 2)) ;

  for j=1:length(framesA)
    numNeighs = length(ev.scores{j}) ;
    if numNeighs > 0
      matches = [matches, ...
                 [j *ones(1,numNeighs) ; ev.neighs{j} ; ev.scores{j} ] ] ;
    end
  end

  % eliminate assigment by priority
  [drop, perm] = sort(matches(3,:), 'descend') ;
  matches = matches(:, perm) ;

  idx = 1 ;
  while idx < size(matches,2)
    isDup = (matches(1, idx+1:end) == matches(1, idx)) | ...
            (matches(2, idx+1:end) == matches(2, idx)) ;
    matches(:, find(isDup) + idx) = [] ;
    idx = idx + 1 ;
  end

  idx = sub2ind(size(wout_), matches(2, :), matches(1, :)) ;
  wout_(idx) = matches(3, :) ;
  good(matches(1, matches(3, :) > .6)) = 1 ;

  repeat(i) = sum(good) / min(length(selA), length(selB)) ;
end

figure(100) ; clf ;
plot(repeat * 100,'linewidth', 3) ; hold on ;
ylabel('repeatab. %') ;
xlabel('image') ;
ylim([0 100]) ;
legend('us', 'vgg') ;
grid on ;
