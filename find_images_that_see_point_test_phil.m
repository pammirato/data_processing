%gets all the images that see a point from another image
%
% input - an x,y, image_name   -where x,y are the location in pixels in
%                                image image_name of the point 
%
%initialize contants, paths and file names, etc. 
init;
IMAGE_ID = 1;
QW = 2;
QX = 3;
QY = 4;
QZ = 5;
TX = 6;
TY = 7;
TZ = 8;



scene_name = 'FB341';
label_to_process = 'red_bull'; %make 'all' for every label
occulsion_threshold = 100;
scale_add = 250;

debug =1;

 x = 0;
 y = 0;
 depth = 0;

 %size of rgb image in pixels
kImageWidth = 1920;
kImageHeight = 1080;

%distance from kinects in mm
kDistanceK1K2 = 291;
kDistanceK2K3 = 272;


%set intrinsic matrices for each kinect
intrinsic1 = [ 1.0700016292741097e+03, 0., 9.2726881773877119e+02; 0.,1.0691225545678490e+03, 5.4576099988165549e+02; 0., 0., 1. ];
intrinsic2 = [  1.0582854982177009e+03, 0., 9.5857576622458146e+0; 0., 1.0593799583771420e+03, 5.3110874137837084e+02; 0., 0., 1. ];
intrinsic3 = [ 1.0630462958838500e+03, 0., 9.6260473585485727e+02; 0., 1.0636103172708376e+03, 5.3489949221354482e+02; 0., 0., 1.];

     
intrinsic2  = intrinsic1;


scene_path = fullfile(BASE_PATH,scene_name);



%end result
label_to_images_that_see_it_map = containers.Map();


text_output_fid = fopen(fullfile(scene_path, LABELING_DIR,  ...
            DATA_FOR_LABELING_DIR, ALL_IMAGES_THAT_SEE_POINT_FILE), 'wt');


fprintf(text_output_fid, [strcat('%%this file has hand labeled points on images, and other',  ... 
                            'images from the scene that see the hand labeled point.') '\n' ]);
                       
fprintf(text_output_fid,['%%format:(x,y,depth refer to the labeled or found point in that image' '\n']);
fprintf(text_output_fid,['%%hand_labeled_image_name  X Y DEPTH' '\n']);
fprintf(text_output_fid,['%%label' '\n']);
fprintf(text_output_fid,['%%--------------' '\n']);
fprintf(text_output_fid,['%%image_that_sees_that_point_name  X Y DEPTH' '\n' '\n']);


load_depths = input('Load all depths?(y/n)' , 's');


    

depths_loaded = 0;

if(strcmp(label_to_process,'all') && (load_depths=='y'))


    %%%%%%%%%%%%%%%%%  LOAD ALL DEPTH IMAGES  %%%%%%%%%%%%%%%%%%%%%%%%%%%

    d = dir(fullfile(scene_path,'rgb'));
    d = d(3:end);
    image_names = {d.name};


    depth_images = cell(1,length(d));

    for i=1:length(image_names)
        rgb_name = image_names{i};

        if(exist(fullfile(scene_path, 'filled_depth',strcat(rgb_name(1:8),'04.png') ),'file'))
            depth_images{i} = imread(fullfile(scene_path, 'filled_depth', ... 
                           strcat(rgb_name(1:8),'04.png') ));
        else
            depth_images{i} = imread(fullfile(scene_path, 'raw_depth', ... 
                           strcat(rgb_name(1:8),'03.png') ));
        end


    end% for i, each image name
    
    
    depth_img_map = containers.Map(image_names, depth_images);
    
    depths_loaded = 1;
end


if(load_depths == 'n')
    a = input('Are depths loaded?(y/n)' , 's');
    
    if(a=='y')
        depths_loaded = 1;
    end
end





%%%%%%%%%%%%%%%%%  END LOAD ALL DEPTH IMAGES  %%%%%%%%%%%%%%%%%%%%%%%%%%%













%%%%%%%%%%%%%%%%%%%%%%%%%%%%% PARSE LABELED POINTS FILE %%%%%%%%%%%%%%%

labeled_names_and_points = cell(0);
labels = cell(0);

%open file with labeled points                
labeled_points_fid = fopen(fullfile(scene_path, LABELING_DIR, ...
                               DATA_FOR_LABELING_DIR, ALL_LABELED_POINTS_FILE));

                           
                           
%move past header
fgetl(labeled_points_fid);
fgetl(labeled_points_fid);
line = fgetl(labeled_points_fid);




line = fgetl(labeled_points_fid);
while(ischar(line))

  %split line based on space, into IMAGE_NAME X Y DEPTH
  labeled_names_and_points{length(labeled_names_and_points)+1} = strsplit(line);
  

  %get label
  labels{length(labels)+1} =fgetl(labeled_points_fid);
  
  %get next labeled point
  line =fgetl(labeled_points_fid);

end

% %the last line is a blank space, so get rid of the last elements
% %split line based on space, into IMAGE_NAME X Y DEPTH
% labeled_names_and_points = labeled_names_and_points(1:end-1);
% 
% 
% %get label
% labels = labels(1:end-1);
  






%%%%%%%%%%%%%%%%%%%%%%%%%%%%% END PARSE LABELED POINTS FILE %%%%%%%%%%%%%%%
















%load data about psition of each image in this scene
camera_structs_file =  load(fullfile(scene_path,RECONSTRUCTION_DIR,NEW_CAMERA_STRUCTS_FILE));
camera_structs = camera_structs_file.(CAMERA_STRUCTS);
scale  = camera_structs_file.scale + scale_add;

%get a list of all the image file names
temp = cell2mat(camera_structs);
image_names = {temp.(IMAGE_NAME)};
clear temp;


%make a map from image name to camera_struct
camera_struct_map = containers.Map(image_names, camera_structs);






%%%%%%%%%%%%%%%%%%%%%%%%%%%% MAIN LOOP  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%for every labeled point, find all other images that see that point

for i=1:length(labeled_names_and_points)
    
    cur_data = labeled_names_and_points{i};

    labeled_image_name = cur_data{1};
    point = floor([str2double(cur_data{2}) str2double(cur_data{3})]);
    depth = str2double(cur_data{4});
    
    label = labels{i}
    
    if(~strcmp(label_to_process,'all'))
        if(~strcmp(label_to_process,label))
            continue;
        end
    end
    



   






    % %%%%%%%%%%%%%%%%%%%%%u   UNDISTORT FISHEYE CAMERA  %%%%%%%%%%%%%%%%%


%     %set up camera parameters from calibration file generated with ROS tool
%      intrinsic1 = [ 1.0700016292741097e+03, 0., 9.2726881773877119e+02; 0.,1.0691225545678490e+03, 5.4576099988165549e+02; 0., 0., 1. ];
%      
%      intrinsic2 = [  1.0582854982177009e+03, 0., 9.5857576622458146e+02, 0., 1.0593799583771420e+03, 5.3110874137837084e+02, 0., 0., 1. ];
%      
%      intrinsic3 = [ 1.0630462958838500e+03, 0., 9.6260473585485727e+02, 0., 1.0636103172708376e+03, 5.3489949221354482e+02, 0., 0., 1.];
%      
     
    distortion1 = [ 3.5321295653368376e-02, 2.5428166340122748e-03, 2.3872136896159945e-03, -2.4103515597419067e-03, -4.0612086782529380e-02 ];
    rotation1 = [ 1., 0., 0.; 0., 1., 0.; 0., 0., 1. ];
    projection1 = [ 1.0700016292741097e+03, 0., 9.2726881773877119e+02, 0.; 0.,1.0691225545678490e+03, 5.4576099988165549e+02, 0.; 0., 0., 1., 0.; 0., 0., 0., 1. ];

    %http://docs.opencv.org/modules/calib3d/doc/camera_calibration_and_3d_reconstruction.html
    radialDistortion1 = distortion1([1 2]);
    tangentialDistorition1  = distortion1([3 4]);

    cameraParams1 = cameraParameters('IntrinsicMatrix',intrinsic1, ...
                                     'RadialDistortion', radialDistortion1, ...
                                     'TangentialDistortion', tangentialDistorition1);


%     %read in the original, distorted image     
%     imgd = imread(fullfile(BASE_PATH,scene_name, RGB_IMAGES_DIR, 'rgb0K1.png'));
% 
%     %show the undistorted image
%     imgu = undistortImage(imgd,cameraParams1);
%     %imshow([imgd  imgu]);
% 
% 
% 
%     %undistort the 
     undistorted_point = undistortPoints(point,cameraParams1)';
    undistorted_point = undistorted_point;
    %undistorted_point = point';


    %%%%%%%%%%%%%%%%%%%%%% END UNDISTORT FISHEYE CAMERA  %%%%%%%%%%%%%%%%%































    %%%%%%%%%%% CONVERT POINT FROM PIXELS TO WORLD COORDINATES %%%%%%%%%%%%%%%



    %get the data for the labeled image
    camera_struct = camera_struct_map(labeled_image_name);

    %intrinsic matrix of kinect1
    %decide which intrinsic matrix to use
    K = intrinsic1;
    K = eye(3);
    if(labeled_image_name(8) =='1')
        K = intrinsic1;
    elseif(labeled_image_name(8) =='2')
        K = intrinsic2;
    else
        K = intrinsic3;
    end
   

    t = camera_struct.(TRANSLATION_VECTOR);
    R = camera_struct.(ROTATION_MATRIX);
    C = camera_struct.(SCALED_WORLD_POSITION);

    t = t*scale;


    world_coords4 = R' * depth * pinv(K) *  [undistorted_point;1] - R'*t;

    world_coords = world_coords4;
    %%%%%%%%%%% END CONVERT POINT FROM PIXELS TO WORLD COORDINATES %%%%%%%%%%%%%%%











    

    %%%%%%%%%%%%% FIND IMAGES THAT SEE THAT 3D Point   %%%%%%%%%%%%%%%%

    found_image_names = cell(0);
    found_points  =cell(0);

    image_names = sort(image_names);
    %for each possible image, see if it contains the labeled point
    for j=1:length(image_names)
        cur_name = image_names{j};

        %skip the labeled image    
        if(strcmp(cur_name,labeled_image_name))
            continue;
        end



        cur_camera_struct = camera_struct_map(cur_name);
        
        %decide which intrinsic matrix to use
        K = intrinsic1;
        K = eye(3);
        if(cur_name(8) =='1')
            K = intrinsic1;
        elseif(cur_name(8) =='2')
            K = intrinsic2;
        else
            K = intrinsic3;
        end

        %get rotation matrix
        R = cur_camera_struct.(ROTATION_MATRIX);

        %translation vector
        t = cur_camera_struct.(TRANSLATION_VECTOR);
        t = t * scale;


        %re-orient the point to see if it is viewable by this camera
        P = [R t];
        oriented_point = P * [world_coords;1];
        %make sure z is positive
        if(oriented_point(3) < 0)
          continue;
        end



        %project the world point onto this image
        M = K * [R t];
        cur_image_point = M * [world_coords;1];

        %acccount for homogenous coords
        cur_image_point = cur_image_point / cur_image_point(3);
        cur_image_point = cur_image_point(1:2);


        %make sure the point is in the image
        if(cur_image_point(1) < 1 ||  cur_image_point(2) < 1 || ...
           cur_image_point(1) > kImageWidth || cur_image_point(2) > kImageHeight)

            continue;

        end 




        %%%%%% OCCULSION  %%%%%%5

        %make sure distance from camera to world_coords is similar to depth of
        %projected point in the depth image

        %get the depth image
        suffix_index = 4;%strfind(cur_name,'b') + 1;
%         depth_image = imread(fullfile(scene_path, RAW_DEPTH_IMAGES_DIR, ...
%             strcat(cur_name(1:8),'03.png') ));
        if(~depths_loaded)
            if(exist(fullfile(scene_path, 'filled_depth',strcat(cur_name(1:8),'04.png') ),'file'))
                depth_image = imread(fullfile(scene_path, 'filled_depth', ... 
                               strcat(cur_name(1:8),'04.png') ));
            else
                depth_image = imread(fullfile(scene_path, 'raw_depth', ... 
                               strcat(cur_name(1:8),'03.png') ));
            end
        else
            depth_image = depth_img_map(cur_name);
        end
        cur_depth = depth_image(floor(cur_image_point(2)), floor(cur_image_point(1)));

        camera_pos = cur_camera_struct.(SCALED_WORLD_POSITION);
        world_dist = pdist2(camera_pos', world_coords');

        if(cur_depth ==0)
            breakp=1;
        end
        
        %if the depth == 0, then keep this image as we can't tell
        if(abs(world_dist - cur_depth) > occulsion_threshold  && cur_depth >0)
            continue;
        end



       found_image_names{length(found_image_names)+1} = cur_name; 
       found_points{length(found_points)+1} = [floor(cur_image_point(1)) floor(cur_image_point(2)) cur_depth];
       

    end%for j  image names



    %%%%%%%%%%%%% END FIND IMAGES THAT SEE THAT 3D Point   %%%%%%%%%%%%%%%%














    



    %%%%%%%%%%%%%%%%  RE-DISTORT FOUND POINTS   %%%%%%%%%%%%%%%%%%%%%

%     distorted_found_points = cell(1,length(found_points));
%     
%     
%     %from http://docs.opencv.org/modules/imgproc/doc/geometric_transformations.html#cv.InitUndistortRectifyMap
%     % InitUndistortRectifyMap
% 
%     for i=1:length(found_points)
% 
% 
%         undistorted_found_point = found_points{i};
% 
%         k1 = distortion1(1);
%         k2 = distortion1(2);
%         p1 = distortion1(3);
%         p2 = distortion1(4);
% 
%         fx = intrinsic1(1,1);
%         fy = intrinsic1(2,2);
%         cx = intrinsic1(1,3);
%         cy = intrinsic1(2,3);
% 
% 
%         %points from corrected image
%         u = undistorted_found_point(1);
%         v = undistorted_found_point(2);
% 
%         r1 = sqrt( (u-cx)^2 + (v-cy)^2);
% 
% 
%         x = (u - cx)/fx;
%         y = (v - cy)/fy;
% 
%         r = sqrt(x^2 + y^2);
% 
%         R = eye(3);
%         xyw = pinv(R) * [x;y;1];
% 
%         x_ = xyw(1)/xyw(3);
%         y_ = xyw(2)/xyw(3);
% 
%         x__ = x_ *(1 + k1*(r^2) + k2*(r^4)) + 2*p1*x_*y_ + p2*(r^2 + 2*(x_^2));
%         y__ = y_ *(1 + k1*(r^2) + k2*(r^4)) + p1*(r^2 + 2*(y_^2)) + 2*p2*x_*y_;
% 
%         ox  = floor(x__*fx + cx);
%         oy  = floor(y__*fy + cy);
% 
%         distorted_found_points{i} = [ox oy];
% 
%     end%for i in found points


    %%%%%%%%%%%%%%%%% END RE-DISTORT FOUND POINTS   %%%%%%%%%%%%%%%%%%%%%



    
    
    
    
    
    
%     
%     {
%   dst.clear();
%   double fx = cameraMatrix.at<double>(0,0);
%   double fy = cameraMatrix.at<double>(1,1);
%   double ux = cameraMatrix.at<double>(0,2);
%   double uy = cameraMatrix.at<double>(1,2);
% 
%   double k1 = distorsionMatrix.at<double>(0, 0);
%   double k2 = distorsionMatrix.at<double>(0, 1);
%   double p1 = distorsionMatrix.at<double>(0, 2);
%   double p2 = distorsionMatrix.at<double>(0, 3);
%   double k3 = distorsionMatrix.at<double>(0, 4);
%   //BOOST_FOREACH(const cv::Point2d &p, src)
%   for (unsigned int i = 0; i < src.size(); i++)
%   {
%     const cv::Point2d &p = src[i];
%     double x = p.x;
%     double y = p.y;
%     double xCorrected, yCorrected;
%     //Step 1 : correct distorsion
%     {     
%       double r2 = x*x + y*y;
%       //radial distorsion
%       xCorrected = x * (1. + k1 * r2 + k2 * r2 * r2 + k3 * r2 * r2 * r2);
%       yCorrected = y * (1. + k1 * r2 + k2 * r2 * r2 + k3 * r2 * r2 * r2);
% 
%       //tangential distorsion
%       //The "Learning OpenCV" book is wrong here !!!
%       //False equations from the "Learning OpenCv" book
%       //xCorrected = xCorrected + (2. * p1 * y + p2 * (r2 + 2. * x * x)); 
%       //yCorrected = yCorrected + (p1 * (r2 + 2. * y * y) + 2. * p2 * x);
%       //Correct formulae found at : http://www.vision.caltech.edu/bouguetj/calib_doc/htmls/parameters.html
%       xCorrected = xCorrected + (2. * p1 * x * y + p2 * (r2 + 2. * x * x));
%       yCorrected = yCorrected + (p1 * (r2 + 2. * y * y) + 2. * p2 * x * y);
%     }
%     //Step 2 : ideal coordinates => actual coordinates
%     {
%       xCorrected = xCorrected * fx + ux;
%       yCorrected = yCorrected * fy + uy;
%     }
%     dst.push_back(cv::Point2d(xCorrected, yCorrected));
%     
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
  if(debug)  
  display = input('Display found images/points?(y/n)' , 's');


  if(display == 'y')


    pause_length = input('Enter seconds to pause between images(0 for keyboard movement): ','s');

    pause_length = str2num(pause_length);

    %show the images/points as a video
    if(pause_length > 0)

      %preload all the images
      images = cell(1,length(found_image_names));
      for i=1:length(images)
        images{i} = imread(fullfile(scene_path,RGB_IMAGES_DIR,found_image_names{i})); 
      end

      for i=1:length(images)
        imshow(images{i});
        hold on;
        cur_point = found_points{i};
        plot(cur_point(1),cur_point(2),'b.', 'MarkerSize',100);
        
        %distorted_point = distorted_found_points{i};
        %plot(distorted_point(1),distorted_point(2),'r.', 'MarkerSize',100);
        pause(pause_length); 
        hold off;
      end

    %let user move through images using keyboard
    else
        
        
        
        
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

        while(cur_image_index < length(found_image_names) ) 



          %%%%%%
          %%%%%%
          %%% VIEWING CODE
          imshow(imread(fullfile(scene_path,RGB_IMAGES_DIR, ...
                   found_image_names{cur_image_index}))); 
    
          hold on;
          cur_point = found_points{cur_image_index};     
          plot(cur_point(1),cur_point(2),'b.','MarkerSize',30); 
          title(num2str(cur_point(3)));
          
%           distorted_point = distorted_found_points{i};
%           plot(distorted_point(1),distorted_point(2),'r.', 'MarkerSize',30);
          
          hold off;
          
          %%%%%%
          %%%%%%











          move_command = input(['Enter move command(' num2str(cur_image_index) '/' ...
                                  num2str(length(found_image_names)) '):' ], 's');

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


        
        
        
        
        
    end%if pause >0



  end%if display == y
  end % if debug
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%  WRITE OUT FOUND POINTS TO A FILE  %%%%%%%%%%%%%%

    
    cur_pt_string = strcat(labeled_image_name, ' ', num2str(point(1)), ' ', ... 
                            num2str(point(2)), ' ', num2str(depth));
    
    fprintf(text_output_fid,[cur_pt_string '\n']);
    fprintf(text_output_fid,[label '\n']);
    fprintf(text_output_fid,['--------------' '\n']);

    

    %write one line for each found point, IMAGE_NAME X Y DEPTH
    for j=1:length(found_points)

      %get the x y depth
      cur_pt = found_points{j};

      cur_pt_string = strcat(found_image_names{j}, ' ', num2str(cur_pt(1)), ' ', ... 
                               num2str(cur_pt(2)), ' ', num2str(cur_pt(3)));
      
      %add this point 
      fprintf(text_output_fid,[cur_pt_string '\n']);
        
    end%for j in found_points

    fprintf(text_output_fid,['\n']);








    %%%%%%%%%%%%%%%%%%%%%%%  End WRITE OUT FOUND POINTS TO A FILE  %%%%%%%%%%%%%%
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    %%%%%%%%%%%%%%%%%%  POPULATE LABEL_TO_IMAGES_THAT_SEE_IT_MAP %%%%%%%%%
    
    %add in the hand labeled point
    found_image_names{length(found_image_names)+1} = labeled_image_name; 
    found_points{length(found_points)+1} = [point depth];
    
    
    cur_structs_array = cell(1,length(found_points));
    
    for j=1:length(cur_structs_array)
        cur_pt = found_points{j};
        
        cur_structs_array{j} = struct(IMAGE_NAME, found_image_names{j}, ...
                                      X, cur_pt(1),  Y, cur_pt(2), ...
                                      DEPTH, cur_pt(3));
    end%for j 
    
    
    %if the current label has already been used in the map
    %then merge these images and points to the old ones.
    if(isKey(label_to_images_that_see_it_map, label))
        
        %get the values that are already in the map
        old_structs_array = label_to_images_that_see_it_map(label);
        
        %just compare the names with 'unique' fucntion
        temp = cell2mat(old_structs_array);
        old_names = {temp.(IMAGE_NAME)};
        clear temp;
        
        [unique_names, iold, ifound] = union(old_names,found_image_names,'stable');
        
        %remove duplicates
        cur_structs_array = cur_structs_array(ifound); 
        
        %append the two non-intersecting lists
        new_structs_array = {old_structs_array{:} cur_structs_array{:}};
        
        %now sort the new array by image name
        temp = cell2mat(new_structs_array);
        all_names = {temp.image_name};
        [a,b] = sort(all_names);
        c = cell(1,length(new_structs_array));
        for kk=1:length(c)
            c(kk) = new_structs_array(b(kk));
        end
        new_structs_array = c;
        
        
        %now add the new array to the old values
        old_keys = keys(label_to_images_that_see_it_map);
        old_values = values(label_to_images_that_see_it_map);
        
        
        %find the index of the label in old_keys
        label_index = 0;
        for k=1:length(old_keys)
            if(strcmp(old_keys{k}, label))
                label_index = k;
            end
        end%for k  
        
        %replace the old values for this label
        old_values{label_index} = new_structs_array;
        
        %update the map
        label_to_images_that_see_it_map =  ...
                                    containers.Map(old_keys, old_values);
        
    else
        
        %if this label hasn't been used yet, just add the points in
        cur_keys = keys(label_to_images_that_see_it_map);
        
        
        % sort the structs array by image name
        temp = cell2mat(cur_structs_array);
        all_names = {temp.image_name};
        [a,b] = sort(all_names);
        c = cell(1,length(cur_structs_array));
        for kk=1:length(c)
            c(kk) = cur_structs_array(b(kk));
        end
        cur_structs_array = c;
        
        

        %if this is the first entry
        if(length(cur_keys) == 0)
            label_to_images_that_see_it_map =  ...
                                containers.Map(label,cur_structs_array);
        else%just append the new stuff
            cur_values = values(label_to_images_that_see_it_map);
            
            
            
            
            

            
            
            
            
            cur_keys{length(cur_keys)+1} = label;
            cur_values{length(cur_values)+1} = cur_structs_array;

            label_to_images_that_see_it_map =  ...
                               containers.Map(cur_keys,cur_values);

        end%if length  - first key to map


    end%if isKey

    

    
    
    %%%%%%%%%%%%%%%%%% END POPULATE LABEL_TO_IMAGES_THAT_SEE_IT_MAP %%%%%%%%%

    
    
    
    
    
    
    
    
    
    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%  VIS SOME DETECTIONS  %%%%%%%%%%%%%%%%%%%%%%%%    
    
    
% 
%         %get the structs with IMAGE_NAME, X, Y, DEPTH for images that see this
%     %instance
%     label_structs = label_to_images_that_see_it_map(label);
% 
%     %get all the image names
%     temp = cell2mat(label_structs);
%     image_names = {temp.(IMAGE_NAME)};
%     clear temp;
% 
% 
% 
%     %load data about psition of each image in this scene
%     camera_structs_file =  load(fullfile(scene_path,RECONSTRUCTION_DIR,CAMERA_STRUCTS_FILE));
%     camera_structs = camera_structs_file.(CAMERA_STRUCTS);
%     camera_structscale  = camera_structs_file.scale;
% 
%     %get a list of all the image file names in the entire scene
%     temp = cell2mat(camera_structs);
%     all_image_names = {temp.(IMAGE_NAME)};
%     clear temp;
% 
%     %make a map from image name to camera_struct
%     camera_structs_map = containers.Map(all_image_names, camera_structs);
%     clear all_image_names;
% 
% 
% 
% 
%     %for each image,
%     for i=1:length(image_names)
%         %figure;
%         imshow(fullfile(scene_path, RGB_IMAGES_DIR, image_names{i}));
% 
% 
%         ls = label_structs{i};
%         hold on;
%         plot(ls.(X), ls.(Y),'r.','MarkerSize',40);
%         hold off;
% 
%         cur_name = image_names{i};
%         title(cur_name);
% 
%         [x,y ,but] = ginput(1);
%         
%         if(but ~=1)
%             break;
%         end
% 
%     end%for i in image_names
% 



    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    



end %for i , every labeled point from file 

%%% END MAIN LOOP%%%



if(exist(fullfile(scene_path,LABELING_DIR, ...
         DATA_FOR_LABELING_DIR,LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE),'file'))
     
     values = label_to_images_that_see_it_map.values;
     key = label_to_images_that_see_it_map.keys;
     
     label_to_images_that_see_it_map = load(fullfile(scene_path,LABELING_DIR, ...
         DATA_FOR_LABELING_DIR,LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE));
     label_to_images_that_see_it_map = label_to_images_that_see_it_map.label_to_images_that_see_it_map;
     
     label_to_images_that_see_it_map(key{1}) = values{1};
end

save(fullfile(scene_path,LABELING_DIR, ...
    DATA_FOR_LABELING_DIR,LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE), ...
    LABEL_TO_IMAGES_THAT_SEE_IT_MAP);



