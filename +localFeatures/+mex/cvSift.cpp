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
  opt_contrast_threshold = 0,
  opt_edge_threshold,
  opt_octave_layers,
  opt_num_features,
  opt_sigma,
  opt_frames,
  opt_verbose
} ;

/* options */
vlmxOption  options [] = {
  {"ContrastThreshold", 1,   opt_contrast_threshold },
  {"EdgeThreshold",     1,   opt_edge_threshold     },
  {"NumOctaveLayers",   1,   opt_octave_layers      },
  {"NumFeatures",       1,   opt_num_features       },
  {"Sigma",             1,   opt_sigma              },
  {"Frames",            1,   opt_frames             },
  {"Verbose",           1,   opt_verbose            },
  {0,                   0,   0                      }
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
  int nOctaveLayers = 3;
  double contrastThreshold = 0.04;
  double edgeThreshold = 10;
  double sigma = 1.6;
  int numFeatures = 0;
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

  while ((opt = vlmxNextOption (in, nin, options, &next, &optarg)) >= 0) {
    switch (opt) {

    case opt_verbose :
      verbose = (bool) *mxGetPr(optarg) ;
      break ;

    case opt_contrast_threshold :
      if (!vlmxIsPlainScalar(optarg) || (contrastThreshold = *mxGetPr(optarg)) < 0) {
        mexErrMsgTxt("'ContrastThreshold' must be a non-negative real.") ;
      }
      break ;

    case opt_edge_threshold :
      if (!vlmxIsPlainScalar(optarg) || (edgeThreshold = *mxGetPr(optarg)) < 0) {
        mexErrMsgTxt("'EdgeThreshold' must be a non-negative real.") ;
      }
      break ;

    case opt_octave_layers :
      if (! vlmxIsPlainScalar(optarg) || (nOctaveLayers = (int) *mxGetPr(optarg)) < 1) {
        mexErrMsgTxt("'NumOctaveLayers' must be a positive integer.") ;
      }
      break ;

    case opt_num_features :
      if (! vlmxIsPlainScalar(optarg) || (numFeatures = (int) *mxGetPr(optarg)) < 0) {
        mexErrMsgTxt("'NumFeatures' must be a non-negative integer.") ;
      }
      break ;

    case opt_sigma :
      if (! vlmxIsPlainScalar(optarg) || (sigma = *mxGetPr(optarg)) < 1) {
        mexErrMsgTxt("'Sigma' must be a non-negative real.") ;
      }
      break ;

    case opt_frames : {
      /* Import the frames */
      importFrames(frames, optarg);
      } break ;

    default :
      abort() ;
    }
  }

  int frmNumel = 4;
  int descNumel = 128;
  bool calcDescs = (nout > OUT_DESCRIPTORS);

  if (verbose) {
    mexPrintf("cvsift: filter settings:\n") ;
    mexPrintf("cvsift:   numFeatures          = %d\n",numFeatures);
    mexPrintf("cvsift:   numOctaveLayers      = %d\n",nOctaveLayers);
    mexPrintf("cvsift:   contrastThreshold    = %f\n",contrastThreshold);
    mexPrintf("cvsift:   edgeThreshold        = %f\n",edgeThreshold);
    mexPrintf("cvsift:   sigma                = %f\n",sigma);
    mexPrintf("cvsift:   calcDescriptors      = %s\n",calcDescs ?"yes":"no");
    mexPrintf("cvsift:   source frames        = %d\n",frames.size());
  }

  SIFT sift = SIFT(numFeatures, nOctaveLayers, contrastThreshold,
                   edgeThreshold, sigma);
  if (calcDescs) {
    bool hasInputFrames = frames.size() > 0;
    sift(image, Mat(), frames, descriptors, hasInputFrames);
  } else {
    sift(image, Mat(), frames);
  }

  if (verbose) {
    mexPrintf("cvsift: detected %d frames\n",frames.size());
  }

  /* Export  computed data */
  exportFrames(&out[OUT_FRAMES], frames, frmNumel);

  if (calcDescs) {
    exportDescs<float>(&out[OUT_DESCRIPTORS], (float*)descriptors.data,
                        descNumel, frames.size());
  }

}
