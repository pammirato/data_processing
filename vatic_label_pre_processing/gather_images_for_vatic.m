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

scene_name = 'Home_16_1'; %make this = 'all' to run all scenes


label_name = 'all';%make this 'all' to do it for all labels, 'bigBIRD' to do bigBIRD stuff


max_image_dimension = 600;%how big images will be at the end
start_crop_size = 400;%how big of a square to crop around labeled point
do_depth_crop = 1;%whether or not to adjust crop size based on depth to labeled point
label_box_size = 5;%size of box drawn on image(before crop)


gather_method = 0;   % 0 - gather all images
                     % 1 - gather images without forward AND backward pointers. 

min_gather_percent = .25; %minimum percent of images in the scene that must be gathered



%how many images are in a sub group (each sub_group is one vatic task)
min_images_per_dir = 30;
maxish_images_per_dir = 70;%actual max = maxish + min


debug = 0;



%% SET UP GLOBAL DATA STRUCTURES


%get the names of all the scenes
d = dir(ROHIT_BASE_PATH);
d = d(3:end);
all_scenes = {d.name};


%determine which scenes are to be processed 
if(iscell(scene_name))
  %if we are using the custom list of scenes
  all_scenes = scene_name;
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

  instance_name_to_id_map = get_instance_name_to_id_map();
  instance_names = keys(instance_name_to_id_map); 
 
  
  %decide which labels to process    
  if(iscell(label_name))
    all_labels = label_name;
  elseif(strcmp(label_name,'all'))
    all_labels = instance_names;
  else
    all_labels = {label_name};
  end

  %for each label, process  all the images that see it
  for j=1:length(all_labels) %num_labels
         
    label_name = all_labels{j};
    disp(label_name);

    try
      instance_labels = load(fullfile(meta_path,LABELING_DIR,'raw_labels',...
                      BBOXES_BY_INSTANCE, strcat(label_name,'.mat')));
      
    catch
      disp(['skipping ' label_name]);
      continue;
    end

    boxes = instance_labels.boxes;
    all_image_names = instance_labels.image_names;

    
%    %remove all images before 2823
%    keep_start = 1;
%    for jl=1:length(all_image_names)
%      cur_name  = all_image_names{jl};
%      cur_index = str2double(cur_name(1:6));
%      if(cur_index > 2823)
%        break;
%      end
%      keep_start = keep_start+1;
%    end
%
%    all_image_names = all_image_names(keep_start:end);
%    
%    
%    if(isempty(all_image_names))
%      disp(['2823ing ' label_name]);
%      continue;
%    end

    %% choose which images to gather


    images_to_gather = cell(1,length(all_image_names));

    %use the chosen method 
    if(gather_method == 0)%use all the images
      images_to_gather = all_image_names;
    
    elseif(gather_method == 1)%only pick those withOUT forward AND back pointers
      disp('gather method not supported');

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
      img_name = images_to_gather{k};
      jpg_name = strcat(img_name(1:end-3),'jpg');


      %make sure the jpg file exists
      if( ~ (exist(fullfile(scene_path, JPG_RGB, jpg_name),'file')==2))
        disp(strcati('could not find jpg image ', jpg_name));
        continue;
      end

      %read in the jpg image
      img = imread(fullfile(scene_path, JPG_RGB, jpg_name));

      %get the raw bounding box
      box = boxes(k,:);
      %double the size of the box for image_cropping
      width = max(box(3)-box(1), max_image_dimension/4);
      height = max(box(4)-box(2),max_image_dimension/4);
      box(1) = box(1) - floor(width/2);
      box(2) = box(2) - floor(height/2);
      box(3) = box(3) + floor(width/2);
      box(4) = box(4) + floor(height/2);
      
      box(1) = max(1,box(1));
      box(2) = max(1,box(2));
      box(3) = min(1920,box(3));
      box(4) = min(1080,box(4));


      crop_img = img(box(2):box(4),box(1):box(3),:);

      scale = max_image_dimension/max(size(crop_img));
      scale_img = imresize(crop_img,scale);
     
      big_img = uint8(255*ones(max_image_dimension,max_image_dimension,3));
      big_img(1:size(scale_img,1), 1:size(scale_img,2),:) = scale_img;
 
      if(debug)
        imshow(scale_img);
        ginput(1);
      end

      %save the processed image
      imwrite(big_img,fullfile(meta_path, LABELING_DIR,...
                 IMAGES_FOR_LABELING_DIR, label_name,jpg_name));


      %make the transform struct to allow inverse processing
      t_struct = struct(...
                      'large_box', box, ...
                      'resize_scale', scale,...
                       'scale_img_size', size(scale_img));

      transform_structs{k} = t_struct;
    end%for k in images_to_gather

    %% add in reference image
    ref_img = imread(fullfile(meta_path,LABELING_DIR,'reference_images', ...
                          strcat(label_name,'.jpg')));
    
    %ref_img = imresize(ref_img,[size(scale_img,1),size(scale_img,2)]);






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





