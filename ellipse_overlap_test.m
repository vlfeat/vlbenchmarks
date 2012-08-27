import localFeatures.*;
import datasets.*;

datasetNames = {'graf','wall','bikes','bark','trees'};

for d = 1%:numel(datasetNames)
  datasetName = datasetNames{d};

  
  dataset = vggAffineDataset('category',datasetName);
  
  detectors{1} = vlFeatCovdet('AffineAdaptation',true,'Orientation',false,'Method','hessian');
%  detectors{1}.binPath{1} = vlf_old_aff;
  detectors{2} = cmpHessian();
  %detectors{2} = vggNewAffine('Detector', 'hessian'); detectors{2}.detectorName = 'VGG hesaff';
  %detectors{2} = vlFeatCovdet('AffineAdaptation',true,'Orientation',false,'Method','dog');


  %%
  img_id = 1;
  d1 = 1;
  d2 = 2;

  imgPath = dataset.getImagePath(1);
  img = datasets.helpers.genEll();
  %imgPath = [tempname '.pgm'];
  %imwrite(img,imgPath);
  
  [framesA a] = detectors{d1}.extractFeatures(imgPath);
  [framesB a] = detectors{d2}.extractFeatures(imgPath);
  
  
  [ bestMatches ] = find_matches(framesA,framesB,0.8);

  img = imread(imgPath);

  figure(101); clf; imshow(img); colormap gray; hold on ; 

  % Plot the transformed and matched frames from B on A in blue
  matchedBFrames = bestMatches(1,(bestMatches(1,:)~=0));
  matchedAFrames = find(bestMatches(1,:)~=0);
  %vl_plotframe(framesB(:,matchedBFrames),'g','linewidth',1);
  % Plot the remaining frames from B on A in red
  unmatchedBFrames = setdiff(1:size(framesB,2),matchedBFrames);
  unmatchedAFrames = setdiff(1:size(framesA,2),matchedAFrames);
  
  colors = distinguishable_colors(25);
  
  vl_plotframe(framesB(:,unmatchedBFrames),'k','linewidth',3);
  vl_plotframe(framesA(:,unmatchedAFrames),'k','linewidth',3);
  uBF = vl_plotframe(framesB(:,unmatchedBFrames),'Color',colors(1,:),'linewidth',1);
  uAF = vl_plotframe(framesA(:,unmatchedAFrames),'Color',colors(2,:),'linewidth',1);

 
  legend([uAF uBF],...
    sprintf('Unmatched frames of %s',detectors{d1}.detectorName), ... 
    sprintf('Unmatched frames of %s',detectors{d2}.detectorName));

end
