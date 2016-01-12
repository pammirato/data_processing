%this script plots detection scores for one instance in a scene againts 
%variation in viewpoint of the instance, and distance from the camera


clear;
init;



%the scene and instance we are interested in
scene_name = 'FB209_2';


label_name = 'hersheys_bar';  %make this 'all' to do it for all labels



label_box_size = 5;
max_image_dimension = 600;
crop_size = 500;
max_images_per_dir = 50;
min_images_per_dir = 20;


scene_path = fullfile(BASE_PATH,scene_name);


%get the map to find all the interesting images
label_to_images_that_see_it_map = load(fullfile(scene_path,LABELING_DIR,...
                                    DATA_FOR_LABELING_DIR, ...
                                    LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE));
 
label_to_images_that_see_it_map = label_to_images_that_see_it_map.(LABEL_TO_IMAGES_THAT_SEE_IT_MAP);
             
all_labels = label_to_images_that_see_it_map.keys;
      
num_labels = 1;
if(strcmp(label_name,'all'))
 num_labels = length(all_labels);
end


for i =1:num_labels

    if(num_labels > 1)
        label_name = all_labels{i}
    end
       



    %get the structs with IMAGE_NAME, X, Y, DEPTH for images that see this
    %instance
    label_structs = label_to_images_that_see_it_map(label_name);

    %get all the image names
    temp = cell2mat(label_structs);
    image_names = {temp.(IMAGE_NAME)};
    clear temp;



    % %load data about psition of each image in this scene
    % camera_structs_file =  load(fullfile(scene_path,RECONSTRUCTION_DIR,CAMERA_STRUCTS_FILE));
    % camera_structs = camera_structs_file.(CAMERA_STRUCTS);
    % camera_structscale  = camera_structs_file.scale;

    % %get a list of all the image file names in the entire scene
    % temp = cell2mat(camera_structs);
    % all_image_names = {temp.(IMAGE_NAME)};
    % clear temp;
    % 
    % %make a map from image name to camera_struct
    % camera_structs_map = containers.Map(all_image_names, camera_structs);
    % clear all_image_names;


    mkdir(fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, label_name));


    transform_structs = cell(1,length(image_names));
    
    %for each image
    for jj=1:length(image_names)
        %figure;
        png_name = image_names{jj};
        jpg_name = strcat(png_name(1:end-3),'jpg');

        %copyfile(fullfile(scene_path, JPG_RGB_IMAGES_DIR, jpg_name), ...
        %         fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, label_name,jpg_name) );


        if( ~ (exist(fullfile(scene_path, JPG_RGB_IMAGES_DIR, jpg_name),'file')==2))
            continue;
        end

        img = imread(fullfile(scene_path, JPG_RGB_IMAGES_DIR, jpg_name));

        ls = label_structs{jj};
        
        depth = ls.depth;
        
        crop_size = 400;
        if(depth >1000)
            crop_size = crop_size - crop_size*(1000/depth)/3;
        end


        %first draw the label dot
        x_dot_min = max(1,ls.(X) - label_box_size/2);
        x_dot_max = min(size(img,2),ls.(X) + label_box_size/2);
        y_dot_min = max(1,ls.(Y) - label_box_size/2);
        y_dot_max = min(size(img,1),ls.(Y) + label_box_size/2);


        temp =  img(y_dot_min:y_dot_max,x_dot_min:x_dot_max,1);
        img(y_dot_min:y_dot_max,x_dot_min:x_dot_max,1) = 255*ones(size(temp));
        img(y_dot_min:y_dot_max,x_dot_min:x_dot_max,2) = zeros(size(temp));
        img(y_dot_min:y_dot_max,x_dot_min:x_dot_max,3) = zeros(size(temp));

        %imshow(img);


        %now center the label
        display_image = uint8(255*ones(2*size(img,1),2*size(img,2),3));
        center_pos = [size(img,1), size(img,2)];

        label_pos = double([ls.y ls.x]);

        diff_pos = center_pos - label_pos ;

        start_row = 1+diff_pos(1);
        end_row = start_row+size(img,1)-1;
        start_col = 1+diff_pos(2);
        end_col = start_col+size(img,2)-1;


        display_image(start_row:end_row,start_col:end_col,:) = img;


        %now crop the image around the label
        y_crop_min = max(1,floor(start_row + label_pos(1) - (crop_size/2)));
        y_crop_max = min(size(display_image,1),floor(start_row + label_pos(1) + (crop_size/2)));

        x_crop_min = max(1,floor(start_col + label_pos(2) - (crop_size/2)));
        x_crop_max = min(size(display_image,2),floor(start_col + label_pos(2) + (crop_size/2)));


        crop_img = display_image(y_crop_min:y_crop_max,x_crop_min:x_crop_max,:);





        %now resize the image
        scale = max_image_dimension/max(size(crop_img));
        scale_img = imresize(crop_img,scale);

        %imshow(scale_img);

        imwrite(scale_img,fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, label_name,jpg_name));


        t_struct = struct('label_struct',ls,'centering_offset',diff_pos, ...
                        'crop_dimensions', [x_crop_min,x_crop_max,y_crop_min,y_crop_max], ...
                        'big_image_place', [start_row,end_row,start_col,end_col], ...
                         'resize_scale', scale);

        transform_structs{jj} = t_struct;

    end%for i in image_names

    %add in reference image
    bbimg = imread(fullfile(BIGBIRD_BASE_PATH,label_name,'NP1_0.jpg'));
    bbimg = imresize(bbimg,[size(scale_img,1),size(scale_img,2)]);
    


     if(length(image_names) > max_images_per_dir)
        num_images = length(image_names);

        num_buckets = 0;

        if(mod(num_images,max_images_per_dir) < min_images_per_dir)
            num_buckets = floor(num_images/max_images_per_dir);
        else
            num_buckets = ceil(num_images/max_images_per_dir);
        end
    
        

        if(num_buckets > 1)
            images_moved_so_far = 0;
            
            new_image_names = dir(fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, label_name,'*.jpg'));
            new_image_names = {new_image_names.name};

            for k=1:num_buckets
                mkdir(fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, ...
                            strcat(label_name, '_', num2str(k))));
                
                start_kk = images_moved_so_far + 1;
                end_kk = start_kk + max_images_per_dir - 1;

                if(end_kk > length(new_image_names) || k ==num_buckets)
                    end_kk = length(new_image_names);
                end
                
                for kk=start_kk:end_kk
                    movefile(fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, ...
                                        label_name, new_image_names{kk}), ...
                             fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, ...
                                        strcat(label_name, '_', num2str(k)), new_image_names{kk}));
                end
                imwrite(bbimg,fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, strcat(label_name, '_', num2str(k)),'0000000000.jpg') );

                images_moved_so_far = end_kk;

            end% for k
        else
            imwrite(bbimg,fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, label_name,'0000000000.jpg') );
        end% if buckets > 1

    else
        imwrite(bbimg,fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, label_name,'0000000000.jpg') );
    end%if more images than max images
    


    mkdir(fullfile(scene_path,LABELING_DIR,DATA_FOR_LABELING_DIR,label_name));
    %save(fullfile(scene_path,LABELING_DIR,DATA_FOR_LABELING_DIR,label_name,'transform_structs.mat'), 'transform_stucts');


    transform_map = containers.Map(image_names, transform_structs);
    save(fullfile(scene_path,LABELING_DIR,DATA_FOR_LABELING_DIR,label_name,'transform_map.mat'), 'transform_map');

    
    
    
    if(num_buckets  > 1)
        rmdir(fullfile(scene_path, LABELING_DIR, IMAGES_FOR_LABELING_DIR, label_name));
    end  

end%for i, each label_naem






