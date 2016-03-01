clear;
init;


density = 0;
scene_name = 'Room15'; %make this = 'all' to run all scenes


rec_images = 1;
label_name = 'chair4';
recognition_system = 'fast-rcnn';


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
    end


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

    
    
    if(rec_images)
        load_path = fullfile(scene_path,RECOGNITION_DIR,recognition_system, ...
                            'performance_images', label_name);
    else
        load_path = fullfile(scene_path,RGB_IMAGES_DIR);
    end

   
    
    if(rec_images)
        temp = dir(fullfile(load_path, '*.jpg'));
        valid_image_names = {temp.name};
        cur_image_name = valid_image_names{1};
        cur_image_name = strcat(cur_image_name(1:8),'01.png');
    else
        struct_one = structs(1);
        cur_image_name = struct_one.image_name;
    end
    
    move_command = 'r';

    while(1)


          if(rec_images)
            rec_name = strcat(cur_image_name(1:8),'11.jpg');
            img = imread(fullfile(load_path,rec_name));
          else
            img = imread(fullfile(load_path,cur_image_name));
          end
          imshow(img);
          title(cur_image_name);








          cur_struct = structs_map(cur_image_name);
          
          %store for check later
          prev_image_name = cur_image_name;

          move_command = input('Enter move command:', 's');

          if(strcmp(move_command, 'q'))
              disp('quiting...');
              break;
          elseif(strcmp(move_command,'a'))
              %random
              if(rec_images)
                index = randi(length(valid_image_names),1);
                cur_image_name = valid_image_names{index};
                cur_image_name = strcat(cur_image_name(1:8),'01.png');
              else
                index = randi(length(structs),1);
                cur_struct = structs(index);
                cur_image_name = cur_struct.image_name;
              end
              

          elseif(strcmp(move_command,'e'))
              %rotate ccw
              rotate_name = cur_struct.rotate_ccw;
              if(rotate_name ~= -1)
                 cur_image_name = rotate_name; 
              else
                  
              end

          elseif(strcmp(move_command,'r'))
              %rotate clockwise 
              rotate_name = cur_struct.rotate_cw;
              if(rotate_name ~= -1)
                 cur_image_name = rotate_name; 
              else
                  
              end
          elseif(strcmp(move_command,'f'))
              %move forward one image 
                forward_name = cur_struct.translate_forward;
                if(forward_name ~= -1)
                    cur_image_name = forward_name;
                else
                    title('cant move forward here!');
                end
          elseif(strcmp(move_command,'b'))
              %move backward one image 
               backward_name = cur_struct.translate_backward;
                if(backward_name ~= -1)
                    cur_image_name = backward_name;
                else
                    title('cant move backward here!');
                end
          elseif(strcmp(move_command,'x'))
              %move up 
               up_name = cur_struct.translate_up;
                if(up_name ~= -1)
                    cur_image_name = up_name;
                else
                    title('cant move up here!');
                end
          elseif(strcmp(move_command,'c'))
              %move down 
               down_name = cur_struct.translate_down;
                if(down_name ~= -1)
                    cur_image_name = down_name;
                else
                    title('cant move down here!');
                end
          elseif(strcmp(move_command,'h'))
            disp('help: ');

            disp('1) click a point on an image ');
            disp('2) type: ');
            disp('	a label - this will be stored with the point, to be saved later ');
            disp('	q  - to quit and save labels so far ');
            disp('	n - go to the next image ');
            disp('	p - go to the previous image  ');
            disp('	m - move some number of images,  ');
            disp('		enter the number of images after typing m  and hitting enter once ');
            disp('	f - move foward 50 images ');
            disp('	g - move forward 100 images ');
          end    
          
          
          %ccheck tp see if the next image actually exists
          if(rec_images)
            rec_name = strcat(cur_image_name(1:8),'11.jpg');
            if(~exist(fullfile(load_path, rec_name),'file'))
              cur_image_name= prev_image_name;
            end
          end
    end %while cur_image_index < 


end
