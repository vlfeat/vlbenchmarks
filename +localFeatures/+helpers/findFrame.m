function [id min_dist] = findFrame(frm, frms)
% FINDFRAME Find the closes frame byt its position
%  [IDX MIN_DIST] = FINDFRAME(FRAME,FRM_SET) Finds the closest frame in set
%    of frames FRM_SET to FRAME considering frame centres L2 norm distances 
%    only and returns its index ID and its distance.
centres =frms(1:2,:);

center_rep = repmat(frm(1:2,1),1,size(centres,2));
E_distance = sqrt(sum((centres-center_rep).^2));

[min_dist id] = min(E_distance);

end
