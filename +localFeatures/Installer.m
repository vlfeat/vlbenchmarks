classdef Installer < helpers.GenericInstaller
% 
  methods (Static)
    function detectors = getDependencies()
      import localFeatures.*;
      detectors = {};
      % Arguments to disable autoinstallation
      noInstArgs = {'AutoInstall',false};
      % Open CV detector
      cvInst = helpers.OpenCVInstaller();
      if cvInst.isInstalled();
        detectors = {...
          CmpHessian(noInstArgs{:}),...
          CvFast(noInstArgs{:}),...
          CvOrb(noInstArgs{:}),...
          CvSift(noInstArgs{:}),...
          CvStar(noInstArgs{:}),...
          CvSurf(noInstArgs{:})};
      end
      detectors = [detectors,{...
        Ebr(noInstArgs{:}),...
        Ibr(noInstArgs{:}),...
        LoweSift(noInstArgs{:}),...
        Sfop(noInstArgs{:}),...
        VggAffine(noInstArgs{:}),...
        VggMser(noInstArgs{:}),...
        VlFeatCovdet(noInstArgs{:}),...
        VlFeatMser(noInstArgs{:}),...
        VlFeatSift(noInstArgs{:})}];
    end

    function checkDetectors(imgPath)
      % CHECKDETECTORS Run all detectors. Before testing them all used
      % detectors must be installed calling localFeatures.install().
      import localFeatures.*;
      randomDet = RandomFeaturesGenerator();
      detectors = Installer.getDependencies();
      for detector = detectors
        % Test frames detection
        detector = detector{:};
        detector.disableCaching();
        if ~isempty(detector.detectorName)
          frames = detector.extractFeatures(imgPath);
          fprintf('%s - extracted %d frames.\n',detector.name, ...
            size(frames,2));

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
    end
  end
end