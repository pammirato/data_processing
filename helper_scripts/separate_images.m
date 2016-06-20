clearvars;

method =  'blurry'; %how to separate the images. Options:
                    %'blurry' - motion blur
                    %'boring' - similar color (blank walls)
                    %'pick out' - just move every nth image

boring_threshold = 50; %1080*1920*.15;
not_blurry_threshold = 120;
pick_out_every = 13;

debug = 0;

base_path = '/playpen/ammirato/Data/RohitMetaData/Bedroom11/';
%base_path = '/playpen/ammirato/Data/RohitData/Kitchen_Living_12/';

if(strcmp(method, 'blurry'))
  load_path = fullfile(base_path, 'hand_scan/rgb');
  move_path = fullfile(base_path, 'hand_scan/blurry_rgb');
elseif(strcmp(method, 'boring'))
  load_path = fullfile(base_path, 'rgb_for_reconstruction');
  move_path = fullfile(base_path, 'boring_rgb');
elseif(strcmp(method, 'pick out'))
  load_path = fullfile(base_path, 'rgb_for_reconstruction');
  move_path = fullfile(base_path, 'picked_out_rgb');
end


rgb_image_names = dir(fullfile(load_path, '*.png'));
%rgb_image_names = dir(fullfile(base_path,'rgb', '*.png'));
rgb_image_names = {rgb_image_names.name};


count = 0;
for il = 1:length(rgb_image_names)
  cur_image_name = rgb_image_names{il};

  if(~strcmp(method, 'pick out'))
    rgb_img = imread(fullfile(load_path, cur_image_name));
    %rgb_img = imread(fullfile(load_path, 'rgb', cur_image_name));
  end

  if(strcmp(method,'blurry'))

    metric = get_single_metric_for_image(rgb_img, 'blurry');


    if(metric < not_blurry_threshold)
      %image is blurry
      movefile(fullfile(load_path, cur_image_name),...
                fullfile(move_path, cur_image_name));
    end

  elseif(strcmp(method, 'boring'))
    metric = get_single_metric_for_image(rgb_img, 'boring');

    if(metric < boring_threshold)
      movefile(fullfile(load_path, cur_image_name), ...
                fullfile(move_path, cur_image_name));  
    end


  elseif(strcmp(method, 'pick out'))
    if(mod(il,pick_out_every) == 0)
      movefile(fullfile(load_path, cur_image_name), ...
                fullfile(move_path, cur_image_name));  
    end   
  end%if method

  %g_img =single(rgb2gray(rgb_img)); 
  %std_val = std(g_img(:));



  if(debug)

    if(1 < 50)
      imshow(rgb_img);
      hold on;
      title(num2str(metric));
      ginput(1);
    end
 end 
end%for il, each iamge name



