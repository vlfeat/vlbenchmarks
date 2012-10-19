#include <mex.h>
#include <opencv2/core/core.hpp>
#include <opencv2/features2d/features2d.hpp>
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
  opt_pattern_scale = 0,
  opt_num_octaves,
  opt_octave_layers,
  opt_orientation_normalized,
  opt_scale_normalized,
  opt_float_descriptors,
  opt_frames,
  opt_verbose
} ;

/* options */
vlmxOption  options [] = {
  {"PatternScale",          1,   opt_pattern_scale          },
  {"NumOctaves",            1,   opt_num_octaves            },
  {"OrientationNormalized", 1,   opt_orientation_normalized },
  {"ScaleNormalized",       1,   opt_scale_normalized       },
  {"FloatDescriptors",      1,   opt_float_descriptors      },
  {"Verbose",               1,   opt_verbose                },
  {0,                       0,   0                          }
} ;

void
mexFunction(int nout, mxArray *out[],
            int nin, const mxArray *in[])
{
  enum {IN_I = 0,IN_FRAMES, IN_END} ;
  enum {OUT_FRAMES=0, OUT_DESCRIPTORS, OUT_END} ;

  int                opt ;
  int                next = IN_END ;
  mxArray const     *optarg ;

  /* Default options */
  int nOctaves = 4;
  bool orientationNorm = true;
  bool scaleNorm = true;
  double patternScale = 22.0;
  bool floatDescriptors = true;
  bool verbose = false ;

  if (nin < IN_END) {
    vlmxError (vlmxErrNotEnoughInputArguments, 0) ;
  } else if (nout > OUT_END) {
    vlmxError (vlmxErrTooManyOutputArguments, 0) ;
  }

  /* Import the image */
  Mat image = importImage8UC1(in[IN_I]);
  Mat descriptors;
  std::vector<KeyPoint> frames;
  importFrames(frames, in[IN_FRAMES]);

  while ((opt = vlmxNextOption (in, nin, options, &next, &optarg)) >= 0) {
    switch (opt) {

    case opt_verbose :
      verbose = (bool) *mxGetPr(optarg) ;
      break ;

    case opt_pattern_scale :
      if (!vlmxIsPlainScalar(optarg) || (patternScale = *mxGetPr(optarg)) < 0) {
        mexErrMsgTxt("'PatternScale' must be a non-negative real.") ;
      }
      break ;

    case opt_num_octaves :
      if (!vlmxIsPlainScalar(optarg) || (nOctaves = (int) *mxGetPr(optarg)) < 0) {
        mexErrMsgTxt("'NumOctaves' must be a positive integer.") ;
      }
      break ;

    case opt_orientation_normalized :
      orientationNorm = (bool) *mxGetPr(optarg) ;
      break ;

    case opt_scale_normalized :
      scaleNorm = (bool) *mxGetPr(optarg) ;
      break ;

    case opt_float_descriptors :
      floatDescriptors = (bool) *mxGetPr(optarg) ;
      break ;

    default :
      abort() ;
    }
  }

  int descNumel;

  if (verbose) {
    mexPrintf("cvfreak: filter settings:\n") ;
    mexPrintf("cvfreak:   numOctaves           = %d\n",nOctaves);
    mexPrintf("cvfreak:   patternScale         = %f\n",patternScale);
    mexPrintf("cvfreak:   orientationNorm      = %s\n",orientationNorm?"yes":"no");
    mexPrintf("cvfreak:   scaleNorm            = %s\n",scaleNorm ?"yes":"no");
    mexPrintf("cvfreak:   floatDescriptors     = %s\n",floatDescriptors?"yes":"no");
    mexPrintf("cvfreak:   source frames        = %d\n",frames.size());
  }

  FREAK freak = FREAK(orientationNorm, scaleNorm, patternScale, nOctaves);
  descNumel = freak.descriptorSize();
  freak.computeImpl(image, frames, descriptors);

  if (verbose) {
    mexPrintf("cvfreak: detected %d frames\n",frames.size());
  }

  /* Export  computed data */
  exportFrames(&out[OUT_FRAMES], frames, 4);

  exportDescs<vl_uint8>(&out[OUT_DESCRIPTORS], (vl_uint8*)descriptors.data,
                        descNumel,frames.size());

}
