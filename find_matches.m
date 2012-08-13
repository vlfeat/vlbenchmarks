function [ frames1Matches frames2Matches ] = find_matches( frames1, frames2, overlapError )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% TODO do it more optimally, there is I think no need to compute it twice..

import localFeatures.*;

res2to1 = matchEllipses(frames1, frames2, 'NormaliseFrames', false);
[frames2Matches.matches,matchIdxs2to1,frames2Matches.scores] = helpers.findOneToOneMatches(res2to1,frames2,frames1,overlapError);


res1to2 = matchEllipses(frames2, frames1, 'NormaliseFrames', false);
[frames1Matches.matches,matchIdxs1to2,frames1Matches.scores] = helpers.findOneToOneMatches(res1to2,frames1,frames2,overlapError);

end

