%an attempt to sythesize training images with bigBird objects placed into
% random backgrounds


init_bigBIRD;


%TODO - add   rotation
%             alpha composition
%             illumination
%

allow_inter_object_occlusion = 1;
max_occ_tries = 5;

%max_camera roll angle
max_camera_roll = 360;

%illumination change parameters
min_illum_radius = 200000;
max_illum_radius = 500000;
min_illum_intensity = .1;
max_illum_intensity = 1;





debug = 0;

d = dir(BIGBIRD_BASE_PATH);
object_names = {d(3:end).name};

back_base_path = '/playpen/ammirato/Data/BigBirdCompositeData/';


back_img_path = fullfile(back_base_path,'background_images');%holds background images
label_meta_output_path = fullfile(back_base_path,'composite_metadata');
back_composite_path = fullfile(back_base_path,'composite_images');
background_image_names = dir(back_img_path);
background_image_names = {background_image_names(3:end).name};



kernels = cell(1,16);
for il=1:sqrt(length(kernels))
  for jl=1:sqrt(length(kernels))
    kernels{(il-1)*sqrt(length(kernels)) + jl} = fspecial('gaussian',il,jl);
  end
end

ses = cell(1,13);
for il=1:length(ses)
  ses{il} = strel('ball',il, il);
end

illum_patterns = cell(1,200);
object_img = zeros(1024,1280,3);
for il=1:length(illum_patterns)
  disp(il)
  centerX = floor(1 + (1280-1)*rand());
  centerY = floor(1 + (1024-1)*rand());
  radius =  floor(min_illum_radius + (max_illum_radius-min_illum_radius)*rand());

  %create the pattern and make it have 3 channels
  illum_pattern = create_illumination_pattern(object_img,centerX, centerY, ...
                                         min_illum_intensity, max_illum_intensity, radius); 

  illum_patterns{il} = repmat(illum_pattern, 1,1,3);
end




%load mapping from bigbird name ot category id
obj_cat_map = containers.Map();
fid_bb_map = fopen('/playpen/ammirato/Data/RohitMetaMetaData/big_bird_cat_map.txt', 'rt');

line = fgetl(fid_bb_map);
while(ischar(line))
  line = strsplit(line);
  obj_cat_map(line{1}) = str2double(line{2}); 
  line = fgetl(fid_bb_map);
end
fclose(fid_bb_map);



bbox_pose_labels = zeros(length(background_image_names),8);
meta_data = zeros(length(background_image_names), 25);




object_inds = [];


for il=1:length(background_image_names)

  fprintf('%d of %d\n', il, length(background_image_names));

  cur_back_image_name = background_image_names{il};

  ext_ind = strfind(cur_back_image_name, '.');
  cur_composite_base_name = cur_back_image_name(1:ext_ind-1);
  cur_label_filename = strcat(cur_composite_base_name, '.txt');
  cur_meta_filename = strcat(cur_composite_base_name, '_meta.txt');
  fid_label = fopen(fullfile(label_meta_output_path, cur_label_filename), 'wt');
  fid_meta = fopen(fullfile(label_meta_output_path, cur_meta_filename), 'wt');


  back_img = imread(fullfile(back_img_path, cur_back_image_name));
 
  %skip grayscale background images
  if(size(back_img,3) == 1) 
    continue;
  end 

  back_size = size(back_img);



  %select some random bigbird objects
  if(isempty(object_inds))
    object_inds = randperm(length(object_names));
  end

  %remove big bird objects we dont want to use
  

  %pick how many objects to put in this image
  num_inds_to_use = randi(min(3,length(object_inds)), 1,1);
  inds_to_use = object_inds(1:num_inds_to_use);
 
  %remove the objects to be used from consideration for future images 
  object_inds(1:num_inds_to_use) = []; 

  %get the names of objects to put in the current background image
  cur_bird_names = object_names(inds_to_use);


  %hold the bounding box for each object
  cur_bboxes = zeros(length(cur_bird_names), 4); 



  %for each object chosen, put in the image with random parameters
  for jl=1:length(cur_bird_names)
    cur_bb_name = cur_bird_names{jl};

    %chose a random view of the object, and calulate its pose from image name
    img_to_use = randi(360, 1,1);%360 = images from first 3 cameras 
    cam_ind = floor(img_to_use/121) + 1;
    pose_ind = img_to_use - (120*(cam_ind-1));
    pose_angle = mod((pose_ind-1)*3, 360);


    %load the chosen image
    object_img = imread(fullfile(BIGBIRD_BASE_PATH, cur_bb_name, 'rgb', ...
                            strcat('NP',num2str(cam_ind), '_', num2str(pose_angle), '.jpg')));

    %load the object mask for the chosen image
    object_mask = imread(fullfile(BIGBIRD_BASE_PATH, cur_bb_name, 'masks', ...
                        strcat('NP',num2str(cam_ind), '_', num2str(pose_angle), '_mask.pbm')));


    %object_img = imresize(object_img, [size(back_img,1), size(back_img,2)]);
    %object_mask = imresize(object_mask, [size(object_img,1), size(object_img,2)]);


    


    %% center object in image, and then rotate to simulate camera roll
   
    %find the indices of the mask and the bounding box
    [I, J] = find(object_mask(:,:) == 0);
    min_row = min(I);
    min_col = min(J);
    max_row = max(I);
    max_col = max(J);

    %center the object in the image and mask
    center_row = floor(min_row + (max_row-min_row)/2);
    center_col = floor(min_col + (max_col-min_col)/2); 
    row_shift = floor(size(object_img,1)/2 - center_row);
    col_shift = floor(size(object_img,2)/2 - center_col);
    object_img = circshift(object_img,row_shift,1);
    object_img = circshift(object_img,col_shift,2);
    object_mask = circshift(object_mask,row_shift,1);
    object_mask = circshift(object_mask,col_shift,2);

    %rotate the image to simulate camera roll
    roll_angle = 360*rand();
    object_img = imrotate(object_img, roll_angle, 'crop');
    object_mask  = imrotate(~object_mask, roll_angle, 'crop');
    object_mask = ~object_mask;





    %% change illumination
  
    %pick a random point for the center of the pattern, and a radius size
    %centerX = floor(1 + (size(object_img,2)-1)*rand());
    %centerY = floor(1 + (size(object_img,1)-1)*rand());
    %radius =  floor(min_illum_radius + (max_illum_radius-min_illum_radius)*rand());
  
    %%create the pattern and make it have 3 channels
    %illum_pattern = create_illumination_pattern(object_img,centerX, centerY, ...
    %                                        min_illum_intensity, max_illum_intensity, radius); 

    %illum_pattern = repmat(illum_pattern, 1,1,3);
    illum_ind = randi(length(illum_patterns));
    illum_pattern = imresize(illum_patterns{illum_ind},[size(object_img,1), size(object_img,2)]);

    %apply the pattern to the image
    object_img = uint8(double(object_img) .* illum_pattern);

    %imwrite(illum_pattern, fullfile(back_base_path, 'illum_patterns', strcat(cur_composite_base_name, '.jpg'))); 

    %% blur object image
    %kernel_size = randi(3,1,1);
    %kernel = fspecial('gaussian',kernel_size, kernel_size);
    kernel_ind = randi(length(kernels));
    object_img = imfilter(object_img,kernels{kernel_ind});

    %% erode the mask a bit, because it may have some background in it
    %find the indices of the mask and the bounding box
    [I, J] = find(object_mask(:,:) == 0);
    min_row = min(I);
    min_col = min(J);
    max_row = max(I);
    max_col = max(J);
    min_dim = min(max_row - min_row, max_col-min_col);
    if(min_dim < 100)
      erode_size = randi(6,1,1);
    else
      erode_size = randi(8,1,1) +5;
    end
    %se = strel('line',11,90);
    
    %se = strel('ball',erode_size, erode_size)
    object_mask = imerode(255*uint8(~object_mask),ses{erode_size}); 
    object_mask = ~object_mask;

    %make the mask 3 channels
    object_mask = repmat(object_mask, 1,1,3);
    object_mask_img = uint8(object_mask);
    object_mask_inv = uint8(~object_mask);

    %resize the background image
    new_back_img = imresize(back_img, [size(object_img,1), size(object_img,2)]);
    %new_back_img = back_img;
     
   
    %apply the mask to the image of the object
    masked_object_img = object_img .* object_mask_inv;      


    %% scale the object
    %resize the entire image, then crop around the middle(because the object is in the middle),
    %back to the original image size
    original_size = size(object_mask_img);
    bbox_height = max_row - min_row;
    bbox_width = max_col - min_col;
    max_dim = max(bbox_height, bbox_width);
    %make sure object is between .1 and .5 the length of the image
    min_scale = .05*max(size(object_img)) / max_dim;
    max_scale = .3*max(size(object_img)) / max_dim;
    scale = min_scale + (max_scale-min_scale)*rand(1,1);
    %scale = rand(1,1)*1.5 + .3;

    %get the resized images
    object_mask_img = imresize(object_mask_img, scale);
    masked_object_img = imresize(masked_object_img, scale);


    %get how many rows/cols to crop
    extra_rows = abs(size(object_mask_img,1) - original_size(1));
    extra_cols = abs(size(object_mask_img,2) - original_size(2));


    if(scale > 1 && extra_rows > 1 && extra_cols > 1)
      %if the object got bigger, crop extra rows/cols from the border
      start_ind_rows = floor(extra_rows/2);
      end_ind_rows = size(object_mask_img,1) - ceil(extra_rows/2) -1;
       
      start_ind_cols = floor(extra_cols/2);
      end_ind_cols = size(object_mask_img,2) - ceil(extra_cols/2) -1;
     
      object_mask_img  = object_mask_img(start_ind_rows:end_ind_rows,  ...
                                            start_ind_cols:end_ind_cols,:);     

      masked_object_img  = masked_object_img(start_ind_rows:end_ind_rows,  ...
                                                  start_ind_cols:end_ind_cols,:);     
 
    elseif(extra_rows > 1 && extra_cols > 1)
      %if the object got smaller, pad the border with zeros
      start_row = floor(extra_rows/2);
      end_row = original_size(1) - ceil(extra_rows/2) -1;
      
      start_col = floor(extra_cols/2);
      end_col = original_size(2) - ceil(extra_cols/2) -1;
     
      temp_mask = ones(original_size(1), original_size(2), 3);
      temp_img = zeros(original_size(1), original_size(2), 3);

      temp_mask(start_row:end_row, start_col:end_col,:) = object_mask_img;
      object_mask_img = uint8(temp_mask);

      temp_img(start_row:end_row, start_col:end_col,:) = masked_object_img;
      masked_object_img =uint8(temp_img);
    end% if scale








    %% move the object around in the image
    
    %find the indices of the mask and the bounding box
    [I, J] = find(object_mask_img(:,:,1) == 0);

    min_row = min(I);
    min_col = min(J);
    max_row = max(I);
    max_col = max(J);

    bbox_width = max_col - min_col;
    bbox_height = max_row - min_row;
    
    if(isempty(bbox_width) || isempty(bbox_height))
      disp('empty box!');
      continue;
    end


    %pick a new random point for the top left corner of the object
    valid_tl = 0;
    tl_row = 1;
    tl_col = 1;
    num_tries = 0;
    while(~valid_tl && num_tries < max_occ_tries)
      %get random coordinates
      tl_row = randi( (size(object_mask_img,1) - bbox_height-1 ),1,1);
      tl_col = randi( (size(object_mask_img,2) - bbox_width-1 ),1,1);

      possible_box = [tl_col, tl_row, tl_col+bbox_width, tl_row+bbox_height];

      %make sure this object wont overlap another
      valid_tl = 1;
      if(allow_inter_object_occlusion)
        continue; %skip the occlusion detection 
      end
      for kl=1:size(cur_bboxes,1)

        cur_box = cur_bboxes(kl,:);
        if(sum(cur_box)  == 0)
          continue; %this box is empty
        end

        if(get_bboxes_iou(cur_box, possible_box)> 0)
          valid_tl = 0;
          num_tries = num_tries +1;
          disp('bad_tl');
        end
      end%for kl, each bbox
    end%while no valid tl




    %make a big image, so that it can hold the full object image with the center
    %of the object bbox at its(the big image) center, no matter where the object is
    %in the original image
    big_image = ones(2*size(object_mask_img,1), 2*size(object_mask_img,2), 3); 


    %put the object image in the big image, with the object at the center
    big_center_row = size(object_mask_img,1);
    big_center_col = size(object_mask_img,2);

    start_row = big_center_row  - min_row; 
    end_row = start_row + size(object_mask_img,1) - 1; 
    start_col = big_center_col  - min_col; 
    end_col = start_col + size(object_mask_img,2) - 1; 

    big_image(start_row:end_row, start_col:end_col,:) = object_mask_img;




    %%now crop the big image around its center 
    start_row = big_center_row - tl_row; 
    end_row = start_row + size(object_mask_img,1) - 1; 
    assert(end_row > tl_row + bbox_height);
    start_col = big_center_col  - tl_col; 
    end_col = start_col + size(object_mask_img,2) - 1; 
    
    object_mask_img = uint8(big_image(start_row:end_row, start_col:end_col,:));



    %do the same for the object image
    big_image = zeros(2*size(object_mask_img,1), 2*size(object_mask_img,2), 3); 
    big_center_row = size(object_mask_img,1);
    big_center_col = size(object_mask_img,2);

    start_row = big_center_row  - min_row; 
    end_row = start_row + size(object_mask_img,1) - 1; 
    start_col = big_center_col - min_col; 
    end_col = start_col + size(object_mask_img,2) - 1; 
    big_image(start_row:end_row, start_col:end_col,:) = masked_object_img;

    start_row = big_center_row  - tl_row; 
    end_row = start_row + size(object_mask_img,1) - 1; 
    start_col = big_center_col - tl_col; 
    end_col = start_col + size(object_mask_img,2) - 1; 
    masked_object_img = uint8(big_image(start_row:end_row, start_col:end_col,:));








    %% adjust contrast
    %contrast_scale  = .8 + .2*rand(1,1);
    %masked_object_img = masked_object_img * contrast_scale;







    %% get the new bbox info 
    [I, J] = find(object_mask_img(:,:,1) == 0);

    min_row = min(I);
    min_col = min(J);
    max_row = max(I);
    max_col = max(J);

    cur_bboxes(jl,:) = [min_col, min_row, max_col, max_row];

    cat_id = obj_cat_map(cur_bb_name);



    %just for safety, should not chang size more than a pixel or two

    assert(max(abs(size(object_mask_img) - size(new_back_img))) < 5);
    if(any(~(size(object_mask_img) == size(new_back_img))))
      object_mask_img = imresize(object_mask_img, ...
                                [size(new_back_img,1), size(new_back_img,2)]);
      masked_object_img = imresize(masked_object_img, ...
                                [size(new_back_img,1), size(new_back_img,2)]);
    end
   
    %% apply the mask to the background image and put the object in the background 
    masked_back_img = new_back_img .* object_mask_img;
    %new_img = masked_back_img + masked_object_img;
    new_img = imfuse(masked_object_img, masked_back_img, 'blend'); 
    back_img = new_img;



    %% brightness

    %randomly adjust brightness, since alpha blending and illumination changes
    %only remove brightness
    max_brightness_scale = 255 / double(max(back_img(:)));  
    brightness_scale = .8 + (max_brightness_scale - .8)*rand();
    back_img = uint8( double(back_img) * brightness_scale); 

    %kernel_size2 = randi(3,1,1)*3;
    %kernel = fspecial('gaussian',kernel_size2, kernel_size2);
    kernel_ind2 = randi(length(kernels));
    back_img = imfilter(back_img,kernels{kernel_ind2});


    %write out the label and meta data info
    fprintf(fid_label, '%d %d %d %d %d %d\n', cat_id, min_col, min_row, max_col,...
                                               max_row, pose_angle);
    fprintf(fid_meta, '%d %d %d %d %d %d %d %d %d %d %d %d\n',...
                        cat_id, img_to_use, kernel_ind, kernel_ind2,  erode_size, ...
                        scale, tl_row, tl_col, roll_angle, ...
                        radius, brightness_scale);
                        %min_illum_radius, max_illum_radius, min_illum_intensity, ...
                        %max_illum_intensity,centerX, centerY,
  end%for jl, each big bird object





  %save the new composite image
  imwrite(back_img, fullfile(back_composite_path, ...
                      strcat(cur_composite_base_name, '.jpg'))); 

  if(debug)
    imshow(new_img);
    ginput(1); 
  end
  fclose(fid_label);
  fclose(fid_meta);
end%for il, each background image











