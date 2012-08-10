function sel = isEllipseInBBox(bbox, f)
% ELLCLIP

if isempty(f)
  sel = false;
  return;
end

rx = sqrt(f(3,:)) ;
ry = sqrt(f(5,:)) ;

sel = bbox(1) <= f(1,:) - rx & ...
      bbox(2) <= f(2,:) - ry & ...
      bbox(3) >= f(1,:) + rx & ...
      bbox(4) >= f(2,:) + ry ;
