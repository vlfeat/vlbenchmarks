#include <mex.h>
#include <opencv2/core/core.hpp>
#include <opencv2/features2d/features2d.hpp>
#include <opencv2/nonfree/nonfree.hpp>
#include <stdio.h>
#include <vector>

#include "matlabio.h"

extern "C" {
#include <toolbox/mexutils.h>
}

using namespace std;
using namespace cv;

/* option codes */
enum {
  opt_threshold = 0,
  opt_nonmax_suppression,
  opt_verbose
} ;

/* options */
vlmxOption  options [] = {
  {"ContrastThreshold", 1,   opt_threshold },
  {"FloatDescriptors",  1,   opt_nonmax_suppression },
  {"Verbose",           1,   opt_verbose           },
  {0,                   0,   0                     }
} ;

void
mexFunction(int nout, mxArray *out[],
            int nin, const mxArray *in[])
{
  enum {IN_I = 0, IN_END} ;
  enum {OUT_FRAMES=0, OUT_END} ;

  int                verbose = 0 ;
  int                opt ;
  int                next = IN_END ;
  mxArray const     *optarg ;

  /* Default options */
  double threshold = 70;
  bool nonmaxSuppression = true;

  std::vector<KeyPoint> frames;

  if (nin < IN_END) {
    vlmxError (vlmxErrNotEnoughInputArguments, 0) ;
  } else if (nout > OUT_END) {
    vlmxError (vlmxErrTooManyOutputArguments, 0) ;
  }

  /* Import the image */
  Mat image = importImage8UC1(in[IN_I]);

  while ((opt = vlmxNextOption (in, nin, options, &next, &optarg)) >= 0) {
    switch (opt) {

    case opt_verbose :
      verbose = (bool) *mxGetPr(optarg) ;
      break ;

    case opt_threshold :
      if (!vlmxIsPlainScalar(optarg) || (threshold = *mxGetPr(optarg)) < 0) {
        mexErrMsgTxt("'HessianThreshold' must be a non-negative real.") ;
      }
      break ;

    case opt_nonmax_suppression :
      nonmaxSuppression = (bool) *mxGetPr(optarg) ;
      break ;

    default :
      abort() ;
    }
  }

  int frmNumel = 3;

  if (verbose) {
    mexPrintf("cvfast: filter settings:\n") ;
    mexPrintf("cvfast:   threshold            = %f\n",threshold);
    mexPrintf("cvfast:   nonmax suppression     = %s\n",nonmaxSuppression?"yes":"no");
  }

  FAST(image, frames, threshold, nonmaxSuppression);

  if (verbose) {
    mexPrintf("cvfast: detected %d frames\n",frames.size());
  }

  /* Export  computed data */
  exportFrames(&out[OUT_FRAMES], frames, frmNumel);

}
