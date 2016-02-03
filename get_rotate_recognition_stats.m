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

score_threshold = .1;

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
    
    
    %only use the images from one kinect, K1
    k1_structs = structs(find(image_names(:,8)=='1'));
    structs = k1_structs;
    
    %get the number of clusters
    max_cluster_id = max([structs.cluster_id]);
    
    num_boxes_diff = -ones(2,max_cluster_id);
    num_boxes = -ones(2,max_cluster_id);
    
    
    %for each cluster
    for j=1:max_cluster_id

        %get all the structs for this cluster
        cur_cluster = structs(find([structs.cluster_id] == j));
        
        if(length(cur_cluster) == 0)
            continue;
        end
        
        
        rec_mats = cell(1,length(cur_cluster));
        nbd_cluster = -ones(1,length(cur_cluster));
        nb_cluster = -ones(1,length(cur_cluster));
        
        
        %make a map from image names to recogintion output
        image_names = {cur_cluster.image_name};
        rec_map = containers.Map(image_names, cell(1,length(image_names)));
        
        
        %for each point in the cluster
        for k=1:length(cur_cluster)
            cur_struct = cur_cluster(k);
            
            %get cur point recognition output
            rec_mat = rec_map(cur_struct.image_name);
            if(isempty(rec_mat))
                rec_name = strcat(cur_struct.image_name(1:10),'.mat');   
                rec_mat = load(fullfile(scene_path,RECOGNITION_DIR,recognition_system_name,rec_name));
                rec_mat = rec_mat.dets;
                rec_map(cur_struct.image_name) = rec_mat;
            end
            
            
            %now get rec output from point rotated ccw
            ccw_struct = structs_map(cur_struct.rotate_ccw);      
            ccw_rec = rec_map(ccw_struct.image_name);
            if(isempty(ccw_rec))
                rec_name = strcat(ccw_struct.image_name(1:10),'.mat');   
                ccw_rec = load(fullfile(scene_path,RECOGNITION_DIR,recognition_system_name,rec_name));
                ccw_rec = ccw_rec.dets;
                rec_map(ccw_struct.image_name) = ccw_rec;
            end
            
            
            % now get rec output from point rotated cw
%             clock_struct = structs_map(cur_struct.rotate_cw);      
%             clock_rec = rec_map(clock_struct.image_name);
%             if(isempty(clock_rec))
%                 rec_name = strcat(clock_struct.image_name(1:10),'.mat');   
%                 clock_rec = load(fullfile(scene_path,RECOGNITION_DIR,recognition_system_name,rec_name));
%                 clock_rec = clock_rec.dets;
%                 rec_map(clock_struct.image_name) = clock_rec;
%             end
            

            %only use the specified category
            if(strcmp(category_name, 'all'))
                rec_mat = cell2mat(struct2cell(rec_mat));
                ccw_rec = cell2mat(struct2cell(ccw_rec));
                
            else
                rec_mat = rec_mat.(category_name);
                ccw_rec = ccw_rec.(category_name);
                
            end
            
            
            %threshold the boxes
            rec_mat = rec_mat(rec_mat(:,5)>score_threshold,:);
            ccw_rec= ccw_rec(ccw_rec(:,5)>score_threshold,:);
            
            
            %get the number of boxes
            cur_num= size(rec_mat,1);
            ccw_num= size(ccw_rec,1);
%             clock_num= size(cell2mat(struct2cell(clock_rec)),1);
            
            
            
            
            
            
            
            nb_cluster(k) = cur_num;
            
            nbd_cluster(1,k) = abs(cur_num - ccw_num);
%             num_boxes_diff(2,k) = cur_num - clock_num;
            

            
            
            
            
            
        end%for k, each point in cluster
        
        
        %take the average difference for each cluster
        num_boxes_diff(1,j) = mean(nbd_cluster);
        num_boxes_diff(2,j) = std(nbd_cluster);
        
        
        %get average total for each point in each cluster
        num_boxes(1,j) = mean(nb_cluster);
        num_boxes(2,j) = std(nb_cluster);
        
        
       
    end% for j, each cluster
    
    
    
end  
    
    
