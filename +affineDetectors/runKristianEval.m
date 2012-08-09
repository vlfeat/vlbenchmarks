function [repScores numOfCorresp matchScores numOfMatches] = runKristianEval(frames,imagePaths,images,tfs, overlapError, descrs)
  import affineDetectors.*;
  import affineDetectors.helpers.*;

  % Index of a value from the test results corresponding to idx*10 overlap
  % error. Kristian eval. computes only overlap errors in step of 0.1
  overlap_err_idx = round(overlapError*10);
  if (overlapError*10 - overlap_err_idx) ~= 0
      warning(['KM benchmark supports only limited set of overlap errors. ',...
               'The comparison would not be accurate.']);
  end

  curDir = pwd;
  krisDir = helpers.getKristianDir();
  if(~exist(krisDir,'dir'))
    error('Kristian''s benchmark not found, cannot run\n');
  end

  repScores = zeros(1,numel(frames)); repScores(1) = 100;
  numOfCorresp = zeros(1,numel(frames));
  matchScores = zeros(1,numel(frames)); matchScores(1) = 100;
  numOfMatches = zeros(1,numel(frames));

  addpath('./');
  for i = 2:numel(frames)
    tmpFile = tempname;
    ellAFile = [tempname 'ellA.txt'];
    ellBFile = [tempname 'ellB.txt'];
    tmpHFile = [tempname 'H.txt'];
    if nargout == 2
      %[framesA,framesB,framesA_,framesB_] = ...
      %  helpers.cropFramesToOverlapRegion(frames{1},frames{i},tfs{i},images{1},images{i});
      helpers.vggwriteell(ellAFile,framesA);
      helpers.vggwriteell(ellBFile,framesB);
      common_part = 1;
    elseif nargout == 4
      % [framesA,framesB,framesA_,framesB_, descrsA, descrsB] = ...
      %  helpers.cropFramesToOverlapRegion(frames{1},frames{i},tfs{i},images{1},images{i}, ...
      %                                    descrs{1}, descrs{i});
      helpers.vggwriteell(ellAFile,frameToEllipse(frames{1}), descrs{1});
      helpers.vggwriteell(ellBFile,frameToEllipse(frames{i}), descrs{i});
      common_part = 0;
    end

    H = tfs{i};
    save(tmpHFile,'H','-ASCII');

    fprintf('Running Kristians''s benchmark on Img#%02d/%02d\n',i,numel(frames));
    cd(krisDir);
    [err,tmpRepScore, tmpNumOfCorresp, matchScore, numMatches] ...
        = repeatability(ellAFile,ellBFile,tmpHFile,imagePaths{1},imagePaths{i},common_part);
    cd(curDir);

    repScores(1,i) = tmpRepScore(overlap_err_idx);
    numOfCorresp(1,i) = tmpNumOfCorresp(overlap_err_idx);
    matchScores(1,i) = matchScore;
    numOfMatches(1,i) = numMatches;
    delete(ellAFile);
    delete(ellBFile);
    delete(tmpHFile);
  end
  rmpath('./');
end
