%puts one image per instance in a common folder. Purpose is the be the 'reference image'
%for the gather images script. this is a sort of training image for vatic workers  



%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Office_02_1'; %make this = 'all' to run all scenes
max_image_dimension=600;
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



instance_name_to_id_map = get_instance_name_to_id_map();
instance_names = keys(instance_name_to_id_map);

%% MAIN LOOP

for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);
  
  %make the path for the reference images
  mkdir(fullfile(meta_path,LABELING_DIR,REFERENCE_IMAGES_DIR));

  %holds all image and l



  for jl=1:length(instance_names)

    cur_instance_name = instance_names{jl};

    try
      instance_labels = load(fullfile(meta_path,LABELING_DIR, 'raw_labels',...
                          BBOXES_BY_INSTANCE, strcat(cur_instance_name,'.mat')));
    catch
      disp(['skipping: ' cur_instance_name]);
      continue;
    end

    boxes = instance_labels.boxes;
    image_names = instance_labels.image_names;

    areas = (boxes(:,3) - boxes(:,1)) .* (boxes(:,4) - boxes(:,2));
    [~,index] = max(areas);
    
    box = boxes(index,:);
    img_name = image_names{index};


    width = max(box(3)-box(1), max_image_dimension/2);
    height = max(box(4)-box(2),max_image_dimension/2);
    box(1) = box(1) - floor(width/2);
    box(2) = box(2) - floor(height/2);
    box(3) = box(3) + floor(width/2);
    box(4) = box(4) + floor(height/2);
    
    box(1) = max(1,box(1));
    box(2) = max(1,box(2));
    box(3) = min(1920,box(3));
    box(4) = min(1080,box(4));

    img = imread(fullfile(scene_path,JPG_RGB, strcat(img_name(1:10),'.jpg')));
    
    crop_img = img(box(2):box(4),box(1):box(3),:);
    scale = max_image_dimension/max(size(crop_img));
    scale_img = imresize(crop_img,scale);
    
    big_img = uint8(255*ones(max_image_dimension,max_image_dimension,3));
    big_img(1:size(scale_img,1), 1:size(scale_img,2),:) = scale_img;

    %% save the img in the reference directory
    imwrite(big_img,  fullfile(meta_path,LABELING_DIR,REFERENCE_IMAGES_DIR, ...
                            strcat(cur_instance_name,'.jpg')));

  end%for jl, each unqiue label
end%for il, each scene


