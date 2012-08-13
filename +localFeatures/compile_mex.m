function compile_mex()

cwd=fileparts(mfilename('fullpath'));

mexCmds=cell(0,1);

mexCmds{end+1}=sprintf('mex -O %s+helpers/mexComputeEllipseOverlap.cpp -outdir %s+helpers/',cwd,cwd);

for i=1:length(mexCmds)
  fprintf('Executing %s\n',mexCmds{i});
  eval(mexCmds{i});
end
