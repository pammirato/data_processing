%gathers images that contain each instance in a scene. Puts them all into
%folders, organized for uploading to vatic tool. 
%For use after find_images_that_see_point script 

%works by cropping around the labeled point in each image, 
%then resizing the image(effectively a zoom in)

%reference image - an image to demonstrate what ojbect a worker
%                  is supposed to find in the other images


%TODO   - draw label dot after crop?
%       - change max/min images per dir relationship
%       - fix depth crop
%       - do something about start crop size

%initialize contants, paths and file names, etc. 
init;


%% USER OPTIONS

scene_name = 'FB341'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


label_name = 'yoda1';%make this 'all' to do it for all labels, 'bigBIRD' to do bigBIRD stuff
use_custom_labels = 0;
custom_labels_list = {'potted_plant', 'potted_plant2'};


max_image_dimension = 600;%how big images will be at the end
start_crop_size = 400;%how big of a square to crop around labeled point
do_depth_crop = 1;%whether or not to adjust crop size based on depth to labeled point
depth_crop_thresh = 2500;%distance in mm object must be to do depth crop
label_box_size = 5;%size of box drawn on image(before crop)


gather_method = 1;   % 0 - gather all images
                     % 1 - gather images without forward AND backward pointers. 

min_gather_percent = .25; %minimum percent of images in the scene that must be gathered



%how many images are in a sub group (each sub_group is one vatic task)
min_images_per_dir = 20;
maxish_images_per_dir = 50;%actual max = maxish + min


debug = 0;



%% SET UP GLOBAL DATA STRUCTURES


%get the names of all the scenes
d = dir(ROHIT_BASE_PATH);
d = d(3:end);
all_scenes = {d.name};


%determine which scenes are to be processed 
if(use_custom_scenes && ~isempty(custom_scenes_list))
  %if we are using the custom list of scenes
  all_scenes = custom_scenes_list;
elseif(~strcmp(scene_name, 'all'))
  %if not using custom, or all scenes, use the one specified
  all_scenes = {scene_name};
end




%% MAIN LOOP

for i=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{i};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


  %load image_structs for all images
  image_structs_file =  load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;

  %make this for easy access to data 
  mat_image_structs = cell2mat(image_structs); 
  
  %make a map from image_name to image struct for easy saving later
  image_structs_map = containers.Map({mat_image_structs.image_name}, image_structs);




  %get the map to find all the images that 'see' each label
  label_to_images_that_see_it_map = load(fullfile(meta_path,LABELING_DIR,...
                                      DATA_FOR_LABELING_DIR, ...
                                      LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE));
   
  label_to_images_that_see_it_map = label_to_images_that_see_it_map.( ...
                                                  LABEL_TO_IMAGES_THAT_SEE_IT_MAP);
  
  %get names of all labels           
  all_labels = label_to_images_that_see_it_map.keys;
  
  %decide which labels to process    
  if(use_custom_labels && ~isempty(custom_labels_list))
    all_labels = custom_labels_list;
  elseif(strcmp(label_name,'bigBIRD'))
    temp = dir(fullfile(BIGBIRD_BASE_PATH));
    temp = temp(3:end);
    all_labels = {temp.name};
  elseif(strcmp(label_name, 'all'))
    all_labels = all_labels;
  else
    all_labels = {label_name};
  end

  %for each label, process  all the images that see it
  for j=1:length(all_labels) %num_labels
         
    label_name = all_labels{j}



    %get the structs with IMAGE_NAME, X, Y, DEPTH for images that see this
    %instance
    try
      label_structs = label_to_images_that_see_it_map(label_name);
    catch
      disp(strcat('could not find ',label_name));
      continue;
    end

    %% choose which images to gather

    %get all the image names,and make a map to label structs
    temp = cell2mat(label_structs);
    all_image_names = {temp.(IMAGE_NAME)};
    label_structs_map = containers.Map(all_image_names, label_structs); 


    images_to_gather = cell(1,length(all_image_names));

    %use the chosen method 
    if(gather_method == 0)%use all the images
      images_to_gather = all_image_names;
    
    elseif(gather_method == 1)%only pick those withOUT forward AND back pointers

      %keep track of which image names are used
      indices_used = zeros(1,length(all_image_names));
 
      %for each image, load its struct and check its pointers   
      for k=1:length(all_image_names)
        cur_image_name = all_image_names{k};
  
        %get the image struct and pointers 
        cur_image_struct = image_structs_map(cur_image_name); 
        forward_pointer = cur_image_struct.translate_forward;
        backward_pointer = cur_image_struct.translate_backward;

        %check if both the pointers are valid
        try
          %for the pointer to be valid, it must be the name 
          %of an image the sees this label. Therefore it must
          %be in the label structs map. 
          temp = label_structs_map(forward_pointer);
          temp = label_structs_map(backward_pointer); 

          %if we have both pointers, skip this image
          continue;
        catch
          %we want to use this image
          indices_used(k) = 1;
          images_to_gather{k} = cur_image_name;
        end%try
      end%for k, each image_name 

      %clear out empty spaces in the array
      images_to_gather = images_to_gather(~cellfun('isempty',images_to_gather));

      %now make sure the minium amount of images were chosen
      min_num_images = ceil(length(all_image_names) * min_gather_percent);
      if(length(images_to_gather) < min_num_images)
        %how many more images we need
        num_extra_images = min_num_images - length(images_to_gather);

        %get indices of names not used yet
        indices_not_used = find(indices_used ==0);

        %get a random selection of these not used indices
        rand_indices = randi([1,length(indices_not_used)],[1,num_extra_images]);
         
        images_to_add = all_image_names(indices_not_used(rand_indices));
      
        %concatenate the image names
        images_to_gather = cat(2,images_to_gather, images_to_add); 
      end%if there aren't enough images to gather 
    else
      disp('gather method not supported');
      return;
    end
      










    %%gather the images

    %make a directiory to store all the processed images
    mkdir(fullfile(meta_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, label_name));

    %for each image, save a struct that details what processing(crops, etc.) was done
    transform_structs = cell(1,length(images_to_gather));
    
    %for each image
    for k=1:length(images_to_gather)
      png_name = images_to_gather{k};
      
      
      jpg_name = strcat(png_name(1:end-3),'jpg');


      %make sure the jpg file exists
      if( ~ (exist(fullfile(scene_path, JPG_RGB, jpg_name),'file')==2))
        disp(strcati('could not find jpg image ', jpg_name));
        continue;
      end

      %read in the jpg image
      img = imread(fullfile(scene_path, JPG_RGB, jpg_name));

      %get info about label in this image
      ls = label_structs_map(png_name);

      %% DEPTH CROP
      %get the depth of the labeled point, and crop accordingly 
      label_depth = double(ls.depth);
     
      %for points further away, make the crop region smaller(more zoom) 
      crop_size = start_crop_size;
      if(do_depth_crop && label_depth >depth_crop_thresh)
        crop_size = crop_size*(depth_crop_thresh/label_depth);
      end


      %% draw the label dot
      x_dot_min = max(1,floor(ls.(X) - label_box_size/2));
      x_dot_max = min(size(img,2),floor(ls.(X) + label_box_size/2));
      y_dot_min = max(1,floor(ls.(Y) - label_box_size/2));
      y_dot_max = min(size(img,1),floor(ls.(Y) + label_box_size/2));

      temp =  img(y_dot_min:y_dot_max,x_dot_min:x_dot_max,1);
      img(y_dot_min:y_dot_max,x_dot_min:x_dot_max,1) = 0*ones(size(temp));
      img(y_dot_min:y_dot_max,x_dot_min:x_dot_max,2) = 255*ones(size(temp));
      img(y_dot_min:y_dot_max,x_dot_min:x_dot_max,3) = zeros(size(temp));

      %display image with point drawn for debugging
      if(debug)
        imshow(img);
        ginput(1);
      end


      %% make it so the labeled point is in the center of the image
      %make a larger image(4X) of white. Place the rgb img in it so
      %the labeled point is in the center

      %make big image and get center coordinates
      display_image = uint8(255*ones(2*size(img,1),2*size(img,2),3));
      center_pos = [size(img,1), size(img,2)];

      %get original label position, and difference from desired location
      label_pos = double([ls.y ls.x]);
      diff_pos = center_pos - label_pos ;

      %shift the entire original image by diff_pos in new image
      start_row = 1+diff_pos(1);
      end_row = start_row+size(img,1)-1;
      start_col = 1+diff_pos(2);
      end_col = start_col+size(img,2)-1;

      %put the orginial image in
      display_image(start_row:end_row,start_col:end_col,:) = img;


      %% now crop the image around the label
      y_crop_min = max(1,floor(start_row + label_pos(1) - (crop_size/2)));
      y_crop_max = min(size(display_image,1),floor(start_row + label_pos(1) + (crop_size/2)));

      x_crop_min = max(1,floor(start_col + label_pos(2) - (crop_size/2)));
      x_crop_max = min(size(display_image,2),floor(start_col + label_pos(2) + (crop_size/2)));

      crop_img = display_image(y_crop_min:y_crop_max,x_crop_min:x_crop_max,:);





      %% now resize the image
      scale = max_image_dimension/max(size(crop_img));
      scale_img = imresize(crop_img,scale);

      if(debug)
        imshow(scale_img);
        ginput(1);
      end

      %save the processed image
      imwrite(scale_img,fullfile(meta_path, LABELING_DIR,...
                 IMAGES_FOR_LABELING_DIR, label_name,jpg_name));


      %make the transform struct to allow inverse processing
      t_struct = struct('label_struct',ls,'centering_offset',diff_pos, ...
                      'crop_dimensions', [x_crop_min,x_crop_max,y_crop_min,y_crop_max], ...
                      'big_image_place', [start_row,end_row,start_col,end_col], ...
                       'resize_scale', scale);

       if(strcmp(jpg_name(1:6),'000007'))
        breakp = 1;
        end

      transform_structs{k} = t_struct;
    end%for k in images_to_gather

    %% add in reference image
    if(exist(fullfile(BIGBIRD_BASE_PATH,label_name,'NP1_0.jpg'),'file'))
      ref_img = imread(fullfile(BIGBIRD_BASE_PATH,label_name,'NP1_0.jpg'));
    else
      ref_img = imread(fullfile(meta_path,LABELING_DIR,'reference_images', ...
                          strcat(label_name,'.jpg')));
    end
    ref_img = imresize(ref_img,[size(scale_img,1),size(scale_img,2)]);






    %% now split up the processed images according to min/max images per dir


     num_buckets = 0;%number of sub_groups needed
     num_images = length(dir(fullfile(meta_path, LABELING_DIR, ...
                          IMAGES_FOR_LABELING_DIR, label_name,'*.jpg')));

     %if we have too many images for in group
     if(num_images > maxish_images_per_dir)
      %get how many sub_groups we need to fit the 
      if(mod(num_images,maxish_images_per_dir) < min_images_per_dir)
          num_buckets = floor(num_images/maxish_images_per_dir);
      else
          num_buckets = ceil(num_images/maxish_images_per_dir);
      end
  
      %if we have more than one sub_group 
      if(num_buckets > 1)
        %keep track of number of images move              
        images_moved_so_far = 0;
        
        processed_image_names = dir(fullfile(meta_path, LABELING_DIR, ...
                        IMAGES_FOR_LABELING_DIR, label_name,'*.jpg'));
        processed_image_names = {processed_image_names.name};

        %put each sub_group of images in its own directory
        for k=1:num_buckets
          %make a new directory to store the subgroup
          mkdir(fullfile(meta_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, ...
                      strcat(label_name, '_', num2str(k))));
         
          %get start and end index of thsi sub group  
          start_kk = images_moved_so_far + 1;
          end_kk = start_kk + maxish_images_per_dir - 1;

          %make sure the index is in bounds of the array
          if(end_kk > length(processed_image_names) || k ==num_buckets)
            end_kk = length(processed_image_names);
          end
         
          %move each file in this subgroup 
          for kk=start_kk:end_kk
            movefile(fullfile(meta_path,LABELING_DIR,IMAGES_FOR_LABELING_DIR, ...
                                label_name, processed_image_names{kk}), ...
                     fullfile(meta_path,LABELING_DIR,IMAGES_FOR_LABELING_DIR, ...
                                strcat(label_name, '_', num2str(k)), ...
                                 processed_image_names{kk}));
          end

          %add the reference image
          imwrite(ref_img,fullfile(meta_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR,...
                               strcat(label_name, '_', num2str(k)),'0000000000.jpg') );

          images_moved_so_far = end_kk;

        end%if nuim_buxkets > 1 
      else%if its just one bucket just add the reference image
        imwrite(ref_img,fullfile(meta_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR,...
                                     label_name,'0000000000.jpg') );
      end% num_images > maxish 

    else%if its just one bucket just add the reference image
      imwrite(ref_img,fullfile(meta_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR,...
                                 label_name,'0000000000.jpg') );
    end%if more images than max images
    

    %make a directory to save the transform structs  
    mkdir(fullfile(meta_path,LABELING_DIR,DATA_FOR_LABELING_DIR,label_name));

    %make a map of the transform structs fore easy access later 
    transform_map = containers.Map(images_to_gather, transform_structs);
    save(fullfile(meta_path,LABELING_DIR,DATA_FOR_LABELING_DIR,...
                  label_name,'transform_map.mat'), 'transform_map');
    
    %delete the old directory if sub_groups were made 
    if(num_buckets  > 1)
      try
        rmdir(fullfile(meta_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, label_name));
      catch
      end
    end  

  end%for j, each label_name
end%for i, each scene





