function [] = add_field_to_image_structs(new_field, initial_value,scene_name)
%adds new field to all image structs in all scenes
%with the given initial value
%
% option scene_name argument to specify one scene

%TODO  - make sure the new_field doesn't already exist
%      - add a remove field feature
%      - TEST


  init;



  %get the names of all the scenes
  d = dir(ROHIT_BASE_PATH);
  d = d(3:end);

  all_scenes = {d.name};
  
  if(exist(scene_name))
    all_scenes = {scene_name};
  end

  for il=1:length(all_scenes)
    %get scene info 
    scene_name = all_scenes{il};
    scene_path =fullfile(ROHIT_BASE_PATH, scene_name);



    %load all the image_structs for this scene
    image_structs_file =  load(fullfile(meta_path, 'reconstruction_results', ... 
                                'colmap_results', ... 
                                '0', IMAGE_STRUCTS_FILE));

    image_structs = image_structs_file.(IMAGE_STRUCTS);
    scale  = image_structs_file.scale;

    %% add the field to each struct
    for jl=1:length(image_structs)
          
      cur_struct = image_structs(jl);
  
      cur_struct.(new_field) = initial_value;       

      image_structs(j) = cur_struct;
    end%for j, each struct
      
      
      save(fullfile(scene_path,IMAGE_STRUCTS_FILE), IMAGE_STRUCTS, SCALE);

                           
  end % for i, scenes                     
                           
end%function                         
                         
