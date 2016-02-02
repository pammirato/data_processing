
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

% figure;
% %show the undistorted image
% imgu = undistortImage(imgd,cameraParams1);
% imshow([imgd  imgu]);







undistorted_points  = [];

xs = 1:1920;

for i=694:1080
    disp(num2str(i));
    
    ys = i*ones(1,1920);
    
    temp = undistortPoints([xs;ys]',cameraParams1);
    
    undistorted_points = cat(2,undistorted_points, temp);
    
    
end%for i


all_original_points = [xs; ys]';

















% %undistort the 
% undistorted_points = undistortPoints(all_original_points(1:end/2),:),cameraParams1)';



    
    
    
    