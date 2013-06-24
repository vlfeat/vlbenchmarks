classdef DTURobotTest < tests.GenericTest
  %RepeatabilityTest
  
  properties
    Opts = struct(...
      'repTestNumImages',5,...
      'repSceneNum',3,...
      'descMatchingStrategy', 'threshold',...
      'descImgNum', 5);
  end
  
  methods
    function obj = DTURobotTest(varargin)
      varargin = obj.configureGenericTest('DTURobotTest',varargin{:});
      obj.Opts = vl_argparse(obj.Opts, varargin);
    end
    
    function testAll(obj)
      import localFeatures.*;
      import datasets.*;
      import benchmarks.*;
      
      descDet = VggDescriptor('CropFrames',true,'Magnification',3);
      detector = DescriptorAdapter(VggAffine('Detector','harlap','Threshold',1000), descDet);
      dataset = datasets.DTURobotDataset();
      consistModel  = consistencyModels.DTURobotConsistencyModel();
      
      
      obj.repeatability(RepeatabilityBenchmark(consistModel, 'Mode','Repeatability'),...
        dataset, obj.Opts.repSceneNum, detector);
      obj.repeatability(RepeatabilityBenchmark(consistModel, 'Mode','MatchingScore'),...
        dataset, obj.Opts.repSceneNum, detector);
      obj.descpr(consistModel, dataset, obj.Opts.repSceneNum, detector);
    end
    
    function repeatability(obj, benchm, dataset, sceneNum, detector)
      
      rep = zeros(1, obj.Opts.repTestNumImages);
      ncorr = rep;
      
      refImgToken = dataset.getReferenceImageToken(sceneNum);
      
      for ii = 1:obj.Opts.repTestNumImages
        testImgToken = dataset.getImageToken(sceneNum, ii);
        sceneGeometry = dataset.getSceneGeometry(testImgToken);
        [rep(ii) ncorr(ii)] = benchm.testFeatureExtractor(...
          detector, ...
          sceneGeometry, ...
          dataset.getImagePath(refImgToken),...
          dataset.getImagePath(testImgToken));
      end
      obj.info(sprintf('Computed score: %s',sprintf('%f ',rep)));
      obj.info(sprintf('Computed num valid pairs: %s',sprintf('%f ',ncorr)));
    end
    
        
    function descpr(obj, consistModel, dataset, sceneNum, detector)
      % detectorPerformance Test detector repeatability based in geometry
      import benchmarks.*;
      bench = DescMatchingBenchmark(consistModel,'matchingStrategy',obj.Opts.descMatchingStrategy);
      bench.disableCaching();
      
      refImgToken = dataset.getReferenceImageToken(sceneNum);
      testImgToken = dataset.getImageToken(sceneNum, obj.Opts.descImgNum);
      
      [precision recall] = bench.testFeatureExtractor(detector, ...
        dataset.getSceneGeometry(testImgToken), ...
        dataset.getImagePath(refImgToken), ...
        dataset.getImagePath(testImgToken));
      
      figure(1); clf;
      plot(1 - precision, recall);
    end
  end
  
  methods (Access = private)
  end
  
end

