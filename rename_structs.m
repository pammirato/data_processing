

%initialize contants, paths and file names, etc. 
clear;
init;


scene_name = 'FB209_2';  %make this = 'all' to run all scenes

%get the names of all the scenes
d = dir(BASE_PATH);
d = d(3:end);

%determine if just one or all scenes are being processed
if(strcmp(scene_name,'all'))
    num_scenes = length(d);
else
    num_scenes = 1;
end

for i=1:num_scenes
    
    %if we are processing all scenes
    if(num_scenes >1)
        scene_name = d(i).name()
    end

    scene_path =fullfile(BASE_PATH, scene_name);
    
    
   
    
    camera_structs = load(fullfile(scene_path, RECONSTRUCTION_DIR, CAMERA_STRUCTS_FILE));
    scale = camera_structs.scale;
    camera_structs = camera_structs.(CAMERA_STRUCTS);
    
%     point_2d_structs = load(fullfile(scene_path, RECONSTRUCTION_DIR, POINT_2D_STRUCTS_FILE));
%     point_2d_structs = point_2d_structs.(POINT_2D_STRUCTS);

    name_map = load(fullfile(scene_path,'name_map.mat'));
    name_map = name_map.name_map;
    
    keys = name_map.keys;
    values = name_map.values;
    
    name_map = containers.Map(values,keys);
    
    for j=1:length(camera_structs)
        
        cur_struct = camera_structs{j};
        
        new_name = name_map(cur_struct.(IMAGE_NAME));
        
        cur_struct.(IMAGE_NAME) = new_name;
        
        camera_structs{j} = cur_struct;
    
    end
    
    
    
    save(fullfile(scene_path, RECONSTRUCTION_DIR, NEW_CAMERA_STRUCTS_FILE),CAMERA_STRUCTS,'scale');
    
end