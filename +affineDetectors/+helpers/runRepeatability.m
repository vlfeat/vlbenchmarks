function [repScore numOfCorresp matchScore numMatches] = runRepeatability(framesA, framesB, descrsA, descrsB, tf, imagePathA, imagePathB, commonPart,overlapError)
  import affineDetectors.*;
  import affineDetectors.helpers.*;
  krisDir = helpers.getKristianDir();
  tmpFile = tempname;
  ellBFile = [tmpFile 'ellB.txt'];
  tmpHFile = [tmpFile 'H.txt'];
  ellAFile = [tmpFile 'ellA.txt'];
  helpers.vggwriteell(ellAFile,frameToEllipse(framesA), descrsA);
  helpers.vggwriteell(ellBFile,frameToEllipse(framesB), descrsB);
  H = tf;
  save(tmpHFile,'H','-ASCII');
  overlap_err_idx = round(overlapError*10);

  addpath(krisDir);
  rehash;
  [err,tmpRepScore, tmpNumOfCorresp, matchScore, numMatches] ...
      = repeatability(ellAFile,ellBFile,tmpHFile,imagePathA,imagePathB,commonPart);
  rmpath(krisDir);

  repScore = tmpRepScore(overlap_err_idx);
  numOfCorresp = tmpNumOfCorresp(overlap_err_idx);
  delete(ellAFile);
  delete(ellBFile);
  delete(tmpHFile);
end
