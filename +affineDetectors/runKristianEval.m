function scores = runKristianEval_old(frames,imagePaths,images,tfs)
import affineDetectors.*;

curDir = pwd;
krisDir = helpers.getKristianDir();
if(~exist(krisDir,'dir'))
  error('Kristian''s benchmark not found, cannot run\n');
end

%addpath(krisDir);
scores = zeros(1,numel(frames));scores(1,1) = 1;

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
  scores(1,i) = tmpScore(4)/100;
  cd(curDir);
  delete(ellAFile);
  delete(ellBFile);
  delete(tmpHFile);
end

%rmpath(krisDir);

function scores = runKristianEval(frames,imagePaths,images,tfs)
import affineDetectors.*;

curDir = pwd;
krisDir = helpers.getKristianDir();
if(~exist(krisDir,'dir'))
  error('Kristian''s benchmark not found, cannot run\n');
end

%addpath(krisDir);
scores = zeros(1,numel(frames));scores(1,1) = 1;

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
  [err,tmpScore] = repeatability(ellAFile,ellBFile,tmpHFile,...
                                    imagePaths{1},imagePaths{i},1);
  scores(1,i) = tmpScore(4)/100;
  cd(curDir);
  delete(ellAFile);
  delete(ellBFile);
  delete(tmpHFile);
end


%rmpath(krisDir);
