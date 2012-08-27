function [ bestCorresp ] = find_matches( framesA, framesB, overlapError )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% TODO do it more optimally, there is I think no need to compute it twice..

import benchmarks.helpers.*;

frameCorresp = matchEllipses(framesB, framesA, 'NormaliseFrames', false);

% Find the best one-to-one correspondences
numFramesA = size(framesA,2);
numFramesB = size(framesB,2);
corresp = zeros(3,0);
overlapThresh = 1 - overlapError;
bestCorresp = zeros(2, numFramesA) ;

% Collect all correspondences in a single array
for j=1:numFramesA
  numNeighs = length(frameCorresp.scores{j});
  if numNeighs > 0
    corresp = [corresp, ...
              [j *ones(1,numNeighs); frameCorresp.neighs{j}; ...
              frameCorresp.scores{j}]];
  end
end

% Filter corresp. with insufficient overlap
corresp = corresp(:,corresp(3,:)>overlapThresh);

% eliminate assigment by priority, i.e. sort the corresp by the score
[drop, perm] = sort(corresp(3,:), 'descend');
corresp = corresp(:, perm);

% Find on-to-one best correspondences
bestCorresp(1,:) = greedyBipartiteMatching(numFramesA, numFramesB, ...
  corresp(1:2,:)');
  

end

