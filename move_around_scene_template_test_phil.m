%template for code that allows a user to "move" around a scene by changing an index to 
%pick a new image to view



%		q  -quit 
%		n - go to the next image
%		p - go to the previous image
%		m - move some number of images, 
%			enter the number of images after typing 'm' and hitting enter once
%		f - move foward 50 images
%		g - move forward 101 images
%   h - help(print this menu)
%



cur_image_index = 1;
move_command = 'n';

while(cur_image_index < REPLACE1 ) 



  %%%%%%
  %%%%%%
  %%% VIEWING CODE
  %%%%%%
  %%%%%%











  move_command = input(['Enter move command(' num2str(cur_image_index) '/' ...
                          num2str(REPLACE1) '):' ], 's');

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
