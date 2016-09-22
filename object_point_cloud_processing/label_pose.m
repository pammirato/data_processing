%saves a map from a label (instance) name, to names of all images that 'see'
% any of the reconstructed points on the object


clearvars;

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Bedroom_01_1'; %make this = 'all' to run all scenes
group_name = 'all';
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 


label_to_process = 'all'; %make 'all' for every label
label_names = {label_to_process};



do_occlusion_filtering = 1;
occlusion_threshold = 150;  %make > 12000 to remove occlusion thresholding 



debug =1;

kinect_to_use = 1;

%size of rgb image in pixels
kImageWidth = 1920;
kImageHeight = 1080;



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


  if(strcmp(label_to_process, 'all'))
    label_names = get_names_of_X_for_scene(scene_name, 'instance_labels');
  end





  %get info about camera position for each image
  %image_structs_file =  load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results', group_name, ...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;



  blank_struct = struct();
  blank_struct.image_name = '';
  for jl=1:length(label_names)
    blank_struct.(label_names{jl}) = []; 
  end


  label_structs = repmat(blank_struct, length(image_structs), 1);


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



  %% MAIN LOOP

  %for each point cloud
  for jl=1:length(label_names)
    

    cur_label_name = label_names{jl};


    %for each image, determine if it 'sees' this object(point cloud) 
    for kl = 1:length(image_names) 

      cur_image_name = image_names{kl};
      cur_image_struct = image_structs_map(cur_image_name);


      
      img = imread(fullfile(scene_path, 'rgb', cur_image_name));

      bboxes = load(fullfile(meta_path,LABELING_DIR, ...
                           'instance_label_structs', strcat(cur_image_name(1:10),'.mat')));

      cur_bbox = bboxes.(cur_label_name);

      if(isempty(cur_bbox))
        continue;
      end

      imshow(img);
      hold on;
      rectangle('position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], ...
                     'linewidth',2, 'edgecolor','r');

      title(cur_label_name);



      [x,y,but] = ginput(1);

      if(but == 1)
        continue;
      end












      cur_struct = label_structs(kl); 

      if(~strcmp(cur_struct.image_name, ''))
        assert(strcmp(cur_struct.image_name, cur_image_name));
      else
        cur_struct.image_name = cur_image_name;
      end

      cur_struct.(cur_label_name) = [pose_angle];
      
      label_structs(kl) = cur_struct;

      %show some visualization of the found points if debug option is set 
      if(debug)  
        %read in the rgb image
        img = imread(fullfile(scene_path, 'rgb', cur_image_name));
 
        ginput(1);
      end % if debug
    end%for k, each image name


   end%for jl, each label 



   for jl=1:length(label_structs)
     cur_struct = label_structs(jl);

     if(strcmp(cur_struct.image_name, ''))
       cur_struct.image_name = image_names{jl};
     end

     cur_image_name = cur_struct.image_name;
     rmfield(cur_struct,'image_name');

     save(fullfile(meta_path, 'labels', 'pose_label_structs', ...
                    strcat(cur_image_name(1:10), '.mat')), '-struct', 'cur_struct'); 

   end%for jl, each label struct

end%for i, each scene_name

