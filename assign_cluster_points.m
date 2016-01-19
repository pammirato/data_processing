%show a figure with the camera positions plotted in 3D for a scene, 
%possible also show a line coming from each point indicating the 
%orientation of the camera at that point

%initialize contants, paths and file names, etc. 
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
    camera_structs = cell2mat(camera_structs_file.(CAMERA_STRUCTS));
    scale  = camera_structs_file.scale;

    image_names = {camera_structs.image_name};
    image_names = cell2mat(image_names');
    
    
    
    k1_structs = camera_structs(find(image_names(:,8)=='1'));
    
    
    k1_world_pos = cell2mat({k1_structs.world_pos});
   
    %plot3(k1_world_pos(1,:),k1_world_pos(2,:),k1_world_pos(3,:),'r.');
    plot(k1_world_pos(1,:),k1_world_pos(3,:),'r.');
    axis equal;
    
    
    but = 1;
    boxes = cell(0);
    while(but ==1)     
    
        [xi, yi, but] = ginput(2);
        but = min(but);
        
        if(but ~= 1)
            break;
        end


        boxes{end+1} = [xi(1), yi(1), xi(2), yi(2)];
    end
    
    
    
    colors = zeros(3,length(boxes));
    for j=1:length(boxes)
        
        colors(:,j) = rand(3,1);
    end%for j
    
   %% 
    structs_map = containers.Map({camera_structs.image_name},camera_structs_file.(CAMERA_STRUCTS));
    
    
    hold on;
    
    k2_structs = camera_structs(find(image_names(:,8)=='2'));
    k3_structs = camera_structs(find(image_names(:,8)=='3'));
    
    camera_structs = camera_structs_file.(CAMERA_STRUCTS);
    k1_structs = camera_structs(find(image_names(:,8)=='1'));
   % k1_structs = mat2cell(k1_structs,size(k1_structs));
    for j=1:length(k1_structs)
        
       cur_struct = k1_structs{j};
       cur_point = cur_struct.world_pos;
       cp = [cur_point(1),cur_point(3)];
        
        
       cluster_id = -1;
       
       counter = 1;
       while(cluster_id==-1 && counter <= length(boxes))
           cb = boxes{counter};
           
           %see if the point is in the box
           if(cp(1) > cb(1) && cp(1) < cb(3))
               if(cp(2)>cb(4) && cp(2) < cb(2))
                   cluster_id = counter;
               end
           end
           counter = counter +1;
       end%while
       
       if(cluster_id ~= -1)
           plot(cp(1),cp(2),'.','Color',colors(:,cluster_id));

           cur_struct.cluster_id = cluster_id;
           k1_structs{j} = cur_struct;
           
           name = cur_struct.image_name;
           
           k2_name  = name;
           k2_name(8)= '2';
           
           k3_name  = name;
           k3_name(8)= '3';
           
           
           structs_map(name) = cur_struct;
           
           try
                k2_struct = structs_map(k2_name);
                k2_struct.cluster_id = cluster_id;
                structs_map(k2_name) = k2_struct;
           catch
           end
           
           try
                k3_struct = structs_map(k3_name);
                k3_struct.cluster_id = cluster_id;
                structs_map(k3_name) = k3_struct;
           catch
           end
           
       end
        
    end %for j
    

    hold off;
    
    
    
    camera_structs = structs_map.values;
    
    

    
    save(fullfile(scene_path, RECONSTRUCTION_DIR, NEW_CAMERA_STRUCTS_FILE), CAMERA_STRUCTS, SCALE);

    
    %rectangle('Position',[bbox(1) bbox(2) abs(bbox(3)-bbox(1)) abs(bbox(4)-bbox(2))], 'LineWidth',2, 'EdgeColor','b');
end%for each scene


