function [repScores numOfCorresp] = runKristianEval(frames,imagePaths,images,tfs)
import affineDetectors.*;

% Index of a value from the test results corresponding to idx*10 overlap
% error
overlap_err_idx = 4;

curDir = pwd;
krisDir = helpers.getKristianDir();
if(~exist(krisDir,'dir'))
  error('Kristian''s benchmark not found, cannot run\n');
end

repScores = zeros(1,numel(frames)); repScores(1) = 100;
numOfCorresp = zeros(1,numel(frames));

addpath('./');
for i = 2:numel(frames)
  [framesA,framesB,framesA_,framesB_] = ...
      helpers.cropFramesToOverlapRegion(frames{1},frames{i},tfs{i},images{1},images{i});
  tmpFile = tempname;
  ellAFile = [tempname 'ellA.txt'];
  ellBFile = [tempname 'ellB.txt'];
  tmpHFile = [tempname 'H.txt'];
  helpers.vggwriteell(ellAFile,framesA);
  helpers.vggwriteell(ellBFile,framesB);

  H = tfs{i};
  save(tmpHFile,'H','-ASCII');
  fprintf('Running Kristians''s benchmark on Img#%02d/%02d\n',i,numel(frames));
  cd(krisDir);
  [err,tmpRepScore, tmpNumOfCorresp] = repeatability(ellAFile,ellBFile,tmpHFile,imagePaths{1},imagePaths{i},1);
  repScores(1,i) = tmpRepScore(overlap_err_idx);
  numOfCorresp(1,i) = tmpNumOfCorresp(overlap_err_idx);
  cd(curDir);
  delete(ellAFile);
  delete(ellBFile);
  delete(tmpHFile);
end
rmpath('./');

function scores = runKristianEval_old(frames,imagePaths,images,tfs)
import affineDetectors.*;

curDir = pwd;
krisDir = helpers.getKristianDir();
if(~exist(krisDir,'dir'))
  error('Kristian''s benchmark not found, cannot run\n');
end

repScores = zeros(1,numel(frames));repScores(1,1) = 1;
numOfCorresp = zeros(1,numel(frames));numOfCorresp(1,1) = 1;
matchScores = zeros(1,numel(frames));matchScores(1,1) = 1;
numOfMatches = zeros(1,numel(frames));numOfMatches(1,1) = 1;

addpath('./');
for i = 2:numel(frames)
  %[framesA,framesB,framesA_,framesB_] = ...
  %    helpers.cropFramesToOverlapRegion(frames{1},frames{i},tfs{i},images{1},images{i});
  tmpFile = tempname;
  ellAFile = [tempname 'ellA.txt'];
  ellBFile = [tempname 'ellB.txt'];
  tmpHFile = [tempname 'H.txt'];
  %helpers.vggwriteell(ellAFile,framesA);
  %helpers.vggwriteell(ellBFile,framesB);
  helpers.vggwriteell(ellAFile,helpers.frameToEllipse(frames{1}));
  helpers.vggwriteell(ellBFile,helpers.frameToEllipse(frames{i}));

  H = tfs{i};
  save(tmpHFile,'H','-ASCII');
  fprintf('Running Kristians''s benchmark on Img#%02d/%02d\n',i,numel(frames));
  cd(krisDir);
  [err,tmpScore] = repeatability(ellAFile,ellBFile,tmpHFile,...
                                    imagePaths{1},imagePaths{i},1);
  repScores(1,i) = tmpScore(4)/100;
  cd(curDir);
  delete(ellAFile);
  delete(ellBFile);
  delete(tmpHFile);
end
rmpath('./');
