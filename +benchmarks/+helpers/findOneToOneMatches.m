function bestMatches = findOneToOneMatches(ev,numFramesA,numFramesB,overlapError)
      corresp = zeros(3,0);
      overlapThresh = 1 - overlapError;
      bestMatches = zeros(3, numFramesA) ;
      
      for j=1:numFramesA
        numNeighs = length(ev.scores{j}) ;
        if numNeighs > 0
          corresp = [corresp, ...
                    [j *ones(1,numNeighs) ; ev.neighs{j} ; ...
                     ev.scores{j}] ] ;
        end
      end

      corresp = corresp(:,corresp(3,:)>overlapThresh);

      % eliminate assigment by priority, i.e. sort the corresp by the score
      % sort by the ellipse overlaps for repeatability
      [drop, perm] = sort(corresp(3,:), 'descend');
      corresp = corresp(:, perm);
      % Create maps which frames has not been 'used' yet
      availA = true(1,numFramesA);
      availB = true(1,numFramesB);

      for idx = 1:size(corresp,2)
        aIdx = corresp(1,idx);
        bIdx = corresp(2,idx);
        if(availA(aIdx) && availB(bIdx))
          bestMatches(1,aIdx) = bIdx;
          bestMatches(2,aIdx) = corresp(3,idx); % Overlap
          availA(aIdx) = false;
          availB(bIdx) = false;
        end
      end
    end