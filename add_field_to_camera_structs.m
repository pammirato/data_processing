
init;


density = 1;
scene_name = 'FB209'; %make this = 'all' to run all scenes

%should the lines indicating orientation be drawn?
view_orientation = 1;


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
        scene_name = d(i).name();
    end

    scene_path =fullfile(BASE_PATH, scene_name);
    if(density)
        scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
    end


    %load a map from image name to camera data
    %camera data is an arraywith the camera position and a point along is orientation vector
    % [CAM_X CAM_Y CAM_Z DIR_X DIR_Y DIR_Z]
    camera_structs_file =  load(fullfile(scene_path,RECONSTRUCTION_DIR,NEW_CAMERA_STRUCTS_FILE));
    camera_structs = camera_structs_file.(CAMERA_STRUCTS);
    scale  = camera_structs_file.scale;

    for j=1:length(camera_structs)
        
        cs = camera_structs{j};

        new_struct = struct(IMAGE_NAME, cs.(IMAGE_NAME), TRANSLATION_VECTOR, cs.(TRANSLATION_VECTOR), ...
                         ROTATION_MATRIX, cs.(ROTATION_MATRIX), WORLD_POSITION, cs.(WORLD_POSITION), ...
                         DIRECTION, cs.(DIRECTION), QUATERNION, cs.(QUATERNION), ...
                         SCALED_WORLD_POSITION, cs.(SCALED_WORLD_POSITION), IMAGE_ID,cs.(IMAGE_ID), ...
                         CAMERA_ID, cs.(CAMERA_ID), 'cluster_id', -1,... %%%); % cs.cluster_id, ...
                         'rotate_ccw', -1,'rotate_cw',-1, ...
                         'translate_forward',-1,'translate_backward',-1, ...
                         'translate_up', -1, 'translate_down', -1);

        camera_structs{j} = new_struct;
    end
    
    
    save(fullfile(scene_path, RECONSTRUCTION_DIR, NEW_CAMERA_STRUCTS_FILE), CAMERA_STRUCTS, SCALE);

                         
                         
end % for i, scenes                     
                         
                         
                         
                         
                         
                         
                         
                         
                         
                         
                         