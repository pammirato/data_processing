%template for code that allows a user to "move" around a scene by changing an index to 
%pick a new image to view




%requires  image sturcts map - image name to image struct
%          image_names  - cell array of all image names

cur_image_index = 1;
cur_image_name  = image_names{cur_image_index};
cur_image_struct =  image_structs_map(cur_image_name);
move_command = 'w';

while(cur_image_index <= length(image_names)) 



  %%%%%%
  %%%%%%
  %%% VIEWING CODE
  %%%%%%
  %%%%%%












  disp('Enter move command: ');
  move_command = getkey(1);

  if(move_command == 'q'))
      disp('quiting...');
      break;

  elseif(move_command =='w'))
      %move forward 
      next_image_name = cur_struct.translate_forward;
      cur_image_index = str2num(next_image_name(1:6));

  elseif(move_command =='s'))
      %move backward 
      next_image_name = cur_struct.translate_backward;
      cur_image_index = str2num(next_image_name(1:6));
  
  elseif(move_command =='d'))
      %rotate clockwise
      next_image_name = cur_struct.rotate_cw;
      cur_image_index = str2num(next_image_name(1:6));
  elseif(move_command =='a'))
      %rotate counter clockwise 
      next_image_name = cur_struct.rotate_ccw;
      cur_image_index = str2num(next_image_name(1:6));

  elseif(move_command =='n'))
      %go forward one image 
      cur_image_index = cur_image_index+1;  
 
  elseif(move_command =='p'))
      %go backward one image 
      cur_image_index = cur_image_index-1;
      if(cur_image_index < 1)
        cur_image_index = 1;
      end

  elseif(move_command =='m'))
      %let the user decide how much to go(forward or back) 
      num_to_move = input('How many images to move: ', 's');
      num_to_move = str2num(num_to_move);
      
      cur_image_index = cur_image_index + num_to_move;
  elseif(move_command =='f'))
      %move forward 50 iamges
      cur_image_index = cur_image_index + 50;
  elseif(move_command =='g'))
      %move forward 100 images
      cur_image_index = cur_image_index + 100;
  elseif(move_command =='h'))
    disp('help: ');

    disp('	q  - to quit and save labels so far ');
    disp('	w  - move forward ');
    disp('	s  - move backward ');
    disp('	d  - rotate clockwise');
    disp('	a  - roatate counter clockwise ');
    disp('	n  - go to the next image ');
    disp('	p  - go to the previous image  ');
    disp('	m  - move some number of images,  ');
    disp('		enter the number of images after typing m  and hitting enter once ');
    disp('	f  - move foward 50 images ');
    disp('	g  - move forward 100 images ');
  end    


  if(cur_image_index < 1)
    cur_image_index = 1;
  elseif(cur_image_index > length(image_names))
    cur_image_index = length(image_names);
  end

  cur_image_name = image_names(cur_image_index);
  cur_image_struct = image_structs_map(cur_image_name);

end %while cur_image_index < 
