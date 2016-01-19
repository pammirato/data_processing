
%initialize contants, paths and file names, etc. 
clear;
init;



scene_name = 'SN208'; %make this = 'all' to run all scenes

dir_angle_thresh = 10;
move_angle_thresh = 30;
dist_thresh = 700;

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
    
    
    max_cluster_id = max([structs.cluster_id]);
    
    
    
    
    for j=1:max_cluster_id

        cur_cluster = structs(find([structs.cluster_id] == j));
        
        other_structs = structs(find([structs.cluster_id] ~= j));
       
        for k=1:length(cur_cluster)
            cur_struct = cur_cluster(k);
            
            cur_world = cur_struct.scaled_world_pos;
            cur_world = [cur_world(1), cur_world(3)];
            
            cur_dir = cur_struct.direction;
            
            cdv = [cur_dir(1),cur_dir(3)]; 
            cdv = cdv/norm(cdv);
            
            forward_angle = 0+move_angle_thresh;
            forward_name = -1;
            backward_angle = 180-move_angle_thresh;
            backward_name = -1;
            for l=1:length(other_structs)
                o_struct = other_structs(l);
                o_world = o_struct.scaled_world_pos;
                o_world = [o_world(1) o_world(3)];
                o_dir = o_struct.direction;
                
                odv = [o_dir(1),o_dir(3)];
                
                odv = odv/norm(odv);
                

                dir_angle = acosd(dot(cdv,odv));
                
                
                point_vec =o_world - cur_world;
                point_vec = point_vec/norm(point_vec);
                
                point_angle = acosd(dot(cdv,point_vec));
                
                distance = sqrt( sum((o_world - cur_world).^2) );
                
%                 back = 0;
%                 if(point_vec(3) < 0)
%                     back = 1;
%                 end
                
                
                if(dir_angle < dir_angle_thresh && distance<dist_thresh)
                    if(point_angle < forward_angle)
                        forward_angle = point_angle;
                        forward_name = o_struct.image_name;
                    end
                    if(point_angle > backward_angle)
                        backward_angle = point_angle;
                        backward_name = o_struct.image_name;
                    end
                    
                end
               
            
            end%for l, each other point in cluster
            
            
%             name = cur_struct.image_name;
% 
%             k2_name  = name;
%             k2_name(8)= '2';
% 
%             k3_name  = name;
%             k3_name(8)= '3';
% 
% 
%             
% 
%             
%             %k2
%             try
%                 k2_struct = structs_map(k2_name);
%                     
%                 k2_rl_name =rl_name;
%                 k2_rl_name(8) = '2';
%                 k2_rr_name =rr_name;
%                 k2_rr_name(8) = '2';
%                 
%                 try
%                     structs_map(k2_rl_name);
%                     k2_struct.rotate_ccw = k2_rl_name;
%                 catch
%                 end
%                 try
%                     structs_map(k2_rr_name);
%                     k2_struct.rotate_cw = k2_rr_name;
%                 catch
%                 end
%                 structs_map(k2_name) = k2_struct;
%             catch
%             end
% 
%             
%             %k3
%             try
%                 k3_struct = structs_map(k3_name);
%                 k3_rl_name =rl_name;
%                 k3_rl_name(8) = '3';
%                 k3_rr_name =rr_name;
%                 k3_rr_name(8) = '3';
%                 
%                 try
%                     structs_map(k3_rl_name);
%                     k3_struct.rotate_ccw = k3_rl_name;
%                 catch
%                 end
%                 try
%                     structs_map(k3_rr_name);
%                     k3_struct.rotate_cw = k3_rr_name;
%                 catch
%                 end
%                 structs_map(k3_name) = k3_struct;
%             catch
%             end
            
            cur_struct.translate_forward = forward_name;
            cur_struct.translate_backward = backward_name;
            
            structs_map(cur_struct.image_name) = cur_struct;
            
        end%for k, each point
        
        %structs(find([structs.cluster_id] == j)) = cur_cluster;
    end%for j, each cluster
    
        
    camera_structs = structs_map.values;
    
    

    
    save(fullfile(scene_path, RECONSTRUCTION_DIR, NEW_CAMERA_STRUCTS_FILE), CAMERA_STRUCTS, SCALE);

end%for each scene


