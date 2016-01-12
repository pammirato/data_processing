
clear all, close all;
%initialize contants, paths and file names, etc. 
init;


scene_name = 'Room15';  %make this = 'all' to run all scenes

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
    
    
   
    
    d = dir(fullfile(scene_path,RECOGNITION_DIR,FAST_RCNN_DIR));
    d = d(3:end);
    
    old_names = {d.name};

    name_map = load(fullfile(scene_path,'name_map.mat'));
    name_map = name_map.name_map;
    
    keys = name_map.keys;
    values = name_map.values;
    
    name_map = containers.Map(values,keys);
    
    for j=1:length(old_names)
       
        old_name = old_names{j};
        
        
        new_name = name_map(strcat(old_name(1:end-3),'png'));
        
        new_name = strcat(new_name(1:end-3),'mat');
        
        movefile(fullfile(scene_path,RECOGNITION_DIR,FAST_RCNN_DIR,old_names{j}), ...
                 fullfile(scene_path,RECOGNITION_DIR,FAST_RCNN_DIR, new_name));
    
    end
    
    
    
    %save(fullfile(scene_path, RECONSTRUCTION_DIR, NEW_POINT_2D_STRUCTS_FILE),POINT_2D_STRUCTS);
    
end