ell_pth = '/home/kaja/projects/c/vlfeat_benchmarks/data/datasets/vggDataset/graf/'

ell_file1 = [ell_pth 'img1.ppm.hesaff.sift'];
ell_file2 = [ell_pth 'img2.ppm.hesaff.sift'];
h_file = [ell_pth, 'H1to2p'];

img_file1 = [ell_pth 'img1.ppm'];
img_file2 = [ell_pth 'img2.ppm'];

curDir = pwd;

krisDir = localFeatures.helpers.getKristianDir();
  cd(krisDir);
  [err,tmpRepScore, tmpNumOfCorresp, matchScore, numMatches] ...
      = repeatability(ell_file1,ell_file2,h_file,img_file1,img_file2,0);
  cd(curDir);