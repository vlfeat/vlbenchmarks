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
  opt_hessian_threshold = 0,
  opt_num_octaves,
  opt_octave_layers,
  opt_extended,
  opt_upright,
  opt_float_descriptors,
  opt_frames,
  opt_verbose
} ;

/* options */
vlmxOption  options [] = {
  {"HessianThreshold", 1,   opt_hessian_threshold },
  {"NumOctaves",       1,   opt_num_octaves       },
  {"NumOctaveLayers",  1,   opt_octave_layers     },
  {"Extended",         1,   opt_extended          },
  {"Upright",          1,   opt_upright           },
  {"FloatDescriptors", 1,   opt_float_descriptors },
  {"Frames",           1,   opt_frames            },
  {"Verbose",          1,   opt_verbose           },
  {0,                  0,   0                     }
} ;

void
mexFunction(int nout, mxArray *out[],
            int nin, const mxArray *in[])
{
  enum {IN_I = 0, IN_END} ;
  enum {OUT_FRAMES=0, OUT_DESCRIPTORS, OUT_END} ;

  int                opt ;
  int                next = IN_END ;
  mxArray const     *optarg ;

  /* Default options */
  int nOctaves = 4;
  bool extended = false;
  bool upright = false;
  int nOctaveLayers = 2;
  double hessianThreshold = 1000;
  bool floatDescriptors = true;
  bool verbose = false ;

  if (nin < IN_END) {
    vlmxError (vlmxErrNotEnoughInputArguments, 0) ;
  } else if (nout > OUT_END) {
    vlmxError (vlmxErrTooManyOutputArguments, 0) ;
  }

  /* Import the image */
  Mat image = importImage8UC1(in[IN_I]);
  std::vector<float> descriptors;
  std::vector<KeyPoint> frames;

  while ((opt = vlmxNextOption (in, nin, options, &next, &optarg)) >= 0) {
    switch (opt) {

    case opt_verbose :
      verbose = (bool) *mxGetPr(optarg) ;
      break ;

    case opt_hessian_threshold :
      if (!vlmxIsPlainScalar(optarg) || (hessianThreshold = *mxGetPr(optarg)) < 0) {
        mexErrMsgTxt("'HessianThreshold' must be a non-negative real.") ;
      }
      break ;

    case opt_num_octaves :
      if (!vlmxIsPlainScalar(optarg) || (nOctaves = (int) *mxGetPr(optarg)) < 0) {
        mexErrMsgTxt("'NumOctaves' must be a positive integer.") ;
      }
      break ;

    case opt_octave_layers :
      if (! vlmxIsPlainScalar(optarg) || (nOctaveLayers = (int) *mxGetPr(optarg)) < 1) {
        mexErrMsgTxt("'NumOctaveLayers' must be a positive integer.") ;
      }
      break ;

    case opt_extended :
      extended = (bool) *mxGetPr(optarg) ;
      break ;

    case opt_upright :
      upright = (bool) *mxGetPr(optarg) ;
      break ;

    case opt_float_descriptors :
      floatDescriptors = (bool) *mxGetPr(optarg) ;
      break ;

    case opt_frames : {
      /* Import the frames */
      importFrames(frames, optarg);
      } break ;

    default :
      abort() ;
    }
  }

  int frmNumel = upright ? 3 : 4;
  bool calcDescs = (nout > OUT_DESCRIPTORS);
  int descNumel;

  if (verbose) {
    mexPrintf("cvsurf: filter settings:\n") ;
    mexPrintf("cvsurf:   numOctaves           = %d\n",nOctaves);
    mexPrintf("cvsurf:   numOctaveLayers      = %d\n",nOctaveLayers);
    mexPrintf("cvsurf:   hessianThreshold     = %f\n",hessianThreshold);
    mexPrintf("cvsurf:   extended             = %s\n",extended?"yes":"no");
    mexPrintf("cvsurf:   upright              = %s\n",upright ?"yes":"no");
    mexPrintf("cvsurf:   calcDescriptors      = %s\n",calcDescs ?"yes":"no");
    mexPrintf("cvsurf:   floatDescriptors     = %s\n",floatDescriptors?"yes":"no");
    mexPrintf("cvsurf:   source frames        = %d\n",frames.size());
  }

  SURF surf = SURF(hessianThreshold, nOctaves, nOctaveLayers, extended);
  if (calcDescs) {
    bool hasInputFrames = frames.size() > 0;
    surf(image, Mat(), frames, descriptors, hasInputFrames);
    descNumel = surf.descriptorSize();
  } else {
    surf(image, Mat(), frames);
  }

  if (verbose) {
    mexPrintf("cvsurf: detected %d frames\n",frames.size());
  }

  /* Export  computed data */
  exportFrames(&out[OUT_FRAMES], frames, frmNumel);

  if (calcDescs) {
    exportDescs<float>(&out[OUT_DESCRIPTORS], descriptors.data(), descNumel,
                     frames.size(),floatDescriptors, -0.5, 0.5);
  }

}
