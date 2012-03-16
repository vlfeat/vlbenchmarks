function vggwriteell(fileName, ell)
% VGGWRITEELL

for i=1:size(ell,2)
  S = [ell(3,i) ell(4,i) ; ell(4,i) ell(5,i)] ;
  A = inv(S) ;
  ell(3:5,i) = A([1 2 4]) ;
end

f = fopen(fileName, 'w') ;
fprintf(f,'0\n%d\n', size(ell,2)) ;
fprintf(f,'%g %g %g %g %g\n', ell) ;
fclose(f) ;

