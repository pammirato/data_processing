%propogates labels from vatic output to all other images 
%assumes all images without both forward and backward pointers have been labeled

%initialize contants, paths and file names, etc. 
init;


%TODO  - save everything at the end
%      - detect when object is cutoff
%      - detect when part transition happens



%% USER OPTIONS

scene_name = 'SN208_Density_2by2_same_chair'; %make this = 'all' to run all scenes
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


label_name = 'all';%make this 'all' to do it for all labels, 'bigBIRD' to do bigBIRD stuff
use_custom_labels = 0;
custom_labels = {};

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


  %get image structs, image_names, and make a map
  image_structs_file = load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  temp = cell2mat(image_structs_file.image_structs);
  all_image_names = {temp.image_name};
  camera_structs_map = containers.Map(all_image_names, image_structs_file.image_structs); 



  %load all the annotations for each image, and make a map,
  all_annotations = cell(1,length(all_image_names));
  for j=1:length(all_image_names)
    cur_image_name = all_image_names{j};
    %get name of annotatinos file 
    cur_mat_name = strcat(cur_image_name(1:10), '.mat');

    all_annotations{j} = load(fullfile(scene_path,LABELING_DIR, ...
                            BBOXES_BY_IMAGE_INSTANCE_DIR, cur_mat_name));
  end%for j, each image name

  annotations_map = containers.Map(all_image_names, all_annotations);



  %get map from label to all image names that see it 
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



  %% for label, propogate it throughout the scene
  for j=1:length(all_labels)
    cur_label_name = all_labels{j};

    cur_label_structs  = cell2mat(label_to_images_that_see_it_map(cur_label_name));
    cur_labels_image_names = {cur_label_structs.image_name};

    %for each image, if it is not labeled, label it
    for k=1:length(cur_labels_image_names)

      %get the current name and image struct
      cur_image_name = cur_labels_image_names{k};
      cur_image_struct = image_structs_map(cur_image_name);

      %get the annotations for this image
      cur_annotations = annotations_map(cur_image_name);
 
      %if this image is already annotated skip it 
      if(struct_has_bbox(cur_annotations,cur_label_name))
        continue;
      end 
     
      %%get the annotations for the closest labeled image backwards and forwards
      [backward_image_struct, backward_bbox] = get_next_labeled_image(cur_image_name, ...
                                                                    image_structs_map, ...
                                                                    annotations_map, ...
                                                                    cur_label_name, ...
                                                                    'backward');
      
      [forward_image_struct, forward_bbox] = get_next_labeled_image(cur_image_name, ...
                                                                    image_structs_map, ...
                                                                    annotations_map, ...
                                                                    cur_label_name, ...
                                                                    'forward');



      %make sure we got valid annotations
      skip = 0;
      if(isempty(backward_bbox))
        disp(strcat('must label ', backward_image_struct.image_name, ' for ', cur_label_name));
        skip =1;
      end
      if(isempty(forward_bbox))
        disp(strcat('must label ', forward_image_struct.image_name, ' for ', cur_label_name));
        skip =1;
      end

      %if we can not interpolate for this image
      if(skip)
        continue;
      end


      %%interpolate a box for the current image from the forward and backward images
      
      %get the distance from the current image to the forward and backward images
      backward_dist = distance_between_structs(cur_image_struct, backward_image_struct);
      forward_dist = distance_between_structs(cur_image_struct, forward_image_struct);

      %do the interpolation
      total_dist = backward_dist + forward_dist;
      diff_bbox = double(forward_bbox - backward_bbox);  
      cur_bbox =int64( double(forward_bbox) - forward_dist*(diff_bbox/total_dist)); 

      %set the interpolated box to this images annotation struct
      cur_annotations.(cur_label_name) = cur_bbox;
  
      %save the annotation struct for this image
      save(fullfile(scene_path,LABELING_DIR, BBOXES_BY_IMAGE_INSTANCE_DIR,...
                             strcat(cur_image_name(1:10),'.mat')), '-struct', 'cur_annotations');
 
    end%for k, each image_name
  end%for j, each labelname
end%for each scene




