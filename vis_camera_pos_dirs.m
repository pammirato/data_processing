%show a figure with the camera positions plotted in 3D for a scene, 
%possible also show a line coming from each point indicating the 
%orientation of the camera at that point

%initialize contants, paths and file names, etc. 
init;


density = 1;
scene_name = 'FB209'; %make this = 'all' to run all scenes

%should the lines indicating orientation be drawn?
view_orientation = 0;


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
    figure;
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

    
    temp = cell2mat(camera_structs);
    a = {temp.scaled_world_pos};
    b =cell2mat(a);
    
    a = {temp.direction};
    c = cell2mat(a);
    
    %plot3(b(1,:),b(2,:),b(3,:),'r.','MarkerSize',20);
    plot(b(1,:),b(3,:),'r.','MarkerSize',20);
    
%                 text(bbox(1), bbox(2)-font_size,strcat(num2str(bbox(5)),cur_label),  ...
% % %                                     'FontSize',font_size, 'Color','white');
% % 
%     
    %get all the camera_data, gives only a 1D matrix :(
    %values = cell2mat(camera_data_map.values);

    %each image has a data vector 6 long, so index every 6

    %plot the camera positions
    %plot3(values(1:6:end-5), values(2:6:end-4), values(3:6:end-3), '.r');
    
    
    axis equal;

    %draw the lines indicating orientations
    if(view_orientation)
        hold on;
        
        %DIR_X,_Y,_Z coordinates are just a point along the direction line
        quiver3(b(1,:),b(2,:),b(3,:), ...
               c(1,:),c(2,:),c(3,:), 'ShowArrowHead','on','Color' ,'b');
        
        
        hold off;
    end

end%for each scene


