import affineDetectors.*;

datasetNames = {'graf','wall','bikes','bark','trees'};

for d = 1%:numel(datasetNames)
  datasetName = datasetNames{d};

  dataset = vggDataset('category',datasetName);
  
  %detectors{1} = vlFeatCovdet('AffineAdaptation',true,'Orientation',false,'Method','hessian');
  vlf_old_aff = '/home/kaja/projects/c/vlfeat-old-aff-norm/toolbox/mex/mexa64/vl_covdet.mexa64';
  detectors{1} = vlFeatCovdet('AffineAdaptation',true,'Orientation',false,'Method','hessian','Magnif',1);
  detectors{1}.detectorName = 'VLf Hessian affine (no or.) + mag.';
%  detectors{1}.binPath{1} = vlf_old_aff;
  %detectors{2} = cmpHessian();
  detectors{2} = vggNewAffine('Detector', 'hessian');

  storage = framesStorage(dataset, 'calcDescriptors', false);
  storage.addDetectors(detectors);

  storage.calcFrames();


  %%
  img_id = 1;
  firstDetector = 1;
  secondDetector = 2;

  frames1 = storage.frames{firstDetector}{img_id};
  frames2 = storage.frames{secondDetector}{img_id};
  
  
  [ frames1Matches frames2Matches ] = find_matches(frames1,frames2,0.8);

  %% Store the original image and frames
  %storage.plotFrames(frames1,frames2,frames1,frames2,1,1,matchIdxs);

  
  %vl_plotframe(frames1,'linewidth', 1);
  %title(sprintf('%s det. frames',detectors{firstDetector}.detectorName)); 
  %print(sprintf('comp_%s_frms_1.pdf',datasetName),'-dpdf');

  %figure(1); clf;
  %colormap gray ;
  %h=gcf;
  %set(h,'PaperOrientation','landscape');
  %set(h,'PaperUnits','normalized');
  %set(h,'PaperPosition', [0 0 1 1]);
  % Plot all the frames of the second detector in green
  %hold on ; imshow(imageA); 
  %vl_plotframe(frames2,'linewidth', 1,'r');
  %title(sprintf('%s det. frames',detectors{secondDetector}.detectorName)); 
  %axis image;
  %print(sprintf('comp_%s_frms_2.pdf',datasetName),'-dpdf');


  %%
  
  draw_matches( imageA, frames1, frames2, frames1Matches, frames2Matches,... 
    detectors{firstDetector}.detectorName, detectors{secondDetector}.detectorName,...
     datasetName);

end
