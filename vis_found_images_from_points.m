%this script plots detection scores for one instance in a scene againts 
%variation in viewpoint of the instance, and distance from the camera
%to the instance

%        clearvars -except 'depth_images_*', close all;
init;

density = 1;

%the scene and instance we are interested in
scene_name = 'SN208';
instance_name = 'chair4';


scene_path = fullfile(BASE_PATH,scene_name);
if(density)
    scene_path =fullfile('/home/ammirato/Data/Density', scene_name);
end


%get the map to find all the interesting images
label_to_images_that_see_it_map = load(fullfile(scene_path,LABELING_DIR,...
                                    DATA_FOR_LABELING_DIR, ...
                                    LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE));
 
label_to_images_that_see_it_map = label_to_images_that_see_it_map.(LABEL_TO_IMAGES_THAT_SEE_IT_MAP);
             
             
             
%get the structs with IMAGE_NAME, X, Y, DEPTH for images that see this
%instance
label_structs = label_to_images_that_see_it_map(instance_name);

%get all the image names
temp = cell2mat(label_structs);
image_names = {temp.(IMAGE_NAME)};
clear temp;



%load data about psition of each image in this scene
camera_structs_file =  load(fullfile(scene_path,RECONSTRUCTION_DIR,NEW_CAMERA_STRUCTS_FILE));
camera_structs = camera_structs_file.(CAMERA_STRUCTS);
camera_structscale  = camera_structs_file.scale;

%get a list of all the image file names in the entire scene
temp = cell2mat(camera_structs);
all_image_names = {temp.(IMAGE_NAME)};
clear temp;

%make a map from image name to camera_struct
camera_structs_map = containers.Map(all_image_names, camera_structs);
clear all_image_names;




%for each image, get its best detection for this instance
for i=1:length(image_names)
    %figure;
    imshow(fullfile(scene_path, RGB_IMAGES_DIR, image_names{i}));
    
    name = image_names{i};
    dimg = imread(fullfile(scene_path,RAW_DEPTH_IMAGES_DIR,strcat(name(1:8),'03.png')));
    
    hold on;
    h = imagesc(dimg);
    set(h,'AlphaData',.5);


    ls = label_structs{i};
    hold on;
    plot(ls.(X), ls.(Y),'r.','MarkerSize',40);
    hold off;

    cur_name = image_names{i};
    %title(cur_name);
    title(num2str(ls.depth));
    
    ginput(1);
    
end%for i in image_names












