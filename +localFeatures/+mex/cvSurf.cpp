#include <mex.h>
#include <opencv2/core/core.hpp>
#include <opencv2/features2d/features2d.hpp>
#include <opencv2/nonfree/nonfree.hpp>
#include <stdio.h>
#include <vector>

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

  int                verbose = 0 ;
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

  std::vector<float> descriptors;
  std::vector<KeyPoint> frames;

  if (nin < IN_END) {
    vlmxError (vlmxErrNotEnoughInputArguments, 0) ;
  } else if (nout > OUT_END) {
    vlmxError (vlmxErrTooManyOutputArguments, 0) ;
  }


  if (mxGetNumberOfDimensions (in[IN_I]) != 2              ||
      mxGetClassID            (in[IN_I]) != mxUINT8_CLASS  ) {
    vlmxError(vlmxErrInvalidArgument, "I must be a matrix of class UINT8") ;
  }

  unsigned char* data = (unsigned char*) mxGetData (in[IN_I]) ;
  int M    = mxGetM (in[IN_I]) ;
  int N    = mxGetN (in[IN_I]) ;

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
        double const *mx_frms_ptr;
        if (!vlmxIsMatrix(optarg, -1, -1)) {
          mexErrMsgTxt("'Frames' must be a matrix.") ;
        }

        int nifrms = mxGetN  (optarg) ;
        int mifrms = mxGetM  (optarg) ;
        mx_frms_ptr = mxGetPr (optarg) ;
        switch (mifrms) {
        case 3: {
          for (int i = 0; i < nifrms; ++i) {
            int ifrms_i = mifrms * i;
            frames.push_back(KeyPoint());
            KeyPoint& frame = frames.back();
            frame.pt.x = mx_frms_ptr[ifrms_i + 1] - 1.;
            frame.pt.y = mx_frms_ptr[ifrms_i + 0] - 1.;
            frame.size = mx_frms_ptr[ifrms_i + 2];
          }
        } break;
        case 4: {
          for (int i = 0; i < nifrms; ++i) {
            int ifrms_i = mifrms * i;
            frames.push_back(KeyPoint());
            KeyPoint& frame = frames.back();
            frame.pt.x = mx_frms_ptr[ifrms_i + 1] - 1.;
            frame.pt.y = mx_frms_ptr[ifrms_i + 0] - 1.;
            frame.size = mx_frms_ptr[ifrms_i + 2];
            frame.angle = (CV_PI / 2. - mx_frms_ptr[ifrms_i + 3])/CV_PI*180.;
          }
        } break;
        default:
          mexErrMsgTxt("CvSurf does not support this type of frames.") ;
          break;
        }
      } break ;

    default :
      abort() ;
    }
  }

  int frmNumel = upright ? 3 : 4;

  if (verbose) {
    mexPrintf("cvsurf: filter settings:\n") ;
    mexPrintf("cvsurf:   numOctaves           = %d\n",nOctaves);
    mexPrintf("cvsurf:   numOctaveLayers      = %d\n",nOctaveLayers);
    mexPrintf("cvsurf:   hessianThreshold     = %f\n",hessianThreshold);
    mexPrintf("cvsurf:   extended             = %s\n",extended?"yes":"no");
    mexPrintf("cvsurf:   upright              = %s\n",upright ?"yes":"no");
  }

  Mat image = Mat(N,M,CV_8UC1,data);

  bool calcDescs = false;
  int descNumel;
  if (nout >= OUT_DESCRIPTORS)
    calcDescs = true;

  SURF surf = SURF(hessianThreshold, nOctaves, nOctaveLayers, extended);
  if (calcDescs) {
    bool hasInputFrames = frames.size() > 0;
    surf(image, Mat(), frames, descriptors, hasInputFrames);
    descNumel = surf.descriptorSize();
  } else {
    surf(image, Mat(), frames);
  }

  /* make enough room for all the keypoints */
  double *mx_frames = (double*)mxMalloc(frmNumel * sizeof(double) * frames.size()) ;
  void *mx_descrs;
  if (calcDescs) {
    if (! floatDescriptors) {
      mx_descrs  = mxMalloc(sizeof(vl_uint8) * descriptors.size()) ;
    } else {
      mx_descrs  = mxMalloc(sizeof(float) * descriptors.size()) ;
    }
  }

  /* For each keypoint ........................................ */
  for (int i = 0; i < frames.size() ; ++i) {

    /* TODO solve the descriptor transpose (is SURF same as SIFT?) */

    /* Save back with MATLAB conventions. Notice that the input
       * image was the transpose of the actual image. */

    const KeyPoint& frame = frames[i];
    int frm_i = i * frmNumel;
    int desc_i = i * descNumel;

    switch (frmNumel) {
    case 3: { /* DISC */
      mx_frames [frm_i + 0] = frame.pt.y + 1. ;
      mx_frames [frm_i + 1] = frame.pt.x + 1. ;
      mx_frames [frm_i + 2] = frame.size ;
    } break;
    case 4: { /* ORIENTED DISC */
      mx_frames [frm_i + 0] = frame.pt.y + 1. ;
      mx_frames [frm_i + 1] = frame.pt.x + 1. ;
      mx_frames [frm_i + 2] = frame.size ;
      mx_frames [frm_i + 3] = CV_PI / 2. - frame.angle / 180. * CV_PI;
    } break;
    default:
      VL_ASSERT(0,"Invalid frame type.");
      break;
    }

    if (calcDescs) {
      if (! floatDescriptors) {
        for (int j = 0 ; j < descNumel ; ++j) {
          float x = (descriptors[desc_i + j] + 0.5F) * 255.0F;
          x = (x < 255.0F) ? x : 255.0F ;
          ((vl_uint8*)mx_descrs) [desc_i + j] = (vl_uint8) x ;
        }
      } else {
        for (int j = 0 ; j < descNumel ; ++j) {
          float x = descriptors[desc_i + j];
          ((float*)mx_descrs) [desc_i + j] = x ;
        }
      }
    }
  } /* next keypoint */

  {
    mwSize dims [2] ;

    /* create an empty array */
    dims [0] = 0 ;
    dims [1] = 0 ;
    out[OUT_FRAMES] = mxCreateNumericArray
                      (2, dims, mxDOUBLE_CLASS, mxREAL) ;

    /* set array content to be the frames buffer */
    dims [0] = frmNumel ;
    dims [1] = frames.size() ;
    mxSetPr         (out[OUT_FRAMES], mx_frames) ;
    mxSetDimensions (out[OUT_FRAMES], dims, 2) ;

    if (calcDescs) {
      /* create an empty array */
      dims [0] = 0 ;
      dims [1] = 0 ;
      out[OUT_DESCRIPTORS]= mxCreateNumericArray
                            (2, dims,
                             floatDescriptors ? mxSINGLE_CLASS : mxUINT8_CLASS,
                             mxREAL) ;

      /* set array content to be the descriptors buffer */
      dims [0] = descNumel ;
      dims [1] = frames.size() ;
      mxSetData       (out[OUT_DESCRIPTORS], mx_descrs) ;
      mxSetDimensions (out[OUT_DESCRIPTORS], dims, 2) ;
    }
  }

}
