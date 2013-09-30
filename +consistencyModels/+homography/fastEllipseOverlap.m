function [ellipsePairs scores] = fastEllipseOverlap(f1, f2, varargin)
% FASTELLIPSEOVERLAP Compute overlaps of two sets ov ellipses
%   EVAL = FASTELLIPSEOVERLAP(F1, F2) computes the overlap scores
%   beteen all pairs of ellipses in F1 and F2.  EVAL output structure
%   of size(F2,2) contains following values:
%
%    EVAL(1:2,:)
%      The list of correspondences between ellipses F1 and F2. 
%      EVAL(1:2,~) = [a;b] means that ellipses F1(:,a) and F2(:,b) has
%      overlap smaller than a threshold.
%
%    EVAL(3,:)
%      The correpsonding overlaps.
%
%   When frame scale normalisation is not applied the function is
%   symmetric. With rescaling, the frames of F2 are used to fix the
%   scaling factors.
%
%   FASTELLIPSEOVERLAP(F1, F2, 'OptionName', OptionValue) accepts the
%   following options:
%
%   NormaliseFrames:: [true]
%     Fix the the frames scale so that each F2 frame has got scale
%     defined by the 'NormalisedScale' option value.
%
%   NormalisedScale:: [30]
%      When frames scale normalisation applied, fixed scale of frames
%      in F2.
%
%   MinAreaRatio:: [0.3]
%      Precise ellipse overlap is calculated only for ellipses E1
%      and E2 which area ratio is bigger than 'minAreaRatio', s.t.:
%
%        area(E1)/area(E2) > minAreaRatio, area(E1) < area(E2)

%  Authors: Andrea Vedaldi, Karel Lenc

% AUTORIGHTS

  import consistencyModels.homography.*;

  conf.normaliseFrames = true ;
  conf.normalisedScale = 30 ;
  conf.minAreaRatio = 0.3;
  conf = helpers.vl_argparse(conf, varargin) ;

  % eigenvalues (radii squared)
  [e1,eigVec1] = ellipseEigen(f1) ;
  [e2,eigVec2] = ellipseEigen(f2) ;

  vggEll1 = ellToVgg(f1,e1,eigVec1);
  vggEll2 = ellToVgg(f2,e2,eigVec2);

  % areas
  a1 = pi * sqrt(prod(e1,1)) ;
  a2 = pi * sqrt(prod(e2,1)) ;

  N2 = size(f2,2) ;
  ellipsePairs = cell(1,N2) ;
  scores = cell(1,N2) ;

  if isempty(f1) || isempty(f2)
    results = [];
    return;
  end

  % Given two ellipses f1, f2, we want to upper bound their overlap
  % (inters over union). We have
  %
  %   overlap(f1,f2) = |inters(f1,f2)| / |union(f1,f2)| <= maxOverlap
  %   maxOverlap = min(|f1|,|f2|) / max(|f1|,|f2|)
  %
  %
  for i2 = 1:N2
    s = conf.normalisedScale / sqrt(a2(i2) / pi)  ;

    % Constant 4 is here because it is the maximal elongation of the
    % ellipse in baumberg iteration generally implemnted
    canOverlap = sqrt(vl_alldist2(f2(1:2, i2), f1(1:2,:))) < 4 * sqrt(a2(i2) / pi);
    maxOverlap = min(a2(i2), a1) ./ max(a2(i2), a1) .* canOverlap ;
    ellipsePairs{i2} = find(maxOverlap > conf.minAreaRatio);
    ellipsePairs{i2} = [repmat(i2,1,numel(ellipsePairs{i2}));ellipsePairs{i2}];

    if isempty(ellipsePairs{i2})
        ellipsePairs{i2} = zeros(2,0);
        scores{i2} = [];
        continue;
    end
    if conf.normaliseFrames
      vggS = [1 1 1/s^2 1/s^2 1/s^2 s s s s]';
      lhsEllipse = vggS.*vggEll2(:,i2);
      rhsEllipse = bsxfun(@times,vggEll1(:,ellipsePairs{i2}(2,:)),vggS);
    else
      lhsEllipse = vggEll2(:,i2);
      rhsEllipse = vggEll1(:,ellipsePairs{i2}(2,:));
    end
    scores{i2} = computeEllipseOverlap(lhsEllipse,rhsEllipse)';
  end
  
  % Convert to a matrix
  ellipsePairs = cell2mat(ellipsePairs);
  scores = cell2mat(scores);

end