function vggEll = ellToVgg(ell,eigVal,eigVec)
% ELLTOVGG Transforms the ellipse into mexComputeEllipseOverlap function
%   VGG_ELL = ELLTOVGG(F, EIG, EIGVEC) Converts ellipse frame F with
%   eigen values EIG and eigen vectors EIGVEC of the frame ellipse 
%   matrix (see `help ellipseEigen`) to KM frame defined as:
%
%     VGG_ELL(1:5,.) = F(1:5,.)
%     VGG_ELL(6:7,.) = sqrt(EIG(:,.)) % Size of the ellipse axes
%     VGG_ELL(8:9,.) Size of the ellipse bounding box (allinged to image 
%                    coordinates) half-axis.

% Authors: Andrea Vedaldi, Karel Lenc

% AUTORIGHTS

vggEll = zeros(5+4,size(ell,2));

if isempty(ell)
  return;
end

vggEll(1:2,:) = ell(1:2,:);
v1byLambda1 = bsxfun(@rdivide,eigVec(1:2,:),eps+eigVal(1,:));
v2byLambda2 = bsxfun(@rdivide,eigVec(3:4,:),eps+eigVal(2,:));

A1 = sum([v1byLambda1(1,:);v2byLambda2(1,:)].*[eigVec(1,:);eigVec(3,:)],1);
A2 = sum([v1byLambda1(2,:);v2byLambda2(2,:)].*[eigVec(1,:);eigVec(3,:)],1);
A4 = sum([v1byLambda1(2,:);v2byLambda2(2,:)].*[eigVec(2,:);eigVec(4,:)],1);

vggEll(3,:) = A1;
vggEll(4,:) = A2;
vggEll(5,:) = A4;

vggEll(6,:) = sqrt(eigVal(2,:));
vggEll(7,:) = sqrt(eigVal(1,:));

% TODO wrong bbox, see repeatability 219
vggEll([8 9],:) = sqrt(ell([3 5],:));
