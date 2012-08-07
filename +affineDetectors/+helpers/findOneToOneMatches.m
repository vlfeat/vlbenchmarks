function [bestMatches,matchIdxs,scores] = findOneToOneMatches(ev,framesA,framesB,overlapError)
      matches = zeros(3,0);
      overlapThresh = 1 - overlapError;
      bestMatches = zeros(1, size(framesA, 2)) ;
      scores = zeros(1, size(framesA, 2)) ;
      matchIdxs = [];

      for j=1:size(framesA,2)
        numNeighs = length(ev.scores{j}) ;
        if numNeighs > 0
          matches = [matches, ...
                    [j *ones(1,numNeighs) ; ev.neighs{j} ; ev.scores{j} ] ] ;
        end
      end

      matches = matches(:,matches(3,:)>overlapThresh);

      % eliminate assigment by priority, i.e. sort the matches by the score
      [drop, perm] = sort(matches(3,:), 'descend');
      matches = matches(:, perm);
      % Create maps which frames has not been 'used' yet
      availA = true(1,size(framesA,2));
      availB = true(1,size(framesB,2));

      for idx = 1:size(matches,2)
        aIdx = matches(1,idx);
        bIdx = matches(2,idx);
        if(availA(aIdx) && availB(bIdx))
          bestMatches(aIdx) = bIdx;
          scores(aIdx) = matches(3,idx);
          matchIdxs = [matchIdxs bIdx];
          availA(aIdx) = false;
          availB(bIdx) = false;
        end
      end
    end