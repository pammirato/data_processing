function [] = change_vatic_label_frame_names(scene_name)
%changes frame name in turk annotation structs to names that match image names in rgb directory 


%initialize contants, paths and file names, etc. 
init;

%TODO - test


%% USER OPTIONS

%scene_name = 'Office_02_1'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 




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
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path =fullfile(ROHIT_META_BASE_PATH, scene_name);

  %get a list of all the instances in the scene
  instance_name_to_id_map = get_instance_name_to_id_map();
  instance_names = keys(instance_name_to_id_map); 

  output_boxes_path = fullfile(meta_path,LABELING_DIR,'output_boxes');
  output_boxes_names = dir(fullfile(output_boxes_path,'*.mat'));
  output_boxes_names = {output_boxes_names.name};

  frame_count = 0;


  for jl=1:length(output_boxes_names)
    i_name = output_boxes_names{jl};
    
    suffix_start = strfind(i_name,'_');
    suffix_start = suffix_start(end);
    instance_name = i_name(1:(suffix_start-1));

    i_mat = load(fullfile(output_boxes_path,i_name));


    image_names = dir(fullfile(meta_path,LABELING_DIR,IMAGES_FOR_LABELING_DIR,...
                  i_name(1:end-4),'*.jpg'));
    image_names = {image_names.name};
                


    annotations = i_mat.annotations;
    
    for k=1:length(annotations)
        ann = annotations{k};
        assert(ann.frame ~= 0);
        
        cur_name = image_names{ann.frame+1}; 
        
        

        %ann.frame = str2num(cur_name(1:10));
        %ann.frame = strcat(cur_name(1:10),'.png');
        ann.frame = cur_name;

        annotations{k} = ann;
    end%for k, each annotation
    frame_count = frame_count +i_mat.num_frames;

    i_mat.annotations = annotations;

    save(fullfile(output_boxes_path,i_name),'-struct','i_mat');

  end%for j ,each instance 
end%for i,  each scene


end%function


