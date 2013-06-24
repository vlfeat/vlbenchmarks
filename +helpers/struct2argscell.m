function res = struct2argscell(s)
% Authors: Karel Lenc

% AUTORIGHTS

res = [fieldnames(s)';struct2cell(s)'];
res = res(:)';
end