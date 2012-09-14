% Check all local features extractors

import localFeatures.*;

detectors = {};
cvInst = helpers.OpenCVInstaller();
if cvInst.isInstalled();
  detectors = [detectors {CmpHessian()}];
  detectors = [detectors {CvFast()}];
  detectors = [detectors {CvOrb()}];
  detectors = [detectors {CvSift()}];
  detectors = [detectors {CvStar()}];
  detectors = [detectors {CvSurf()}];
end

detectors = [detectors {Ebr()}];
detectors = [detectors {Ibr()}];
detectors = [detectors {LoweSift()}];
detectors = [detectors {Sfop()}];
detectors = [detectors {VggAffine()}];
detectors = [detectors {VggMser()}];
detectors = [detectors {VlFeatCovdet('Method','DoG')}];
detectors = [detectors {VlFeatCovdet('Method','Hessian')}];
detectors = [detectors {VlFeatMser()}];

dataset = datasets.VggAffineDataset('Category','graf');
imgPath = dataset.getImagePath(1);
randomDet = RandomFeaturesGenerator();

for detector = detectors
  % Test frames detection
  detector = detector{:};
  detector.disableCaching();
  if ~isempty(detector.detectorName)
    frames = detector.extractFeatures(imgPath);
    fprintf('%s - extracted %d frames.\n',detector.name, size(frames,2));
    
    if ~isempty(detector.descriptorName)
      [frames descs] = detector.extractFeatures(imgPath);
      fprintf('%s - extracted %d frames and descriptors.\n',...
        detector.name, size(frames,2));
    end
  end
  if detector.extractsDescriptors
    frames = randomDet.extractFeatures(imgPath);
    [drop descs] = detector.extractDescriptors(imgPath, frames);
    fprintf('%s - extracted %d descriptors from %d frames.\n',...
      detector.name, size(descs,2),size(frames,2));
  end
  
end