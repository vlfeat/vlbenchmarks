setup

img = genPersp();
%img = genEll();

figure(1);
imshow(img);
%img = vl_imsmooth(single(img),2.5);
img = uint8(img.*255);

[frms1 descs gss resp1] = vl_covdet(single(img),'Method','hessian','Orientation',false,'AffineAdaptation',true, 'Magnif',1,'EdgeThresh',10000,'PeakThresh',100,'AffMaxIter',10,'AffConvThr',0.1,'AffWinSize',19);
%[frms2 descs gss resp2] = vl_covdet(single(img),'Method','dog','Orientation',false,'AffineAdaptation',true, 'Magnif',1);
%vl_plotframe(frms);

vggDet = affineDetectors.vggNewAffine('detector','hessian','thresh',5000);
frms3 = vggDet.detectPoints(img);

%cmpDet = affineDetectors.cmpHessian();
%frms4 = cmpDet.detectPoints(img);

frames1 = frms1;
frames2 = frms3;
det1Name = 'vlf';
det2Name = 'vgg';

[ frames1Matches frames2Matches ] = find_matches(frames1,frames2,0.8);

draw_matches( img, frames1, frames2, frames1Matches, frames2Matches,... 
  det1Name, det2Name,...
   'persp');

figure(3); clf;
vl_plotss(resp1);

clear mex;
