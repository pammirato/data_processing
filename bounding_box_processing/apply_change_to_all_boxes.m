function apply_change_to_all_boxes(scene_name, instance_name, changes, label_type)
%Applys a uniform change to all bounding box labels for a given instance in a given scene
% 
%INPUTS:
%       scene_name: String name of the desired scene
%       instance_name: String name of the desired instances boxes to change
%       changes: length 4 vector of values to add to xmin, ymin, xmax, ymax in that order
%       label_type: optional - 'raw_labels'(default) or 'verified_labels' 


%CLEANED - no
%TESTED - yes

%initialize contants, paths and file names, etc. init;
init;


%% USER OPTIONS


%whether or not to run for the scenes in the custom list
%scene_name = 'Office_01_2';
%instance_name = 'pepto_bismol';

%set default label_type if not inputted by user
if(nargin < 4)
  label_type = 'raw_labels'; 
end

label_loc = 'meta'; %which path to use: scene or meta 

xmind = changes(1);
xmaxd = changes(2);
ymind = changes(3);
ymaxd = changes(4);



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

for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path = fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %set label_path, where to load the labels from
  if(strcmp(label_loc,'meta'))
    label_path = meta_path;
  else
    label_path = scene_path;
  end


  %get a list of all the instances in the scene
  instance_name_to_id_map = get_instance_name_to_id_map();
  instance_names = keys(instance_name_to_id_map);

  cur_instance_name = instance_name; 
  cur_instance_file_name = strcat(cur_instance_name, '.mat');
  disp(cur_instance_name);

  %load the boxes for this instance and make a map
  try
    cur_instance_labels= load(fullfile(label_path,LABELING_DIR, label_type, ...
                                BBOXES_BY_INSTANCE, cur_instance_file_name));
  catch
    %this instance may not be in this scene, so skip it
    continue;
  end
  %get the image names and boxes for this instance from the loaded file struct 
  image_names = cur_instance_labels.image_names;
  boxes = cur_instance_labels.boxes; 

  %apply the changes
  boxes = [boxes(:,1)+xmind, boxes(:,2)+ymind,  ...
           boxes(:,3)+xmaxd, boxes(:,4)+ymaxd, boxes(:,5:end)]; 
         
  boxes(boxes<=0) = 1;
  boxes(boxes>1920) = 1920;
  boxes(boxes==(1080+ymaxd)) = 1080;
  boxes(:,6) = 0;

  %save the boxes
  save(fullfile(label_path,LABELING_DIR, label_type, ...
                                BBOXES_BY_INSTANCE, cur_instance_file_name), ...
                            'image_names', 'boxes');
                  


  %update the other box format for this scene(boxes by image)
  convert_boxes_by_instance_to_image_instance(scene_name,label_type);
end%for il,  each scene

end %function

