function [ img ] = genEllipses( )
%GENELLIPSES Generate testing image with various multivariant Gauss. blobs

w = 800;
h = 800;

img = zeros(h,w) ;

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
  end
end

end

