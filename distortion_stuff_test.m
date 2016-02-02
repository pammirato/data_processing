
init;



scene_name = 'FB209';
scene_path = fullfile(BASE_PATH,scene_name);


intrinsic1 = [ 1.0700016292741097e+03, 0., 9.2726881773877119e+02; 0.,1.0691225545678490e+03, 5.4576099988165549e+02; 0., 0., 1. ];




%% set up camera info

distortion1 = [ 3.5321295653368376e-02, 2.5428166340122748e-03, 2.3872136896159945e-03, -2.4103515597419067e-03, -4.0612086782529380e-02 ];
rotation1 = [ 1., 0., 0.; 0., 1., 0.; 0., 0., 1. ];
projection1 = [ 1.0700016292741097e+03, 0., 9.2726881773877119e+02, 0.; 0.,1.0691225545678490e+03, 5.4576099988165549e+02, 0.; 0., 0., 1., 0.; 0., 0., 0., 1. ];

%http://docs.opencv.org/modules/calib3d/doc/camera_calibration_and_3d_reconstruction.html
radialDistortion1 = distortion1([1 2]);
tangentialDistorition1  = distortion1([3 4]);

cameraParams1 = cameraParameters('IntrinsicMatrix',intrinsic1, ...
                                 'RadialDistortion', radialDistortion1, ...
                                 'TangentialDistortion', tangentialDistorition1);


                                 
                                 
original_point= [400,400];                             


%% check out image
%read in the original, distorted image     
imgd = imread(fullfile(BASE_PATH,scene_name, RGB_IMAGES_DIR, '0000010101.png'));

figure;
%show the undistorted image
imgu = undistortImage(imgd,cameraParams1);
imshow([imgd  imgu]);



%undistort the 
undistorted_point = undistortPoints(original_point,cameraParams1)';



   





























k1 = distortion1(1);
k2 = distortion1(2);
k3 = distortion1(5);
p1 = distortion1(3);
p2 = distortion1(4);

fx = intrinsic1(1,1);
fy = intrinsic1(2,2);
cx = intrinsic1(1,3);
cy = intrinsic1(2,3);




%% opencv stuff
%points from corrected image
u = undistorted_point(1);
v = undistorted_point(2);

r1 = sqrt( (u-cx)^2 + (v-cy)^2);


x = (u - cx)/fx;
y = (v - cy)/fy;

r = sqrt(x^2 + y^2);

R = eye(3);
xyw = pinv(R) * [x;y;1];

x_ = xyw(1)/xyw(3);
y_ = xyw(2)/xyw(3);

x__ = x_ *(1 + k1*(r^2) + k2*(r^4)) + 2*p1*x_*y_ + p2*(r^2 + 2*(x_^2));
y__ = y_ *(1 + k1*(r^2) + k2*(r^4)) + p1*(r^2 + 2*(y_^2)) + 2*p2*x_*y_;

ox  = floor(x__*fx + cx);
oy  = floor(y__*fy + cy);

distorted_point = [ox, oy];







    
    
    
    
  %% internet stuff
    
  
x = undistorted_point(1);
y = undistorted_point(2);


x = (x - cx)/fx;
y = (y - cy)/fy;



r2 = x*x + y*y;
%radial distorsion
xCorrected = x * (1 + k1 * r2 + k2 * r2 * r2 );% + k3 * r2 * r2 * r2);
yCorrected = y * (1 + k1 * r2 + k2 * r2 * r2);% + k3 * r2 * r2 * r2);

xCorrected = xCorrected + (2. * p1 * x * y + p2 * (r2 + 2. * x * x));
yCorrected = yCorrected + (p1 * (r2 + 2. * y * y) + 2. * p2 * x * y);

xCorrected = xCorrected * fx + cx;
yCorrected = yCorrected * fy + cy;
  
distorted_point2 = [xCorrected, yCorrected];
%     
%     {
%   dst.clear();
%   double fx = cameraMatrix.at<double>(0,0);
%   double fy = cameraMatrix.at<double>(1,1);
%   double ux = cameraMatrix.at<double>(0,2);
%   double uy = cameraMatrix.at<double>(1,2);
% 
%   double k1 = distorsionMatrix.at<double>(0, 0);
%   double k2 = distorsionMatrix.at<double>(0, 1);
%   double p1 = distorsionMatrix.at<double>(0, 2);
%   double p2 = distorsionMatrix.at<double>(0, 3);
%   double k3 = distorsionMatrix.at<double>(0, 4);
%   //BOOST_FOREACH(const cv::Point2d &p, src)
%   for (unsigned int i = 0; i < src.size(); i++)
%   {
%     const cv::Point2d &p = src[i];
%     double x = p.x;
%     double y = p.y;
%     double xCorrected, yCorrected;
%     //Step 1 : correct distorsion
%     {     
%       double r2 = x*x + y*y;
%       //radial distorsion
%       xCorrected = x * (1. + k1 * r2 + k2 * r2 * r2 + k3 * r2 * r2 * r2);
%       yCorrected = y * (1. + k1 * r2 + k2 * r2 * r2 + k3 * r2 * r2 * r2);
% 
%       //tangential distorsion
%       //The "Learning OpenCV" book is wrong here !!!
%       //False equations from the "Learning OpenCv" book
%       //xCorrected = xCorrected + (2. * p1 * y + p2 * (r2 + 2. * x * x)); 
%       //yCorrected = yCorrected + (p1 * (r2 + 2. * y * y) + 2. * p2 * x);
%       //Correct formulae found at : http://www.vision.caltech.edu/bouguetj/calib_doc/htmls/parameters.html
%       xCorrected = xCorrected + (2. * p1 * x * y + p2 * (r2 + 2. * x * x));
%       yCorrected = yCorrected + (p1 * (r2 + 2. * y * y) + 2. * p2 * x * y);
%     }
%     //Step 2 : ideal coordinates => actual coordinates
%     {
%       xCorrected = xCorrected * fx + ux;
%       yCorrected = yCorrected * fy + uy;
%     }
%     dst.push_back(cv::Point2d(xCorrected, yCorrected));
%     
    
    
    
    
    