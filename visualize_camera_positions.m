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
    camera_data_map = load(fullfile(BASE_PATH, scene_name, RECONSTRUCTION_DIR, NAME_TO_POS_DIRS_MAT_FILE));
    camera_data_map = camera_data_map.NAMES_TO_POS_DIRS;



    %get all the camera_data, gives only a 1D matrix :(
    values = cell2mat(camera_data_map.values);

    %each image has a data vector 6 long, so index every 6

    %plot the camera positions
    plot3(values(1:6:end-5), values(2:6:end-4), values(3:6:end-3), '.r');
    axis equal;

    %draw the lines indicating orientations
    if(view_orientation)
        hold on;
        
        %DIR_X,_Y,_Z coordinates are just a point along the direction line
        quiver3(values(1:6:end-5), values(2:6:end-4), values(3:6:end-3), ...
                values(4:6:end-2), values(5:6:end-1), values(6:6:end), 'ShowArrowHead','off','Color' ,'b');
        hold off;
    end

end%for each scene


