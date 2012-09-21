classdef Installer < helpers.GenericInstaller
% 
  methods  (Access=protected)
    function detectors = getDependencies(obj)
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
        %Ebr(noInstArgs{:}),...
        Ibr(noInstArgs{:}),...
        LoweSift(noInstArgs{:}),...
        Sfop(noInstArgs{:}),...
        VggAffine(noInstArgs{:}),...
        VggMser(noInstArgs{:}),...
        VlFeatCovdet(noInstArgs{:}),...
        VlFeatMser(noInstArgs{:}),...
        VlFeatSift(noInstArgs{:})}];
    end
  end

  methods (Static)
    function checkDetectors(imgPath)
      % CHECKDETECTORS Run all detectors. Before testing them all used
      % detectors must be installed calling localFeatures.install().
      import localFeatures.*;
      randomDet = RandomFeaturesGenerator();
      detectors = Installer().getDependencies();
      for detIdx = 1:numel(detectors)
        % Test frames detection
        detector = detectors{detIdx};
        if ~detector.isInstalled(), detector.install(); end;
        detector.disableCaching();
        if ~isempty(detector.DetectorName)
          frames = detector.extractFeatures(imgPath);
          fprintf('%s - extracted %d frames.\n',detector.Name, ...
            size(frames,2));

          if ~isempty(detector.DescriptorName)
            [frames descs] = detector.extractFeatures(imgPath);
            fprintf('%s - extracted %d frames and descriptors.\n',...
              detector.Name, size(frames,2));
          end
        end
        if detector.ExtractsDescriptors
          frames = randomDet.extractFeatures(imgPath);
          [drop descs] = detector.extractDescriptors(imgPath, frames);
          fprintf('%s - extracted %d descriptors from %d frames.\n',...
            detector.Name, size(descs,2),size(frames,2));
        end
      end
    end
  end
end