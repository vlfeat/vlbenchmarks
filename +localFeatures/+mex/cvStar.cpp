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
  opt_max_size = 0,
  opt_response_threshold,
  opt_line_threshold_projected,
  opt_line_threshold_binarized,
  opt_suppress_nonmax_size,
  opt_verbose
} ;

/* options */
vlmxOption  options [] = {
  {"MaxSize",                 1,   opt_max_size },
  {"ResponseThreshold",       1,   opt_response_threshold },
  {"LineThresholdProjected",  1,   opt_line_threshold_projected },
  {"LineThresholdBinarized",  1,   opt_line_threshold_binarized },
  {"SuppressNonmaxSize",      1,   opt_suppress_nonmax_size},
  {"Verbose",                 1,   opt_verbose           },
  {0,                         0,   0                     }
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
  int maxSize = 16;
  int responseThreshold = 30;
  int lineThresholdProjected = 10;
  int lineThresholdBinarized = 8;
  int suppressNonmaxSize = 5;

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

    case opt_max_size :
      if (!vlmxIsPlainScalar(optarg) || (maxSize = (int)*mxGetPr(optarg)) < 0) {
        mexErrMsgTxt("'MaxSize' must be a non-negative integer.") ;
      }
      break ;

    case opt_response_threshold :
      if (!vlmxIsPlainScalar(optarg) || (maxSize = (int)*mxGetPr(optarg)) < 0) {
        mexErrMsgTxt("'MaxSize' must be a non-negative integer.") ;
      }
      break ;

    case opt_line_threshold_projected :
      if (!vlmxIsPlainScalar(optarg) || (lineThresholdProjected = (int)*mxGetPr(optarg)) < 0) {
        mexErrMsgTxt("'LineThresholdProjected' must be a non-negative integer.") ;
      }
      break ;

    case opt_line_threshold_binarized :
      if (!vlmxIsPlainScalar(optarg) || (lineThresholdBinarized = (int)*mxGetPr(optarg)) < 0) {
        mexErrMsgTxt("'LineThresholdBinarizes' must be a non-negative integer.") ;
      }
      break ;

    case opt_suppress_nonmax_size :
      if (!vlmxIsPlainScalar(optarg) || (suppressNonmaxSize = (int)*mxGetPr(optarg)) <= 0) {
        mexErrMsgTxt("'SuppressNonmaxSize' must be a positive integer.") ;
      }
      break ;

    default :
      abort() ;
    }
  }

  int frmNumel = 3;

  if (verbose) {
    mexPrintf("cvstar: filter settings:\n") ;
    mexPrintf("cvstar:   max size             = %d\n",maxSize);
    mexPrintf("cvstar:   response threshold   = %d\n",responseThreshold);
    mexPrintf("cvstar:   line threshold proj. = %d\n",lineThresholdProjected);
    mexPrintf("cvstar:   line threshold bin.  = %d\n",lineThresholdBinarized);
    mexPrintf("cvstar:   nonmax supp. size    = %d\n",suppressNonmaxSize);
  }

  StarFeatureDetector det(maxSize, responseThreshold, lineThresholdProjected,
                          lineThresholdBinarized, suppressNonmaxSize);
  det.detect(image, frames);

  if (verbose) {
    mexPrintf("cvstar: detected %d frames\n",frames.size());
  }

  /* Export  computed data */
  exportFrames(&out[OUT_FRAMES], frames, frmNumel);

}
