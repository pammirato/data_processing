function [metric] = get_single_metric_for_image(rgb_image, metric_name)


  metric = NaN;
  gray_img = rgb2gray(rgb_image);


  if(strcmp(metric_name, 'blurry'))

    kernel = [0 1 0; 1 -4 1; 0 1 0];
    %kernel = fspecial('log');
    filtered_img = imfilter(double(gray_img), kernel);
    metric = var(single(filtered_img(:)));
    %metric = sort(filtered_img(:));
    %metric = mean(metric(end:-1:end-1000));

  elseif(strcmp(metric_name, 'boring'))

    gray_img = double(gray_img); 
    %mean_val = mean(gray_img(:));
    std_val = std(gray_img(:));

    %mean_diffs = abs(gray_img - mean_val);

    %is_interesting =  mean_diffs > std_val;

    %metric = length(find(is_interesting)); 

    metric = std_val;
  end



end%main function
