%NOT USED


init_bigBIRD;


d = dir(BIGBIRD_BASE_PATH);
object_names = {d(3:end).name};


save_base_path = fullfile('/playpen/ammirato/Detectors/SegNet/BigBIRD');


fid_train = fopen(fullfile(save_base_path, 'train.txt'), 'wt');
fid_test = fopen(fullfile(save_base_path, 'test.txt'), 'wt');

for il=1:length(object_names)

  cur_bb_name = object_names{il};
  disp(cur_bb_name);
  image_names = dir(fullfile(BIGBIRD_BASE_PATH, object_names{il}, 'rgb', '*.jpg'));
  image_names = {image_names.name};
  test = 0;

  if(strcmp(cur_bb_name, 'listerine_green') ||  ...
      strcmp(cur_bb_name, 'aunt_jemima_original_syrup') ||  ...
      strcmp(cur_bb_name, 'coca_cola_glass_bottle') || ...
      strcmp(cur_bb_name, 'red_bull') || ...
      strcmp(cur_bb_name, 'softsoap_clear')) 

    test = 1;
    %continue;
  else
    continue;
  end
  
  if(strcmp(cur_bb_name, 'hunts_sauce') ||  ...
      strcmp(cur_bb_name, 'pepto_bismol')) 
    disp('noooooooooooooooo');
    %test = 1;
  end

  %for each object chosen, put in the image with random parameters
  for jl=1:length(image_names)


    rgb_name = image_names{jl};
    mask_name = strcat(rgb_name(1:end-4), '_mask.pbm');

    %% load the chosen image
    object_img = imread(fullfile(BIGBIRD_BASE_PATH, cur_bb_name, 'rgb', rgb_name)); 

    %load the object mask for the chosen image
    object_mask = imread(fullfile(BIGBIRD_BASE_PATH, cur_bb_name, 'org_masks', mask_name));


    %% crop around the center
    row_offset = 250; 
    col_offset = 300;
    start_row = row_offset;
    end_row = 1024 - row_offset;
    start_col = col_offset;
    end_col = 1280-col_offset;


    object_img = object_img(start_row:end_row, start_col:end_col, :);
    object_mask = object_mask(start_row:end_row, start_col:end_col);



    object_img = imresize(object_img, [360,480]);
    object_mask = imresize(object_mask, [360,480]);

    object_mask = uint8(object_mask);
     
   

    if(test)
      img_save_path = fullfile(save_base_path,'test/', ...
                          strcat(cur_bb_name, '_', rgb_name(1:end-4), '.png'));
      mask_save_path = fullfile(save_base_path,'testannot/', ...
                            strcat(cur_bb_name, '_',rgb_name(1:end-4), '_mask.png'));
      imwrite(object_img,img_save_path);
      imwrite(object_mask,mask_save_path);

      fprintf(fid_test, '%s %s ', img_save_path, mask_save_path);

    else
      img_save_path = fullfile(save_base_path,'train/', ... 
                          strcat(cur_bb_name, '_', rgb_name(1:end-4), '.png'));
      mask_save_path = fullfile(save_base_path,'trainannot/', ...
                            strcat(cur_bb_name, '_',rgb_name(1:end-4), '_mask.png'));
      imwrite(object_img,img_save_path);
      imwrite(object_mask,mask_save_path);

      fprintf(fid_train, '%s %s ', img_save_path, mask_save_path);
    end






    if(debug)
      imshow(object_img);
      hold on;
      %h = imagesc(object_mask);
      %set(h, 'AlphaData', .5);
      hold off;
      ginput(1);
    end 
  end
end%for il



fclose(fid_train);
fclose(fid_test);










