init_bigBIRD;


max_occ_tries = 5;






d = dir(BIGBIRD_BASE_PATH);
big_bird_names = {d(3:end).name};


back_img_path = fullfile('/playpen/ammirato/Data/background_images4');
back_label_path = fullfile('/playpen/ammirato/Data/background_labels_pose');
back_composite_path = fullfile('/playpen/ammirato/Data/background_composite_images_pose');
background_image_names = dir(back_img_path);
background_image_names = {background_image_names(3:end).name};






%load mapping from bigbird name ot category id
bb_cat_map = containers.Map();
fid_bb_map = fopen('/playpen/ammirato/Data/RohitMetaMetaData/big_bird_cat_map.txt', 'rt');

line = fgetl(fid_bb_map);
while(ischar(line))
  line = strsplit(line);
  bb_cat_map(line{1}) = str2double(line{2}); 
  line = fgetl(fid_bb_map);
end
fclose(fid_bb_map);








big_bird_inds = [];


for il=14001:length(background_image_names)

  fprintf('%d of %d\n', il, length(background_image_names));

  cur_back_image_name = background_image_names{il};

  ext_ind = strfind(cur_back_image_name, '.');
  cur_label_filename = strcat(cur_back_image_name(1:ext_ind-1), '_2.txt');
  fid_back_label = fopen(fullfile(back_label_path, cur_label_filename), 'wt');


  back_img = imread(fullfile(back_img_path, cur_back_image_name));
 
  if(size(back_img,3) == 1)
    continue;
  end 

  back_size = size(back_img);



  %select some random bigbird objects
  if(isempty(big_bird_inds))
    big_bird_inds = randperm(length(big_bird_names));
  end


  num_inds_to_use = randi(min(3,length(big_bird_inds)), 1,1);
  inds_to_use = big_bird_inds(1:num_inds_to_use);
  
  big_bird_inds(1:num_inds_to_use) = []; 


  cur_bird_names = big_bird_names(inds_to_use);



  cur_bboxes = zeros(length(cur_bird_names), 4); 




  for jl=1:length(cur_bird_names)
    cur_bb_name = cur_bird_names{jl};


    img_to_use = randi(360, 1,1);%360 = images from first 3 cameras 

    cam_ind = floor(img_to_use/121) + 1;

    pose_ind = img_to_use - (120*(cam_ind-1));
    pose_angle = mod((pose_ind-1)*3, 360);




    big_bird_image = imread(fullfile(BIGBIRD_BASE_PATH, cur_bb_name, 'rgb', ...
                            strcat('NP',num2str(cam_ind), '_', num2str(pose_angle), '.jpg')));


    %blur image
    kernel_size = randi(3,1,1)*3;
    kernel = fspecial('gaussian',kernel_size, kernel_size);
    big_bird_image = imfilter(big_bird_image,kernel);


    big_bird_mask = imread(fullfile(BIGBIRD_BASE_PATH, cur_bb_name, 'masks', ...
                        strcat('NP',num2str(cam_ind), '_', num2str(pose_angle), '_mask.pbm')));


    %se = strel('line',11,90);
    erode_size = randi(5,1,1)*2+3;
    se = strel('ball',8,8);


    big_bird_mask = imerode(255*uint8(~big_bird_mask),se); 

    big_bird_mask = ~big_bird_mask;


    big_bird_mask = repmat(big_bird_mask, 1,1,3);
    
    new_back_img = imresize(back_img, [size(big_bird_image,1), size(big_bird_image,2)]);

     
   

    big_bird_mask_img = uint8(big_bird_mask);
    big_bird_mask_inv = uint8(~big_bird_mask);

    masked_big_bird_img = big_bird_image .* big_bird_mask_inv;      




    original_size = size(big_bird_mask_img);
    scale = rand(1,1)*1.5 + .3;

    big_bird_mask_img = imresize(big_bird_mask_img, scale);
    masked_big_bird_img = imresize(masked_big_bird_img, scale);



    extra_rows = abs(size(big_bird_mask_img,1) - original_size(1));
    extra_cols = abs(size(big_bird_mask_img,2) - original_size(2));

    %extra_rows = max(2,extra_rows);
    %extra_cols = max(2,extra_cols);


    if(scale > 1 && extra_rows > 1 && extra_cols > 1)
      start_ind_rows = floor(extra_rows/2);
      end_ind_rows = size(big_bird_mask_img,1) - ceil(extra_rows/2) -1;
       
      %if(end_ind_rows - start_ind_rows ~= original_size

 
      start_ind_cols = floor(extra_cols/2);
      end_ind_cols = size(big_bird_mask_img,2) - ceil(extra_cols/2) -1;
     
      big_bird_mask_img  = big_bird_mask_img(start_ind_rows:end_ind_rows,  ...
                                            start_ind_cols:end_ind_cols,:);     

      masked_big_bird_img  = masked_big_bird_img(start_ind_rows:end_ind_rows,  ...
                                                  start_ind_cols:end_ind_cols,:);     
 
    elseif(extra_rows > 1 && extra_cols > 1)
      start_row = floor(extra_rows/2);
      end_row = original_size(1) - ceil(extra_rows/2) -1;
      
      start_col = floor(extra_cols/2);
      end_col = original_size(2) - ceil(extra_cols/2) -1;
     
      temp_mask = ones(original_size(1), original_size(2), 3);
      temp_img = zeros(original_size(1), original_size(2), 3);

      temp_mask(start_row:end_row, start_col:end_col,:) = big_bird_mask_img;

      big_bird_mask_img = uint8(temp_mask);

      temp_img(start_row:end_row, start_col:end_col,:) = masked_big_bird_img;

      masked_big_bird_img =uint8(temp_img);


    end% if scale

    

    [I, J] = find(big_bird_mask_img(:,:,1) == 0);

    min_row = min(I);
    min_col = min(J);
    max_row = max(I);
    max_col = max(J);

    bbox_width = max_col - min_col;
    bbox_height = max_row - min_row;


    %pick a new random point for the top left corner of the object
    valid_tl = 0;
    tl_row = 1;
    tl_col = 1;
    num_tries = 0;
    while(~valid_tl && num_tries < max_occ_tries)
      %get random coordinates
      tl_row = randi( (size(big_bird_mask_img,1) - bbox_height-1 ),1,1);
      tl_col = randi( (size(big_bird_mask_img,2) - bbox_width-1 ),1,1);

      possible_box = [tl_col, tl_row, tl_col+bbox_width, tl_row+bbox_height];

      %make sure this object wont overlap another
      valid_tl = 1;
      for kl=1:size(cur_bboxes,1)

        cur_box = cur_bboxes(kl,:);
        if(sum(cur_box)  == 0)
          continue; %this box is empty
        end

        %if(is_point_in_box(cur_box, [tl_col, tl_row]))
        if(get_bboxes_iou(cur_box, possible_box)> 0)
          valid_tl = 0;
          num_tries = num_tries +1;
          disp('bad_tl');
        end
      end%for kl, each bbox
    end%while no valid tl

    big_image = ones(2*size(big_bird_mask_img,1), 2*size(big_bird_mask_img,2), 3); 
    big_center_row = size(big_bird_mask_img,1);
    big_center_col = size(big_bird_mask_img,2);

    %start_row = big_center_row - (size(big_bird_mask_img,1) - min_row); 
    start_row = big_center_row  - min_row; 
    end_row = start_row + size(big_bird_mask_img,1) - 1; 

    %start_col = big_center_col - (size(big_bird_mask_img,2) - min_col); 
    start_col = big_center_col  - min_col; 
    end_col = start_col + size(big_bird_mask_img,2) - 1; 

    big_image(start_row:end_row, start_col:end_col,:) = big_bird_mask_img;


    %start_row = big_center_row - (size(big_bird_mask_img,1) - tl_row); 
    start_row = big_center_row - tl_row; 
    end_row = start_row + size(big_bird_mask_img,1) - 1; 


    assert(end_row > tl_row + bbox_height);

    %start_col = big_center_col - (size(big_bird_mask_img,2) - tl_col); 
    start_col = big_center_col  - tl_col; 
    end_col = start_col + size(big_bird_mask_img,2) - 1; 
    
    big_bird_mask_img = uint8(big_image(start_row:end_row, start_col:end_col,:));




    big_image = zeros(2*size(big_bird_mask_img,1), 2*size(big_bird_mask_img,2), 3); 
    big_center_row = size(big_bird_mask_img,1);
    big_center_col = size(big_bird_mask_img,2);

    %start_row = big_center_row - (size(big_bird_mask_img,1) - min_row); 
    start_row = big_center_row  - min_row; 
    end_row = start_row + size(big_bird_mask_img,1) - 1; 

    %start_col = big_center_col - (size(big_bird_mask_img,2) - min_col); 
    start_col = big_center_col - min_col; 
    end_col = start_col + size(big_bird_mask_img,2) - 1; 

    big_image(start_row:end_row, start_col:end_col,:) = masked_big_bird_img;


    %start_row = big_center_row - (size(big_bird_mask_img,1) - tl_row); 
    start_row = big_center_row  - tl_row; 
    end_row = start_row + size(big_bird_mask_img,1) - 1; 

    %start_col = big_center_col - (size(big_bird_mask_img,2) - tl_col); 
    start_col = big_center_col - tl_col; 
    end_col = start_col + size(big_bird_mask_img,2) - 1; 
    
    masked_big_bird_img = uint8(big_image(start_row:end_row, start_col:end_col,:));








    %% contrast
    contrast_scale  = .8 + .2*rand(1,1);
    masked_big_bird_img = masked_big_bird_img * contrast_scale;







    %get the bbox info 
    [I, J] = find(big_bird_mask_img(:,:,1) == 0);

    min_row = min(I);
    min_col = min(J);
    max_row = max(I);
    max_col = max(J);

    cur_bboxes(jl,:) = [min_col, min_row, max_col, max_row];

    cat_id = bb_cat_map(cur_bb_name);

    fprintf(fid_back_label, '%d %d %d %d %d %d\n', cat_id, min_col, min_row, max_col, max_row, pose_angle);


    if(any(~(size(big_bird_mask_img) == size(new_back_img))))
      big_bird_mask_img = imresize(big_bird_mask_img, ...
                                [size(new_back_img,1), size(new_back_img,2)]);
      masked_big_bird_img = imresize(masked_big_bird_img, ...
                                [size(new_back_img,1), size(new_back_img,2)]);
    end
    
    masked_back_img = new_back_img .* big_bird_mask_img;
    new_img = masked_back_img + masked_big_bird_img;

    back_img = new_img;
    %imshow(new_img);
    %ginput(1); 

  end%for jl, each big bird object

    ext_ind = strfind(cur_back_image_name, '.');

    imwrite(back_img, fullfile(back_composite_path, ...
                        strcat(cur_back_image_name(1:ext_ind-1), '_2.jpg'))); 
    %imshow(back_img);
   % ginput(1); 

  fclose(fid_back_label);
end%for il, each background image











