
%initialize contants, paths and file names, etc. 
clear;
init;



scene_name = 'FB209_2'; %make this = 'all' to run all scenes

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
    
    
    max_cluster_id = max([structs.cluster_id]);
    
    rep_cluster_structs = cell(1,max_cluster_id);
    %find average cluster points
    for j=1:max_cluster_id
        cur_cluster = structs(find([structs.cluster_id] == j));
        
        rep_cluster_structs{j} = cur_cluster(1);
        
        
    end%for j each cluster
    
    
    clusters_left = -ones(1,max_cluster_id);
    clusters_right = -ones(1,max_cluster_id);
    clusters_forward = -ones(1,max_cluster_id);
    clusters_back = -ones(1,max_cluster_id);
    
    figure; 
    hold on;
    
    for j=1:max_cluster_id
        cur_cluster = structs(find([structs.cluster_id] == j));
        
        cur_rep_struct = rep_cluster_structs{j};
        cws = cur_rep_struct.scaled_world_pos;
        od = cur_rep_struct.direction * 1000;
        
        plot(cws(1),cws(3),'r.','MarkerSize',10);
        quiver(cws(1),cws(3),od(1),od(3),'ShowArrowHead','off','Color' ,'b');
        
    end%for j, each cluster
    
    
    
    
    breakp = 1;
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    for j=1:max_cluster_id

        cur_cluster = structs(find([structs.cluster_id] == j));
       
        for k=1:length(cur_cluster)
            cur_struct = cur_cluster(k);
            
            cur_world = cur_struct.world_pos;
            cur_dir = cur_struct.direction;
            
            cdv = [cur_dir(1),cur_dir(3)]; 
            cdv = cdv/norm(cdv);
            
            other_structs = cur_cluster;
            other_structs(k) = [];
            
            rl_name = '';
            rr_name = '';
            rl_angle = 360;
            rr_angle = 360;
            for l=1:length(other_structs)
                o_struct = other_structs(l);
                o_world = o_struct.world_pos;
                o_dir = o_struct.direction;
                odv = [o_dir(1),o_dir(3)];
                
                odv = odv/norm(odv);
                
                dotp = cur_dir(1)*-o_dir(3) + cur_dir(3)*o_dir(1);
                
%                 plot(cur_world(1),cur_world(3),'r.');
%                 hold on;
%                 plot(cur_dir(1),cur_dir(3),'b.');
%                 plot(o_world(1),o_world(3),'k.');
%                 plot(o_dir(1),o_dir(3),'g.');
                angle = acosd(dot(cdv,odv));
                if(dotp > 0)
                    %console.log("b on the right of a")
                     
                     if(angle < rr_angle)
                         rr_angle = angle;
                         rr_name = o_struct.image_name;
                     end
                elseif(dotp < 0)
                     %console.log("b on the left of a")
                     
                    
                     if(angle < rl_angle)
                         rl_angle = angle;
                         rl_name = o_struct.image_name;
                     end
                   
                else
                    %console.log("b parallel/antiparallel to a")
                end
                
                
%                 hold off;
                
               
            
            end%for l, each other point in cluster
            
            cur_struct.rotate_ccw = rl_name;
            cur_struct.rotate_cw = rr_name;

            %cur_cluster(k) = cur_struct;
            
            
            name = cur_struct.image_name;

            k2_name  = name;
            k2_name(8)= '2';

            k3_name  = name;
            k3_name(8)= '3';


            

            
            %k2
            try
                k2_struct = structs_map(k2_name);
                    
                k2_rl_name =rl_name;
                k2_rl_name(8) = '2';
                k2_rr_name =rr_name;
                k2_rr_name(8) = '2';
                
                try
                    structs_map(k2_rl_name);
                    k2_struct.rotate_ccw = k2_rl_name;
                catch
                end
                try
                    structs_map(k2_rr_name);
                    k2_struct.rotate_cw = k2_rr_name;
                catch
                end
                structs_map(k2_name) = k2_struct;
            catch
            end

            
            %k3
            try
                k3_struct = structs_map(k3_name);
                k3_rl_name =rl_name;
                k3_rl_name(8) = '3';
                k3_rr_name =rr_name;
                k3_rr_name(8) = '3';
                
                try
                    structs_map(k3_rl_name);
                    k3_struct.rotate_ccw = k3_rl_name;
                catch
                end
                try
                    structs_map(k3_rr_name);
                    k3_struct.rotate_cw = k3_rr_name;
                catch
                end
                structs_map(k3_name) = k3_struct;
            catch
            end
            
            
            structs_map(name) = cur_struct;
            
        end%for k, each point
        
        %structs(find([structs.cluster_id] == j)) = cur_cluster;
    end%for j, each cluster
    
        
    camera_structs = structs_map.values;
    
    

    
    save(fullfile(scene_path, RECONSTRUCTION_DIR, NEW_CAMERA_STRUCTS_FILE), CAMERA_STRUCTS, SCALE);

end%for each scene


