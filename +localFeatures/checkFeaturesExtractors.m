% Check all local features extractors

import localFeatures.*;

detectors = {};
cvInst = helpers.OpenCVInstaller();
if cvInst.isInstalled();
  detectors = [detectors {cmpHessian()}];
  detectors = [detectors {cvFast()}];
  detectors = [detectors {cvOrb()}];
  detectors = [detectors {cvSift()}];
  detectors = [detectors {cvStar()}];
  detectors = [detectors {cvSurf()}];
end

detectors = [detectors {ebr()}];
detectors = [detectors {ibr()}];
detectors = [detectors {loweSift()}];
detectors = [detectors {sfop()}];
detectors = [detectors {vggAffine()}];
detectors = [detectors {vggMser()}];
detectors = [detectors {vlFeatCovdet('Method','DoG')}];
detectors = [detectors {vlFeatCovdet('Method','Hessian')}];
detectors = [detectors {vlFeatMser()}];

dataset = datasets.vggAffineDataset('Category','graf');
imgPath = dataset.getImagePath(1);
randomDet = randomFeaturesGenerator();

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