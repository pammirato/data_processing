clear;
init;



scene_name = 'SN208'; %make this = 'all' to run all scenes

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


    struct_one = structs(1);
    cur_image_name = struct_one.image_name;
    move_command = 'r';

    while(1)



          img = imread(fullfile(scene_path,RGB_IMAGES_DIR,cur_image_name));
          imshow(img);
            title(cur_image_name);








            cur_struct = structs_map(cur_image_name);

          move_command = input('Enter move command:', 's');

          if(strcmp(move_command, 'q'))
              disp('quiting...');
              break;

          elseif(strcmp(move_command,'e'))
              %move forward one image 

              cur_image_name = cur_struct.rotate_ccw;

          elseif(strcmp(move_command,'r'))
              %move forward one image 
                cur_image_name = cur_struct.rotate_cw;
          elseif(strcmp(move_command,'f'))
              %move forward one image 
                forward_name = cur_struct.translate_forward;
                if(forward_name ~= -1)
                    cur_image_name = forward_name;
                else
                    title('cant move forward here!');
                end
          elseif(strcmp(move_command,'b'))
              %move forward one image 
               backward_name = cur_struct.translate_backward;
                if(backward_name ~= -1)
                    cur_image_name = backward_name;
                else
                    title('cant move backward here!');
                end
          elseif(strcmp(move_command,'x'))
              %move forward one image 
               up_name = cur_struct.translate_up;
                if(up_name ~= -1)
                    cur_image_name = up_name;
                else
                    title('cant move up here!');
                end
          elseif(strcmp(move_command,'c'))
              %move forward one image 
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
    end %while cur_image_index < 


end