%this script plots detection scores for one instance in a scene againts 
%variation in viewpoint of the instance, and distance from the camera
%to the instance


clearvars , close all;
init;



%the scene and instance we are interested in
scene_name = 'SN208';
recognition_system_name = 'fast-rcnn';
font_size = 10;

%any of the fast-rcnn categories
category_name = 'all'; %make this 'all' to see all categories

score_threshold = .001;

scene_path = fullfile(BASE_PATH,scene_name);


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
    
    
    num_boxes_diff = cell(0);
    num_boxes = cell(0);
    
    
    
    for j=1:length(structs)
        
        cur_struct = structs(j);
        if(cur_struct.translate_forward == -1)
            continue;
        end
        rec_name = strcat(cur_struct.image_name(1:10),'.mat');   
        cur_rec= load(fullfile(scene_path,RECOGNITION_DIR,recognition_system_name,rec_name));
        cur_rec = cur_rec.dets;   
        
        forward_name = strcat(cur_struct.translate_forward(1:10),'.mat');
        forward_rec= load(fullfile(scene_path,RECOGNITION_DIR,recognition_system_name,forward_name));
        forward_rec = forward_rec.dets;
        
        
     
        
            
        if(strcmp(category_name, 'all'))
            cur_rec = cell2mat(struct2cell(cur_rec));
            forward_rec = cell2mat(struct2cell(forward_rec));

        else
            cur_rec = cur_rec.(category_name);
            forward_rec = forward_rec.(category_name);

        end

            
            
        cur_rec = cur_rec(cur_rec(:,5)>score_threshold,:);
        forward_rec= forward_rec(forward_rec(:,5)>score_threshold,:);

        cur_num= size(cur_rec,1);
        forward_num= size(forward_rec,1);
  
            
        num_boxes{end+1} = cur_num;

        num_boxes_diff{end+1} = abs(cur_num - forward_num);

        
       
    end% for j, each point
    
    num_boxes = cell2mat(num_boxes);
    num_boxes_diff = cell2mat(num_boxes_diff);
    

    
end  
    
    