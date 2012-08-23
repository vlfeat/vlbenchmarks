#ifndef _MATLABIO_H__
#define _MATLABIO_H__

#include <mex.h>
#include <opencv2/core/core.hpp>
#include <opencv2/features2d/features2d.hpp>

extern "C" {
#include <toolbox/mexutils.h>
}

/**
 * @brief importImage8UC1 Import OpenCV CV_8UC1 image from Matlab array
 * Image is not transposed and data are not copied.
 * @param mArray Pointer to Matlab array
 * @return OpenCV Mat wrapper around the Matlab data.
 */
cv::Mat importImage8UC1(mxArray const *mArray)
{
  if (mxGetNumberOfDimensions (mArray) != 2              ||
      mxGetClassID            (mArray) != mxUINT8_CLASS  ) {
    vlmxError(vlmxErrInvalidArgument,
              "I must be a 2-dimensional matrix of class UINT8") ;
  }

  unsigned char* data = (unsigned char*) mxGetData (mArray) ;
  int M    = mxGetM (mArray) ;
  int N    = mxGetN (mArray) ;

  cv::Mat image = cv::Mat(N,M,CV_8UC1,data);
  return image;
}

/**
 * @brief importFrames Import frames from Matlab
 * This function is intended for OpenCV therefore supports only Discs and
 * oriented discs. Conversion of other frames is not supported.
 * @param frames Reference to vector of frames (sink)
 * @param mArray Pointer to Matlab array (source)
 */
void importFrames(std::vector<cv::KeyPoint>& frames, mxArray const *mArray)
{
  double const *mx_frms_ptr;
  if (!vlmxIsMatrix(mArray, -1, -1)) {
    mexErrMsgTxt("'Frames' must be a matrix.") ;
  }

  int nifrms = mxGetN  (mArray) ;
  int mifrms = mxGetM  (mArray) ;
  mx_frms_ptr = mxGetPr (mArray) ;
  switch (mifrms) {
  case 3: {
    for (int i = 0; i < nifrms; ++i) {
      int ifrms_i = mifrms * i;
      frames.push_back(cv::KeyPoint());
      cv::KeyPoint& frame = frames.back();
      frame.pt.x = mx_frms_ptr[ifrms_i + 1] - 1.;
      frame.pt.y = mx_frms_ptr[ifrms_i + 0] - 1.;
      frame.size = mx_frms_ptr[ifrms_i + 2];
    }
  } break;
  case 4: {
    for (int i = 0; i < nifrms; ++i) {
      int ifrms_i = mifrms * i;
      frames.push_back(cv::KeyPoint());
      cv::KeyPoint& frame = frames.back();
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
}


/**
 * @brief exportFrames Export OpenCV frames (KeyPoints) to Matlab array
 * Function automatically creates needed data storage. Becouse the
 * cv::KeyPoint does not handle affinities, only Discs and oriented Discs
 * are supported. Type of exported frames is set by ::frmNumEl parameter.
 * @param out Pointer to Matlab output array
 * @param frames Reference to std::vector of the exported frames
 * @param frmNumEl Number of frame elements (3 - Disc, 4 - Oriented Disc).
 */
void exportFrames(mxArray **out, const std::vector<cv::KeyPoint>& frames,
                  const int frmNumEl)
{
  /* make enough room for all the keypoints */
  double *mx_frames = (double*)mxMalloc(frmNumEl * sizeof(double) * frames.size()) ;

  /* For each keypoint ........................................ */
  for (int i = 0; i < frames.size() ; ++i) {

    /* TODO solve the descriptor transpose (is SURF same as SIFT?) */

    /* Save back with MATLAB conventions. Notice that the input
       * image was the transpose of the actual image. */

    const cv::KeyPoint& frame = frames[i];
    int frm_i = i * frmNumEl;

    switch (frmNumEl) {
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

  } /* next frame */

  mwSize dims [2] ;

  /* create an empty array */
  dims [0] = 0 ;
  dims [1] = 0 ;
  *out = mxCreateNumericArray (2, dims, mxDOUBLE_CLASS, mxREAL) ;

  /* set array content to be the frames buffer */
  dims [0] = frmNumEl ;
  dims [1] = frames.size() ;
  mxSetPr (*out, mx_frames) ;
  mxSetDimensions (*out, dims, 2) ;

  return;
}


/**
 * @brief exportDescs Export descriptors to Matlab
 * When ::floatDescriptors is false and minValue < maxValue then the values
 * from interval [minValue,maxValue] are normalsied into interval [1,2...255].
 * @param out Pointer to out Matlab Array
 * @param descriptors Reference to a float vector with all descriptor values
 * @param descNumEl Number of elements per descriptor
 * @param numDescs Number of descriptors
 * @param floatDescriptors Export descriptors as float and do not normalise.
 * @param minValue Minimum value of the normalised interval
 * @param maxValue Max. value of the normalised interval.
 */

template <class TP>
void exportDescs(mxArray **out, const TP* descriptors,
                 const int descNumEl, const int numDescs,
                 const bool floatOutput = false,
                 TP minValue = 1, TP maxValue = 0)
{
  void *mx_descrs;

  if (! floatOutput) {
    mx_descrs  = mxMalloc(sizeof(vl_uint8) * descNumEl * numDescs) ;
  } else {
    mx_descrs  = mxMalloc(sizeof(float) * descNumEl * numDescs) ;
  }

  for (int i = 0; i < numDescs; ++i) {
    int desc_i = i * descNumEl;

    if (! floatOutput) {
      for (int j = 0 ; j < descNumEl ; ++j) {
        /* Normalise the descriptors values to range [0...255] */
        TP x = (descriptors[desc_i + j]);
        /* Do not do anything with the data in case the descriptor is binary */
        if (minValue < maxValue) {
          x = (x - minValue) / (maxValue - minValue) * 255.0F;
          x = (x < 255.0F) ? x : 255.0F ;
        }
        ((vl_uint8*)mx_descrs) [desc_i + j] = (vl_uint8) x ;
      }
    } else {
      for (int j = 0 ; j < descNumEl ; ++j) {
        TP x = descriptors[desc_i + j];
        ((float*)mx_descrs) [desc_i + j] = (float)x ;
      }
    }
  }

  mwSize dims [2];

  /* create an empty array */
  dims [0] = 0 ;
  dims [1] = 0 ;
  *out = mxCreateNumericArray(2, dims,
                            floatOutput ? mxSINGLE_CLASS : mxUINT8_CLASS,
                            mxREAL) ;

  /* set array content to be the descriptors buffer */
  dims [0] = descNumEl ;
  dims [1] = numDescs ;
  mxSetData (*out, mx_descrs) ;
  mxSetDimensions (*out, dims, 2) ;

  return;
}

#endif // __UTLS_MARY_H__
