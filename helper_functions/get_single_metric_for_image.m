function [metric] = get_single_metric_for_image(rgb_image, metric_name)
% attempts to quantify some image quality with a single number
%
%
%  metric_name is the desired qualtiy. Supported:
%
%  'blurry' - how blurry the image is (motion blur)
%  'boring' - how boring the image is, i.e a blank wall is boring, a bunch of objects is not

  metric = NaN;
  gray_img = rgb2gray(rgb_image);


  if(strcmp(metric_name, 'blurry'))

    %http://stackoverflow.com/questions/7765810/is-there-a-way-to-detect-if-an-image-is-blurry
    kernel = [0 1 0; 1 -4 1; 0 1 0];
    filtered_img = imfilter(double(gray_img), kernel);
    metric = var(single(filtered_img(:)));

  elseif(strcmp(metric_name, 'boring'))

    %how much variance there is in color of the pixels
    gray_img = double(gray_img); 
    std_val = std(gray_img(:));
    metric = std_val;
  end
end%function
