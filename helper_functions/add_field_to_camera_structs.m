function [] = add_field_to_image_structs(new_field, inital_value)

%TODO  - make sure the new_field doesn't already exist
%      - add a remove field feature
%      - TEST

%adds new field to all image structs in all scenes
%with the given initial value

  init;



  %get the names of all the scenes
  d = dir(ROHIT_BASE_PATH);
  d = d(3:end);

  all_scenes = {d.name};

  for i=1:length(all_scenes)
    %get scene info 
    scene_name = d(i).name();
    scene_path =fullfile(ROHIT_BASE_PATH, scene_name);



    %load all the image_structs for this scene
    image_structs_file =  load(fullfile(scene_path,IMAGE_STRUCTS_FILE));
    image_structs = image_structs_file.(IMAGE_STRUCTS);
    scale  = image_structs_file.scale;

    %% add the field to each struct
    for j=1:length(image_structs)
          
      cur_struct = image_structs{j};
  
      cur_struct.(new_field) = intial_value;       

      image_structs{j} = cur_struct;
    end%for j, each struct
      
      
      save(fullfile(scene_path,IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE);

                           
  end % for i, scenes                     
                           
end%function                         
                         
