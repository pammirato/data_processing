%shows bounding boxes by image, with many options.  Can view vatic outputted boxes,
%results from a recognition system, or both. Also allows changing of vatic boxes. 

%TODO  - add scores to rec bboxes
%      - add labels to rec bboxes
%      - move picking labels to show outside of loop

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Kitchen_Living_03_1'; %make this = 'all' to run all scenes
group_name = 'all_minus_boring';
model_number = '0';
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



%load mapping from bigbird name ot category id
bb_cat_map = containers.Map();
fid_bb_map = fopen('/playpen/ammirato/Data/RohitMetaMetaData/big_bird_cat_map.txt', 'rt');

line = fgetl(fid_bb_map);
while(ischar(line))
  line = strsplit(line);
  bb_cat_map(line{1}) = str2double(line{2}); 
  line = fgetl(fid_bb_map);
end
fclose(fid_bb_map);






%% MAIN LOOP

for i=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{i};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  


  image_structs_file =  load(fullfile(meta_path,'reconstruction_results', group_name, ...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  image_structs = nestedSortStruct2(image_structs, 'image_name');
  scale  = image_structs_file.scale;


  %get a list of all the image file names
  %temp = cell2mat(image_structs);
  %image_names = {temp.(IMAGE_NAME)};
  image_names = {image_structs.(IMAGE_NAME)};

  %make a map from image name to image_struct
  %image_structs_map = containers.Map(image_names, image_structs);


  image_structs_map = containers.Map(image_names,...
                                 cell(1,length(image_names)));

  for jl=1:length(image_names)
    image_structs_map(image_names{jl}) = image_structs(jl);
  end









  for jl=1:length(image_names) 

    cur_image_name = image_names{jl};


    
    vatic_bboxes = load(fullfile(meta_path,LABELING_DIR, ...
                         'instance_label_structs', strcat(cur_image_name(1:10),'.mat')));


    fid_text_boxes = fopen(fullfile(meta_path, 'labels', 'wei_label_files', ...
                        strcat(cur_image_name(1:10),'.txt')), 'wt'); 

    fieldnames = fields(vatic_bboxes);

    writes = 0;

    for kl=1:length(fieldnames)
      if(strcmp(fieldnames{kl}, 'coca_cola_glass_bottle'))
        continue;
      end 

      bbox = double(vatic_bboxes.(fieldnames{kl}));
      if(isempty(bbox))
        continue;
      end 


      cat_id = bb_cat_map(fieldnames{kl});

      fprintf(fid_text_boxes, '%d %d %d %d %d\n', cat_id, bbox(1), bbox(2), bbox(3), bbox(4));
      writes = writes + 1;;
    end%for kl


    fclose(fid_text_boxes);

    if(writes == 0)
      delete(fullfile(meta_path, 'labels', 'wei_label_files', ...
                        strcat(cur_image_name(1:10),'.txt'))); 

    end

  end %for jl, each image name
end%for each scene


