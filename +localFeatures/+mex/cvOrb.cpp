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
  opt_scale_factor = 0,
  opt_edge_threshold,
  opt_num_levels,
  opt_num_features,
  opt_wtak,
  opt_patch_size,
  opt_score_type,
  opt_frames,
  opt_verbose
} ;

/* options */
vlmxOption  options [] = {
  {"ScaleFactor",       1,   opt_scale_factor       },
  {"EdgeThreshold",     1,   opt_edge_threshold     },
  {"NumLevels",         1,   opt_num_levels         },
  {"NumFeatures",       1,   opt_num_features       },
  {"WTAK",              1,   opt_wtak               },
  {"PatchSize",         1,   opt_patch_size         },
  {"ScoreType",         1,   opt_score_type         },
  {"Frames",            1,   opt_frames             },
  {"Verbose",           1,   opt_verbose            },
  {0,                   0,   0                      }
} ;
/* FirstLevel is not a part of this implementation because in OpenCV
 * 2.4.2 it was not implemented
 * ("firstLevel – It should be 0 in the current implementation.")
 */

enum ScoreType {
  INVALID = 0,
  HARRIS_SCORE,
  FAST_SCORE
};

/**
 * @brief scoreTypeToORBPar Convert ScoreType enum to ORB parameter.
 * See (OpenCV_2.4.2) features2d/features2d.hpp:276.
 * @param st Score type
 * @return Integer for the cv::ORB constructor scoreType par.
 */
int scoreTypeToORBPar(ScoreType st)
{
  return (int)st - 1;
}

vlStringEnumMap scoreTypesMap [3] = {
  {"harris",            (int)HARRIS_SCORE     },
  {"fast" ,             (int)FAST_SCORE       },
  {0,                   0                     }
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
  int numFeatures = 1000;
  double scaleFactor = 1.2;
  int numLevels = 8;
  double edgeThreshold = 31;
  int wtak = 2;
  ScoreType scoreType = HARRIS_SCORE;
  int patchSize = 31;
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

    case opt_num_features :
      if (! vlmxIsPlainScalar(optarg) || (numFeatures = (int) *mxGetPr(optarg)) < 0) {
        mexErrMsgTxt("'NumFeatures' must be a non-negative integer.") ;
      }
      break ;

    case opt_scale_factor :
      if (!vlmxIsPlainScalar(optarg) || (scaleFactor = *mxGetPr(optarg)) <= 1.) {
        mexErrMsgTxt("'ScaleFactor' must be bigger than 1.") ;
      }
      break ;

    case opt_edge_threshold :
      if (!vlmxIsPlainScalar(optarg) || (edgeThreshold = *mxGetPr(optarg)) < 0) {
        mexErrMsgTxt("'EdgeThreshold' must be a non-negative real.") ;
      }
      break ;

    case opt_num_levels :
      if (! vlmxIsPlainScalar(optarg) || (numLevels = (int) *mxGetPr(optarg)) < 1) {
        mexErrMsgTxt("'NumLevels' must be a positive integer.") ;
      }
      break ;

    case opt_wtak :
      if (! vlmxIsPlainScalar(optarg) || (wtak = (int) *mxGetPr(optarg)) < 2
          || wtak > 4) {
        mexErrMsgTxt("'WTAK' must be in {2,3,4}.") ;
      }
      break ;

    case opt_score_type :
      scoreType = (ScoreType)vlmxGetEnum(optarg, scoreTypesMap);
      if (scoreType == 0) {
        mexErrMsgTxt("'ScoreType' must be 'FAST' or 'HARRIS'.") ;
      }
      break ;

    case opt_patch_size :
      if (! vlmxIsPlainScalar(optarg) || (patchSize = (int) *mxGetPr(optarg)) < 1) {
        mexErrMsgTxt("'PatchSize' must be a positive integer.") ;
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
  int descNumel = 0;
  bool calcDescs = (nout > OUT_DESCRIPTORS);

  if (verbose) {
    mexPrintf("cvorb: filter settings:\n") ;
    mexPrintf("cvorb:   numFeatures          = %d\n",numFeatures);
    mexPrintf("cvorb:   numLevels            = %d\n",numLevels);
    mexPrintf("cvorb:   edgeThreshold        = %f\n",edgeThreshold);
    mexPrintf("cvorb:   wtak                 = %d\n",wtak);
    mexPrintf("cvorb:   score type           = %s\n",
              scoreTypesMap[(int)scoreType - 1].name);
    mexPrintf("cvorb:   patchSize            = %d\n",patchSize);
    mexPrintf("cvorb:   calcDescriptors      = %s\n",calcDescs ?"yes":"no");
    mexPrintf("cvorb:   source frames        = %d\n",frames.size());
  }

  ORB orb(numFeatures, scaleFactor, numLevels, edgeThreshold, 0,
          wtak, scoreTypeToORBPar(scoreType), patchSize);
  if (calcDescs) {
    bool hasInputFrames = frames.size() > 0;
    orb(image, Mat(), frames, descriptors, hasInputFrames);
    descNumel = orb.descriptorSize();
  } else {
    orb(image, Mat(), frames);
  }

  if (verbose) {
    mexPrintf("cvorb: detected %d frames\n",frames.size());
  }

  /* Export  computed data */
  exportFrames(&out[OUT_FRAMES], frames, frmNumel);

  if (calcDescs) {
    exportDescs<vl_uint8>(&out[OUT_DESCRIPTORS],
                          (vl_uint8*)descriptors.data,
                          descNumel, frames.size());
  }

}
