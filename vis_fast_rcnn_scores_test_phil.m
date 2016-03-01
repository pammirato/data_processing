%show a figure with some bounding boxes and scores for detections in one image at a time
%in a scene


%initialize contants, paths and file names, etc. 
init;

density  = 1;

scene_name = 'SN208'; %make this = 'all' to run all scenes

%only show bounding boxes above this score
score_threshold = .5;

mat_suffix = '.mat';


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

    %get a list of all the image names
    rgb_dir = dir(fullfile(scene_path,RGB_IMAGES_DIR));     
    rgb_dir = rgb_dir(3:end);         
    rgb_image_names = {rgb_dir.name};   




  cur_image_index = 1;
  move_command = 'n';

  while(cur_image_index < length(rgb_image_names) ) 
 
    %get fileame for image
    image_name = rgb_image_names{cur_image_index};
    %get rid of .png
    file_prefix = image_name(1:end-4);


    %show the image (will add detections next)
    img = imread(fullfile(scene_path,RGB_IMAGES_DIR,image_name));
    imshow(img);
    

    detections_all = load(fullfile(scene_path,RECOGNITION_DIR,'fast-rcnn',...  
                              strcat(file_prefix,mat_suffix)));
    detections_all = detections_all.dets;

    categories = fieldnames(detections_all);

    %for every category
    for j=1:length(categories)
      detections = detections_all.(categories{j});  

      %threshold out low scores
      detections = detections(detections(:,5) > score_threshold , :);

      %for each detection       
      for k=1:size(detections,1)
        
        img = insertText(img,detections(k,1:2),categories{j});
        img = insertText(img,[detections(k,1) detections(k,2)+20],detections(k,5));
        img = insertShape(img,'Rectangle',...
               [detections(k,1:2) detections(k,3)-detections(k,1) detections(k,4)-detections(k,2)]);
 
%        rectangle('Position',detections(k,1:4), 'LineWidth',2, 'EdgeColor','b'); 
      end %for k, each detection
    end %for j, each category



 
    imshow(img);





    move_command = input(['Enter move command(' num2str(cur_image_index) '/' ...
                          num2str(length(rgb_image_names)) '):' ], 's');

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

end%for each scene


