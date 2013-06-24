classdef DescMatchingTest < tests.GenericTest
  %RepeatabilityTest
  
  properties
    Opts = struct(...
      'prMaxErrorDist', 0.01, ...
      'datasetCategory', 'graf', ...
      'datasetImgNum',4, ...
      'drawResults', true ...
      );
  end
  
  methods
    function obj = DescMatchingTest(varargin)
      varargin = obj.configureGenericTest('DescMatchingTest',varargin{:});
      obj.Opts = vl_argparse(obj.Opts, varargin);
    end
    
    function testAll(obj)
      import localFeatures.*;
      import datasets.*;
      descDet = VggDescriptor('CropFrames',true,'Magnification',3);
      detector = DescriptorAdapter(VggAffine('Detector','haraff','Threshold',1000), descDet);
      dataset = VggAffineDataset('category', obj.Opts.datasetCategory);
      
      matchStrategies = {'nn','nn-dist-ratio','threshold'};
      
      for msi = 1:numel(matchStrategies)
        obj.testPRCurve(detector, dataset, matchStrategies{msi}, ...
          obj.Opts.datasetImgNum);
      end
      
    end
    
    function testPRCurve(obj, detector, dataset, matchStrategy, imageNum)
      % detectorPerformance Test detector repeatability based in geometry
      import benchmarks.*;
      
      bench = DescMatchingBenchmark(...
        consistencyModels.HomographyConsistencyModel(...
          'overlapError', 0.5,...
          'cropFrames', false,...
          'normaliseFrames', false,...
          'warpMethod', 'linearise',...
          'magnification',3), ...
        'matchingStrategy',matchStrategy);
      bench.disableCaching();
      bench_orig = PamiDescBenchmark('matchingStrategy',matchStrategy);
      
      [expPrecision expRecall] = bench_orig.testFeatureExtractor(detector, ...
        dataset.getSceneGeometry(imageNum), ...
        dataset.getImagePath(1), ...
        dataset.getImagePath(imageNum));

      [actPrecision actRecall] = bench.testFeatureExtractor(detector, ...
        dataset.getSceneGeometry(imageNum), ...
        dataset.getImagePath(1), ...
        dataset.getImagePath(imageNum));

      if obj.Opts.drawResults
        figure(1);clf; hold on;
        plot(1-expPrecision,expRecall,'-ro','LineWidth',1);
        plot(1-actPrecision,actRecall,'b','LineWidth',1);
        waitforbuttonpress;
      end
      
      err = obj.computePRError(expPrecision, expRecall, actPrecision, actRecall);
      
      obj.assertMaxError(sprintf('Desc PR-Curve - %s - %s', ...
        dataset.DatasetName, matchStrategy), err, obj.Opts.prMaxErrorDist);
    end
  end
  
  methods (Static, Access = private)
    function err = computePRError(expPrecision, expRecall, actPrecision, actRecall)
      actPts = [actPrecision; actRecall];
      expPts = [expPrecision; expRecall];
      
      dists = vl_alldist2(actPts, expPts);
      err = min(dists);
    end
  end
  
end

