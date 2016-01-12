%allows

init;


scene_name = 'Room15'


instance_name = 'bottle1';
%any of the fast-rcnn categories
category_name = 'bottle'; %usually the only difference is this has no index


eval(['depth_images = depth_images_' scene_name]);


scene_path = fullfile(BASE_PATH,scene_name);


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


for i=1:length(image_names)
    
    cur_rgb_name = image_names{i};
    
    cur_ls = label_structs{i};
    
    %this point must have depth for inverse projection
    if(cur_ls.(DEPTH) == 0)
        continue;
    end
    
    imshow(fullfile(scene_path, RGB_IMAGES_DIR, cur_rgb_name));
    hold on;
    plot(cur_ls.(X), cur_ls.(Y), 'r.', 'MarkerSize', 40);
    
    [x y but] = ginput(1);
    
    %right click to chose current image as view 0
    if(but ~=1)
        
        view_zero_struct = cur_ls;
        
        save(fullfile(scene_path,LABELING_DIR, DATA_FOR_LABELING_DIR, ...
                        LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE))
        
    end%if but
    
    
end%for i in image_names
