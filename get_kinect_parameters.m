function [intrinsic,distortion, rotation, projection] = get_kinect_parameters(k_index)
%returns the intrinsic, distortion, rotation, and projection parameters as matrices for
%the given kinect


%TODO  - double check all numbers
%      - add numbers for K2 and K3


  intrinsic = [];
  distortion = [];
  rotation = [];
  projection = [];


  switch k_index
    case 1
      intrinsic = [ 1.0700016292741097e+03, 0., 9.2726881773877119e+02; ...
                     0.,1.0691225545678490e+03, 5.4576099988165549e+02; 0., 0., 1.];
      distortion = [ 3.5321295653368376e-02, 2.5428166340122748e-03, 2.3872136896159945e-03, ...
                     -2.4103515597419067e-03, -4.0612086782529380e-02 ];
      rotation = [ 1., 0., 0.; 0., 1., 0.; 0., 0., 1. ];
      projection = [ 1.0700016292741097e+03, 0., 9.2726881773877119e+02, 0.; ... 
                     0.,1.0691225545678490e+03, 5.4576099988165549e+02, 0.; ...
                     0., 0., 1., 0.; 0., 0., 0., 1. ];

    case 2
      intrinsic = [  1.0582854982177009e+03, 0., 9.5857576622458146e+0; ...
                 0., 1.0593799583771420e+03, 5.3110874137837084e+02; 0., 0., 1.];

    case 3
      intrinsic = [ 1.0630462958838500e+03, 0., 9.6260473585485727e+02; ...
                    0., 1.0636103172708376e+03, 5.3489949221354482e+02; 0., 0., 1.];



end%function
