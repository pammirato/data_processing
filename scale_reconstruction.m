


init;




density  = 1;
density_res = 100;


scene_name = 'SN208_3'; %make this = 'all' to run all scenes

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
        
        camera_structs_file =  load(fullfile(scene_path,RECONSTRUCTION_DIR,NEW_CAMERA_STRUCTS_FILE));
        camera_structs = cell2mat(camera_structs_file.(CAMERA_STRUCTS));
        scale  = camera_structs_file.scale;

        image_names = {camera_structs.image_name};
        %image_names = cell2mat(image_names');
        structs_map = containers.Map({camera_structs.image_name},camera_structs_file.(CAMERA_STRUCTS));

    
        cluster_ids= [camera_structs.cluster_id];
        first_col = camera_structs(cluster_ids < 11);
        
        
        dists = zeros(1,9);
        
        
        prev_pos = first_col(1).world_pos;
        
        for j=2:size(first_col,2)
            
            cur_pos = first_col(j).world_pos;
            
            dists(j-1) = cur_pos(3) - prev_pos(3);
            
            prev_pos = cur_pos;
            
        end%for j, each position in first col
        
        
        mean_dist = mean(dists);
        
        scale = density_res/mean_dist; 
        
        
        
        
        
        
        
        %% apply scale
        
        for j=1:length(image_names)
            cur_name = image_names{j};
            
            cur_struct = structs_map(cur_name);
            
            cur_struct.scaled_world_pos = cur_struct.world_pos * scale;
            
            structs_map(cur_name) = cur_struct;
            
        end
        
        
        
    else %not denstiy

    %% sdf
    
    
    
    
    
    
    
    
    
    



        %load a map from image name to camera data
        %camera data is an arraywith the camera position and a point along is orientation vector
        % [CAM_X CAM_Y CAM_Z DIR_X DIR_Y DIR_Z]

        if(~exist('camera_structs','var'))
            camera_structs_file =  load(fullfile(scene_path,RECONSTRUCTION_DIR,NEW_CAMERA_STRUCTS_FILE));
            camera_structs = camera_structs_file.(CAMERA_STRUCTS);
        end

        temp = cell2mat(camera_structs);
        image_ids = {temp.image_id};
        camera_structs_map = containers.Map(image_ids,camera_structs);
        clearvars temp;

        if(~exist('point2D_structs','var'))
            point2D_structs_file = load(fullfile(scene_path,RECONSTRUCTION_DIR,'point_2d_structs.mat'));
            point2D_structs = cell2mat(point2D_structs_file.point_2d_structs);
        end

        image_names = {point2D_structs.image_name};
        p2d = {point2D_structs.points_2d};
        p2d_map = containers.Map(image_names,p2d);



        if(~exist('points3D','var'))
            points3D = load(fullfile(scene_path,RECONSTRUCTION_DIR,'points3D.mat'));
            points3d = points3D.points3d;
            points3D  = nestedSortStruct(points3d,'error');
        end

       %only consider points that have been seen by a bunch of images

       num_images_thresh = 100;
       error = 0;
       prev_point = -1;
       point = -1;
       while(error < 1)


        p3index = [points3D.num_image_ids];
        b = find(p3index > num_images_thresh);
        seen_points = points3D(b);
        if(length(seen_points) < 1)
            break;
        end

        prev_point = point;
        point = seen_points(1);

        error = point.error;
        num_images_thresh = num_images_thresh + 100;
       end


        image_ids = point.image_ids;
        point2_ids = point.point2_ids;



        depths = -ones(1,length(image_ids));
        dists = -ones(1,length(image_ids));
        ydists = -ones(1,length(image_ids));

        for j=1:length(image_ids)

            cur_image_id = image_ids(j);
            cur_p2_id = point2_ids(j);
            camera_struct = camera_structs_map(num2str(cur_image_id));
            p2d = p2d_map(camera_struct.image_name);

            xs = p2d(1:3:end);
            ys = p2d(2:3:end);
            p3ids = p2d(3:3:end);


            p3index = find(p3ids == point.id);
            p3index = p3index(1);
            p3id=  p3ids(p3index);

            x = max(1,floor(xs(p3index)));
            y = max(1,floor(ys(p3index)));

            depth_img = imread(fullfile(scene_path,'raw_depth', ...
                            strcat(camera_struct.image_name(1:8),'03.png')));


            depths(j) = depth_img(y,x);


            cam_pos = camera_struct.world_pos;

            dists(j) = sqrt( (cam_pos(1)-point.x)^2 + (cam_pos(2)-point.y)^2 + (cam_pos(3)-point.z)^2 );

            ydists(j) = point.y- cam_pos(2);
        end


        scales = depths./dists;
        temp = find(scales);
        scales = scales(temp);

        scale = mean(scales);


        for j=1:length(camera_structs)
            cur_struct = camera_structs{j};

            t = cur_struct.(TRANSLATION_VECTOR);
            R = cur_struct.(ROTATION_MATRIX);

            t = t*scale;

            cur_struct.(SCALED_WORLD_POSITION) = (-R' *t);

            camera_structs{j} = cur_struct;

        end%for j
    end
    
    camera_structs = structs_map.values;
    
    save(fullfile(scene_path, RECONSTRUCTION_DIR, NEW_CAMERA_STRUCTS_FILE), CAMERA_STRUCTS, SCALE);
    
end