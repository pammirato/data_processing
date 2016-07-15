% Demo's the in-painting function fill_depth_cross_bf.m

imgRgb = imread('~/Data/RohitData/Bedroom_01_1/rgb/0000030101.png');
%imgDepthAbs = imread('~/Data/RohitData/Bedroom_01_1/raw_depth/0000030102.png');
imgDepthAbs = imread('~/Data/RohitData/Bedroom_01_1/high_res_depth/0000030103.png');


% Crop the images to include the areas where we have depth information.
%imgRgb = crop_image(imgRgb);
%imgDepthAbs = crop_image(imgDepthAbs);

%imgDepthFilled = fill_depth_cross_bf(imgRgb, double(imgDepthAbs));



imgDepthFilled = fill_depth_colorization(double(imgRgb), double(imgDepthAbs), 1);

figure;
subplot(1,3,1); imagesc(imgRgb);
subplot(1,3,2); imagesc(imgDepthAbs);
subplot(1,3,3); imagesc(imgDepthFilled);
