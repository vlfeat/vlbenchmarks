function result = fastEllipseOverlap(f1, f2, varargin)
% FASTELLIPSEOVERLAP Compute overlaps of two sets ov ellipses
%   EVAL = FASTELLIPSEOVERLAP(F1, F2) computes the overlap scores
%   beteen all pairs of ellipses in F1 and F2.  EVAL output structure
%   of size(F2,2) contains following values:
%
%    EVAL.NEIGH::
%      The list of neighbours in F1 for each ellipse in F1.
%
%    EVAL.SCORES::
%      The correpsonding overlaps.
%
%   When frame scale normalisation is not applied the function is
%   symmetric. With rescaling, the frames of F2 are used to fix the
%   scaling factors.
%
%   MATCHELLIPSES(F1, F2, 'OptionName', OptionValue) accepts the
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

%  Author:: Andrea Vedaldi, Karel Lenc

% AUTORIGHTS

  import benchmarks.*;

  conf.normaliseFrames = true ;
  conf.normalisedScale = 30 ;
  conf.minAreaRatio = 0.3;
  conf = helpers.vl_argparse(conf, varargin) ;

  % eigenvalues (radii squared)
  [e1,eigVec1] = helpers.ellipseEigen(f1) ;
  [e2,eigVec2] = helpers.ellipseEigen(f2) ;

  vggEll1 = helpers.ellToVgg(f1,e1,eigVec1);
  vggEll2 = helpers.ellToVgg(f2,e2,eigVec2);

  % areas
  a1 = pi * sqrt(prod(e1,1)) ;
  a2 = pi * sqrt(prod(e2,1)) ;

  N2 = size(f2,2) ;
  neighs = cell(1,N2) ;
  scores = cell(1,N2) ;

  if isempty(f1) || isempty(f2)
    result.neighs = neighs ;
    result.scores = scores ;
    return;
  end

  for i2 = 1:N2
    s = conf.normalisedScale / sqrt(a2(i2) / pi)  ;

    canOverlap = sqrt(vl_alldist2(f2(1:2, i2), f1(1:2,:))) < 4 * sqrt(a2(i2) / pi);
    % a2(i2) - area of tested ellipse
    % a1 - areas of all ellipses
    % min(a2(i2) a1) - vector
    maxOverlap = min(a2(i2), a1) ./ max(a2(i2), a1) .* canOverlap ;
    neighs{i2} = find(maxOverlap > conf.minAreaRatio) ;

    if conf.normaliseFrames
      vggS = [1 1 1/s^2 1/s^2 1/s^2 s s s s]';
      lhsEllipse = vggS.*vggEll2(:,i2);
      rhsEllipse = bsxfun(@times,vggEll1(:,neighs{i2}),vggS);
    else
      lhsEllipse = vggEll2(:,i2);
      rhsEllipse = vggEll1(:,neighs{i2});
    end
    scores{i2} = helpers.computeEllipseOverlap(lhsEllipse,rhsEllipse)';
  end

  result.neighs = neighs ;
  result.scores = scores ;

end