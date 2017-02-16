function [] = transform_vatic_output(scene_name)
%transforms bounding boxes from vatic tool to be in original image units
%images are transformed before being uploaded to vatic, so the 
%boxes need to be transformed inversely to fit the original images 


%initialize contants, paths and file names, etc. 
init;

%TODO - test


%% USER OPTIONS

%scene_name = 'Office_02_1'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


debug =0;



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

  %get names of all instet_names_of_X_for_scene(scene_name, 'instance_labels');
  instance_label_names = dir(fullfile(meta_path,LABELING_DIR,'output_boxes','*.mat'));
  instance_label_names = {instance_label_names.name};


  for j=1:length(instance_label_names)
      %% load info for this label
      cur_name = instance_label_names{j};
      label_name = cur_name(1:end-4);
      disp(label_name);
      
      cur_instance_labels = load(fullfile(meta_path,LABELING_DIR, ...
                                 'output_boxes',cur_name));
      
      %get a  map from image name to a struct describing the transform it took
      transform_map = load(fullfile(meta_path,LABELING_DIR,DATA_FOR_LABELING_DIR,...
                              label_name,'transform_map.mat'));
      transform_map = transform_map.transform_map;
      
     
      %get the acutal boxes labeled 
      annotations = cur_instance_labels.annotations;

      indices_to_remove = [];
      for k=1:length(annotations)
          
          ann = annotations{k};
         
          %get the box and the image name 
          bbox = [ann.xtl, ann.ytl, ann.xbr, ann.ybr];
          image_name = ann.frame;
          
          
          %% apply transformation to box
          try
          ts = transform_map(image_name);
          catch
            indices_to_remove(end+1) = k;
            disp('REMOVIONG IND??');
            assert(0);
            continue;
          end


          large_box = double(ts.large_box);
          resize_scale = double(ts.resize_scale);
          scale_image_size = ts.scale_img_size;
          
          %% resize the box
          bbox = double(double(bbox) * (1/resize_scale));

          %% unapply the crop
          bbox(1) = floor(bbox(1) + large_box(1));
          bbox(2) = floor(bbox(2) + large_box(2));
          bbox(3) = ceil(bbox(3) + large_box(1));
          bbox(4) = ceil(bbox(4) + large_box(2));

          bbox(1) = max(1,bbox(1));
          bbox(2) = max(1,bbox(2));
          bbox(3) = min(1920,bbox(3));
          bbox(4) = min(1080,bbox(4));
          
          
%           assert(bbox(1) >0);
%           assert(bbox(2) >0);
%           assert(bbox(3) <=1920);
%           assert(bbox(4) <=1080);
          
          %% debug vis
          if(debug)
            %show the rgb image
            rgb_image = imread(fullfile(scene_path,RGB, image_name));

            imshow(rgb_image);
            hold on;

            title(cur_name);
            %draw  the new bbox
            rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], ...
                         'LineWidth',2, 'EdgeColor','b');

            ginput(1);
          end
          
          %% put new info back into structs
          ann.xtl = bbox(1);
          ann.ytl = bbox(2);
          ann.xbr = bbox(3);
          ann.ybr = bbox(4);
         
          annotations{k} = ann;
          
      end%for k, each annotation 
     
      annotations(indices_to_remove) = [];
 
      cur_instance_labels.annotations = annotations;
     
      %save this instance 
      save(fullfile(meta_path,LABELING_DIR, 'output_boxes',...
             cur_name), '-struct','cur_instance_labels');

 end%for j, each 
end%for i, each scene


end%function



