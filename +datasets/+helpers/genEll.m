function [ img ] = genEll( )
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here


w = 800;
h = 800;

%img = uint8(ones(h,w)*255);
img = zeros(h,w) ;

%f = figure(100);
%imshow(img);

nx = 5;
ny = 5;
sc = min([w/6/nx h/6/ny]);

bndr = 5;
xs = linspace(bndr*sc,w-bndr*sc,nx);
ys = linspace(bndr*sc,h-bndr*sc,ny);
dvds = linspace(1,1/3,ny);
[x,y]=meshgrid(1:w,1:h) ;

for i=1:ny
  for j=1:nx
    dx = (x - xs(j)) / (sc*dvds(i)) ;
    dy = (y - ys(i)) / (sc*dvds(i)*dvds(j)) ;
    d2 = dx.*dx + dy.*dy ;
    img = img + exp(-0.5*d2) ;
    %plotEll(xs(j),ys(i),sc*dvds(i),sc*dvds(j)*dvds(i),'k');
  end
end

function plotEll(x,y,a,b,c)
r=0:0.1:2*pi+0.1;
p=[(a*cos(r))' (b*sin(r))'];
patch(x+p(:,1),y+p(:,2),c,'EdgeColor',c);
end

%frm = getframe(f);
%img = rgb2gray(frm.cdata);

end

