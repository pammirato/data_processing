%transforms bounding boxes from vatic tool to be in original image units
%images are transformed before being uploaded to vatic, so the 
%boxes need to be transformed inversely to fit the original images 


%initialize contants, paths and file names, etc. 
init;

%TODO - test


%% USER OPTIONS

scene_name = 'SN208_Density_2by2_same_chair'; %make this = 'all' to run all scenes
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

  %get names of all instances that were labeled in the scene
  instace_label_names = get_names_of_X_for_scene(scene_name, 'instance_labels');


  for j=1:length(instace_label_names)
      %% load info for this label
      cur_name = instace_label_names{j};
      label_name = cur_name(1:end-4)
      
      cur_instance_labels = load(fullfile(scene_path,LABELING_DIR, ...
                                  BBOXES_BY_INSTANCE_DIR,cur_name));
      
      %get a  map from image name to a struct describing the transform it took
      transform_map = load(fullfile(meta_path,LABELING_DIR,DATA_FOR_LABELING_DIR,label_name,'transform_map.mat'));
      transform_map = transform_map.transform_map;
      
     
      %get the acutal boxes labeled 
      annotations = cur_instance_labels.annotations;
      for k=1:length(annotations)
          
          ann = annotations{k};
         
          %get the box and the image name 
          bbox = [ann.xtl, ann.ytl, ann.xbr, ann.ybr];
          image_name = ann.frame;
          
          
          %% apply transformation to box
          ts = transform_map(image_name);

          label_struct = ts.label_struct;
          centering_offset = ts.centering_offset;
          crop_dimensions = ts.crop_dimensions;
          big_image_place = ts.big_image_place;
          resize_scale = ts.resize_scale;


          %% resize the box
          bbox = bbox * (1/resize_scale);

          %% unapply the crop
          xcrop_min = int64(crop_dimensions(1));
          ycrop_min = int64(crop_dimensions(3));

          bbox(1) = bbox(1) + xcrop_min;
          bbox(2) = bbox(2) + ycrop_min;
          bbox(3) = bbox(3) + xcrop_min;
          bbox(4) = bbox(4) + ycrop_min;


          %% unapply centering the label in the center of a big image
          start_row = big_image_place(1);
          start_col = big_image_place(3);

          bbox(1) = max(1,bbox(1) - start_col);
          bbox(2) = max(1,bbox(2) - start_row);
          bbox(3) = max(1,bbox(3) - start_col);
          bbox(4) = max(1,bbox(4) - start_row);
          
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
      
      cur_instance_labels.annotations = annotations;
     
      %save this instance 
      save(fullfile(scene_path,LABELING_DIR, BBOXES_BY_INSTANCE_DIR,...
             cur_name), '-struct','cur_instance_labels');

 end%for j, each 
end%for i, each scene



