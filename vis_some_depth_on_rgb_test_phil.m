

init; 


images_per_room = 101;
scene_name = 'SN208';  %make this = 'all' to go through all rooms






d = dir(BASE_PATH);
d = d(3:end);

if(strcmp(scene_name,'all'))
    num_rooms = length(d);
else
    num_rooms = 1;
end

for i=1:num_rooms
    
    if(num_rooms >1)
        scene_name = d(i).name();
    end
    
    dr = dir(fullfile(BASE_PATH, scene_name,'/rgb/'));
    dr = dr(3:end);


    cur_image_index = 1;
    move_command = 'n';

    scene_path = fullfile(BASE_PATH,scene_name);

    while(cur_image_index < length(dr) ) 
    
    %for j=1:floor(length(dr)/images_per_room):length(dr)
        %rgb_name = dr(j).name;
        rgb_name = dr(cur_image_index).name;
        
        fullfile(BASE_PATH, scene_name,'rgb/', rgb_name)
        
        img = imread(fullfile(BASE_PATH, scene_name,'rgb/', rgb_name));
        depth_name =strcat(rgb_name(1:8),'03.png');
        raw_depth = imread(fullfile(BASE_PATH,scene_name,'/raw_depth/',depth_name));
        
        %fullfile(base_path,scene_name,'/raw_depth/',['raw_depth' index])
        
        imshow(img);
        hold on;
        h = imagesc(raw_depth);
        set(h,'AlphaData',.5);
        hold off; 
       % kin = input(':');
       % 
       % if(kin == 'q')
       %     break;
       % end
%    end
    

      move_command = input(['Enter move command(' num2str(cur_image_index) '/' ...
                              num2str(length(dr)) '):' ], 's');

      if(strcmp(move_command, 'q'))
          disp('quiting...');
          break;

      elseif(strcmp(move_command,'n'))
          %move forward one image 
          cur_image_index = cur_image_index+1;   
      elseif(strcmp(move_command,'p'))
          %move backward one image 
          cur_image_index = cur_image_index-1;
          if(cur_image_index < 1)
            cur_image_index = 1;
          end
      elseif(strcmp(move_command,'m'))
          %let the user decide how much to move(forward or back) 
          num_to_move = input('How many images to move: ', 's');
          num_to_move = str2num(num_to_move);
          
          cur_image_index = cur_image_index + num_to_move;
          if(cur_image_index < 1)
            cur_image_index = 1;
          end
      elseif(strcmp(move_command,'f'))
          %move forward 50 iamges
          num_to_move = 50;
          cur_image_index = cur_image_index + num_to_move;
      elseif(strcmp(move_command,'g'))
          %move forward 100 images
          num_to_move = 100;
          
          cur_image_index = cur_image_index + num_to_move;
      elseif(strcmp(move_command,'s'))
          saveas(gcf,fullfile(BASE_PATH,strcat(scene_name,'_rep_pic.jpg')));          

      elseif(strcmp(move_command,'h'))
        disp('help: ');

        disp('1) click a point on an image ');
        disp('2) type: ');
        disp('  a label - this will be stored with the point, to be saved later ');
        disp('  q  - to quit and save labels so far ');
        disp('  n - go to the next image ');
        disp('  p - go to the previous image  ');
        disp('  m - move some number of images,  ');
        disp('    enter the number of images after typing m  and hitting enter once ');
        disp('  f - move foward 50 images ');
        disp('  g - move forward 100 images ');
      end    
    end %while cur_image_index < 

end











