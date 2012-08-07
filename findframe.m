function [id min_dist] = findframe(frm, frms)

centres =frms(1:2,:);

center_rep = repmat(frm(1:2,1),1,size(centres,2));
E_distance = sqrt(sum((centres-center_rep).^2));

[min_dist id] = min(E_distance);

end
