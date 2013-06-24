function cname = callerName(idx)

if nargin == 0
  idx = 0;
end

[ST I] = dbstack;
callerIdx = (I - idx + 1);
if callerIdx <= numel(ST)
  cname = ST(callerIdx).name;
else
  cname = 'matlab_root_win';
end

end