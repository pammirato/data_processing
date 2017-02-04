init;


scene_name = 'Home_01_2'; %make this = 'all' to run all scenes
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


base_path = '/playpen/ammirato/Data/RohitMetaMetaData/aligned_object_point_clouds/';
object_names = dir(fullfile(base_path,'*.ply'));
object_names = {object_names.name};


%% MAIN LOOP

for il=1:length(object_names)
 
  cur_instance_name = object_names{il};
  cur_instance_name = cur_instance_name(1:end-4);
  
  cur_instance_id = instance_name_to_id_map(cur_instance_name);
  
  for jl=1:length(all_scenes)
 
    %% set scene specific data structures
    scene_name = all_scenes{jl};
    scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
    meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);
    
    img_save_path = fullfile(meta_path,'labels','pose_images');
    ann_save_path = fullfile(meta_path,'labels','pose_annotations');
    if(~exist(img_save_path,'dir'))
      mkdir(img_save_path);
    end
    if(~exist(ann_save_path,'dir'))
      mkdir(ann_save_path);
    end
    
    %load instance labels
    try
      boxes = load(fullfile(meta_path,'labels','verified_labels',...
                  'bounding_boxes_by_instance', ...
                  strcat(cur_instance_name, '.mat')));
    catch
      continue;
    end
    image_names = boxes.image_names;          
    boxes = boxes.boxes;
    
    %get the box with the biggest area
    areas = (boxes(:,3) - boxes(:,1)) .* (boxes(:,4) - boxes(:,2));
    [~,index] = max(areas);
    
    box = boxes(index,:);
    img_name = image_names{index};
    
    
    box = box + [-50 -50 50 50 0 0];
    box(1) = max(1,box(1));
    box(2) = max(1,box(2));
    box(3) = min(1920,box(3));
    box(4) = min(1080,box(4));
    
    img = imread(fullfile(scene_path,'jpg_rgb',img_name));
    img = img(box(2):box(4),box(1):box(3),:);
    
    imwrite(img,fullfile(img_save_path, ...
            strcat(img_name(1:10), '_', cur_instance_name, '.jpg')));
          
          
    %write the annotation file
    record = struct();
    record.filename = strcat(img_name(1:10),'_',cur_instance_name,'.jpg');

    cur_box = [1 1 size(img,2)-50, size(img,1)-50];
    if(cur_box(3)<1)
      cur_box(3) = size(img,2);
    end
    if(cur_box(4)<1)
      cur_box(4) = size(img,1);
    end
    
    
    objects = struct();
    objects.class = cur_instance_name;
    objects.bbox = cur_box(1:4);
    objects.cad_index = cur_instance_id;
    objects.truncated = 0;
    objects.occluded = 0;
    objects.difficult = 0;
    objects.viewpoint = [];

    record.objects = objects;

    save(fullfile(ann_save_path,...
          strcat('n_',img_name(1:10),'.mat')),'record');
    
    
  end%for jl
  
  
end%for il, each object_name
