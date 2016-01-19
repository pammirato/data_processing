
%initialize contants, paths and file names, etc. 
clear;
init;



scene_name = 'SN208'; %make this = 'all' to run all scenes

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


    %load a map from image name to camera data
    %camera data is an arraywith the camera position and a point along is orientation vector
    % [CAM_X CAM_Y CAM_Z DIR_X DIR_Y DIR_Z]
    camera_structs_file =  load(fullfile(scene_path,RECONSTRUCTION_DIR,NEW_CAMERA_STRUCTS_FILE));
    structs = camera_structs_file.(CAMERA_STRUCTS);
    scale  = camera_structs_file.scale + 50;
    
    

    
    %sort the camera_structs based on cluster
    structs = cell2mat(structs);
    %[~,index] = sortrows([structs.cluster_id].'); structs = structs(index); clear index
    structs_map = containers.Map({structs.image_name},camera_structs_file.(CAMERA_STRUCTS));

    image_names = {structs.image_name};
    image_names = cell2mat(image_names');
    
    
    
    k1_structs = structs(find(image_names(:,8)=='1'));
    structs = k1_structs;
    
    
    for j=1:length(k1_structs)

        cur_struct = k1_structs(j);
        
        k1_name = cur_struct.image_name;
       
        
        k2_exists = 0;
        k3_exists = 0;

        k2_name  = k1_name;
        k2_name(8)= '2';

        k3_name  = k1_name;
        k3_name(8)= '3';





        %k2
        try
            k2_struct = structs_map(k2_name);
            k2_exists=1;
        catch
        end
        try
            k3_struct = structs_map(k3_name);
            k3_exists = 1;
        catch
        end

        if(k2_exists)
            cur_struct.translate_up = k2_name;
            k2_struct.translate_down = k1_name;
            
            if(k3_exists)
                k2_struct.translate_up = k3_name;
                k3_struct.translate_down = k2_name;
                structs_map(k3_name) = k3_struct;
            end
            structs_map(k2_name) = k2_struct;
        elseif(k3_exists)
            cur_struct.translate_up = k3_name;
            k3_struct.translate_down = k1_name;
            
            structs_map(k3_name) = k3_struct;
        end


        structs_map(k1_name) = cur_struct;
        
       
        
        
            
        %structs(find([structs.cluster_id] == j)) = cur_cluster;
    end%for j, each cluster
    
        
    camera_structs = structs_map.values;
    
    

    
    save(fullfile(scene_path, RECONSTRUCTION_DIR, NEW_CAMERA_STRUCTS_FILE), CAMERA_STRUCTS, SCALE);

end%for each scene


