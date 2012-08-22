% CVSURF Calculate SURF image frames and descriptors using OpenCV SURF [1]
%   F = CVSURF(I) computed SURF frames F of the input image I. When
%   'Upright' is false, F are oriented discs (4 values), otherwise discs 
%   without orientation are returned (3 values).
%             
%   [F,D] = CVSURF(I) computes the SURF descriptors for the
%   detected frames F. Each column of D is the descriptor of the 
%   corresponding frame in F. A descriptor is a 64 or 128-dimensional 
%   vector (when 'Extended',true is specified) of class UINT8 or DOUBLE 
%   when 'FloatDescriptors',true option is specified.
%
%   CVSURF(...,'OptionName',value) accepts the following options:
%
%   NumOctaves:: [4]
%     Set the number of octaves of the scale space.
%
%   NumOctaveLayers:: [2]
%     Set the number of levels per octave of the scale space.
%
%   PeakThreshold:: [1000]
%     Set the peak selection threshold.
%
%   Extended:: [false]
%     Extend the descriptor to 128 values when true.
%
%   Upright:: [false]
%     Calculate upright frames and descriptors (no orientation assignment).
%
%   Frames:: [not specified]
%     If specified, set the frames to use (bypass the detector). The output
%     frames are in the same locations however the angle can be
%     recalculated.
%
%   FloatDescriptors:: [true]
%     If true, descriptors are returned as float numbers.
%
%   Verbose:: [false]
%     If true, be verbose (may be repeated to increase the
%     verbosity level).
%
%   REFERENCES::
%     [1] http://docs.opencv.org/modules/nonfree/doc/feature_detection.html
%
