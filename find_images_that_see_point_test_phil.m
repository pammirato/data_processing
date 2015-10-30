%gets all the images that see a point from another image
%
% input - an x,y, image_name   -where x,y are the location in pixels in
%                                image image_name of the point 
%
clear all,close all;
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



scene_name = 'Room15';
occulsion_threshold = 200;


 x = 0;
 y = 0;
 depth = 0;

 %size of rgb image in pixels
kImageWidth = 1920;
kImageHeight = 1080;

%distance from kinects in mm
kDistanceK1K2 = 291;
kDistanceK2K3 = 272;


scene_path = fullfile(BASE_PATH,scene_name);

% %the image we will hand label
% labeled_image_name =  'rgb0K1.png';
% suffix_index = strfind(labeled_image_name,'b') + 1;
% 
% rgb_image = imread(fullfile(scene_path, 'rgb/', labeled_image_name));
% depth_image = imread(fullfile(scene_path, ['raw_depth/raw_depth' labeled_image_name(suffix_index:end)] ));
%   
% %display the image with the depth map overlaid on it
% imshow(rgb_image);    
% hold on;          
% h = imagesc(depth_image);
% set(h,'AlphaData',.5);
% 
% %get one point from the user clicking on the image
% [xi, yi, but] = ginput(1);
% hold off;
% 
% x = floor(xi);
% y = floor(yi);
% point = [x y];
% %get the depth of the labeled pixel from the depth image
% depth = double(depth_image(y,x));



%open file with labeled points                
labeled_points_fid = fopen(fullfile(scene_path, LABELING_DIR, ...
                               DATA_FOR_LABELING_DIR, ALL_LABELED_POINTS_FILE));

                           
                           
%move past header
fgetl(labeled_points_fid);
fgetl(labeled_points_fid);
line = fgetl(labeled_points_fid);




line = fgetl(labeled_points_fid);
while(ischar(line))


  fprintf(fid_save, [line '\n']);

  %get label
  line =fgetl(labeled_points_fid);
  line =fgetl(labeled_points_fid);

end

























%load data about the camera for each image
camera_structs_file =  load(fullfile(scene_path,RECONSTRUCTION_DIR,CAMERA_STRUCTS_FILE));
camera_structs = camera_structs_file.(CAMERA_STRUCTS);
scale  = camera_structs_file.scale;

%get a list of all the image file names
temp = cell2mat(camera_structs);
image_names = {temp.name};
clear temp;

%make a map from image name to camera_struct
camera_struct_map = containers.Map(image_names, camera_structs);

















% %%%%%%%%%%%%%%%%%%%%%u   UNDISTORT FISHEYE CAMERA  %%%%%%%%%%%%%%%%%


%set up camera parameters from calibration file generated with ROS tool
intrinsic1 = [ 1.0700016292741097e+03, 0., 9.2726881773877119e+02; 0.,1.0691225545678490e+03, 5.4576099988165549e+02; 0., 0., 1. ];
distortion1 = [ 3.5321295653368376e-02, 2.5428166340122748e-03, 2.3872136896159945e-03, -2.4103515597419067e-03, -4.0612086782529380e-02 ];
rotation1 = [ 1., 0., 0.; 0., 1., 0.; 0., 0., 1. ];
projection1 = [ 1.0700016292741097e+03, 0., 9.2726881773877119e+02, 0.; 0.,1.0691225545678490e+03, 5.4576099988165549e+02, 0.; 0., 0., 1., 0.; 0., 0., 0., 1. ];

%http://docs.opencv.org/modules/calib3d/doc/camera_calibration_and_3d_reconstruction.html
radialDistortion1 = distortion1([1 2]);
tangentialDistorition1  = distortion1([3 4]);

cameraParams1 = cameraParameters('IntrinsicMatrix',intrinsic1, ...
                                 'RadialDistortion', radialDistortion1, ...
                                 'TangentialDistortion', tangentialDistorition1);
                                 
                    
%read in the original, distorted image     
imgd = imread(fullfile(BASE_PATH,scene_name, RGB_IMAGES_DIR, 'rgb0K1.png'));

%show the undistorted image
imgu = undistortImage(imgd,cameraParams1);
%imshow([imgd  imgu]);



%undistort the 
undistorted_point = undistortPoints(point,cameraParams1);
undistorted_point = undistorted_point';
undistorted_point = point';


%%%%%%%%%%%%%%%%%%%%%% END UNDISTORT FISHEYE CAMERA  %%%%%%%%%%%%%%%%%





























% 
% %%%%%%%%%%%%%%%  SCALE   RECONSTRUCTION  %%%%%%%%%%%%%%%%%%
% 
% 
% %hold the distances between camera positions for kinect1 to kinect2, and K2 to K3
% distances_k1k2 = cell(1,1);
% distances_k2k3 = cell(1,1);
% 
% %keep track of where we are in the matrices
% k1k2_counter =1;
% k2k3_counter =1;
% 
% %find all the distances from the reconstruction
% for i=1:length(image_names)
% 
%   cur_name = image_names{i};
% 
% 
%   %if this is a k1, store the distance to the k2 above it 
%   if( cur_name(end-4) == '1')
%     %get name of image for k2 at same point
%     k2_name = cur_name;
%     k2_name(end -4) = '2';
% 
%     %get camera positions
%     k1_data = camera_struct_map(cur_name);
%     
%     %this image might not exist
%     try
%       k2_data = camera_struct_map(k2_name);
%     catch
%       continue;
%     end
%     
%     
%     distances_k1k2{k1k2_counter} = pdist2(k2_data.(WORLD_POSITION)', k1_data.(WORLD_POSITION)');
%     k1k2_counter =k1k2_counter+1;
% 
%   elseif( cur_name(end-4) == '2')
%     %get name of image for k3 at same point
%     k3_name = cur_name;
%     k3_name(end -4) = '3';
% 
%     %get camera positions
%     k2_data = camera_struct_map(cur_name);
% 
%     %this image might not exist
%     try
%       k3_data = camera_struct_map(k3_name);
%     catch
%       continue;
%     end
%     
% 
%     distances_k2k3{k2k3_counter} = pdist2(k3_data.(WORLD_POSITION)' ,k2_data.(WORLD_POSITION)');
%     k2k3_counter =k2k3_counter+1;
% 
% 
%   end %if cur_name == k1
% 
% 
% end%for i keys
% 
% 
% 
% %get scale from ratio of actual_distance / average_reconstructed_distance
% scale_k1k2 = kDistanceK1K2 / mean(cell2mat(distances_k1k2));
% scale_k2k3 = kDistanceK2K3 / mean(cell2mat(distances_k2k3));
% 
% %get the overall scale as a weighted average from the above
% scale  = ( length(distances_k1k2)*scale_k1k2  + length(distances_k2k3)*scale_k2k3 )...
%           / ( length(distances_k1k2) + length(distances_k2k3) );
% 
% 
% %%%%%%%%%%%%%%% END SCALE   RECONSTRUCTION  %%%%%%%%%%%%%%%%%%






















% xcam = camera coordinates
% ycam = camera coordinates
% depth = depth in from camera 
% M = K[R t]  = projection matrix?

%M1 = intrinsic1 * [ ];

%%%%%%%%%%% CONVERT POINT FROM PIXELS TO WORLD COORDINATES %%%%%%%%%%%%%%%



%get the data for the labeled image
camera_struct = camera_struct_map(labeled_image_name);

%intrinsic matrix of kinect1
K = intrinsic1;
t = camera_struct.(TRANSLATION_VECTOR);
R = camera_struct.(ROTATION_MATRIX);
C = camera_struct.(SCALED_WORLD_POSITION);

t = t*scale;


%P1 = K * [R' -R'*t];
%P2 = K * [R' -R'*(t*scale)];
% P3 = K * [R' -R'*C];
% P4 = K * [R -R'*C];


%world_coords1 = pinv(P1) * [undistorted_point;1];
%world_coords2 = pinv(P2) * [undistorted_point;1];
%world_coords2 = world_coords1 / world_coords1(4);

%world_coords3 = world_coords2*double(depth); %pinv(P3) * [undistored_point;1];

world_coords4 = R' * depth * pinv(K) *  [undistorted_point;1] - R'*t;







%dist1 = pdist2(world_coords1(1:3)',C');

%scalef = (depth/dist1);

%world_coords3 = world_coords1 * (depth/dist1);












% M = intrinsic1 * [-R' t];
% M = M * scale;
% inverse_projection = pinv(M);
% %reverse project the camera coordinates to world coordinates
% world_coords = inverse_projection * homog_camera_coords;

% K = intrinsic1;
% 
% 
% %homog_camera_coords = [x;y;1];
% homog_image_coords = [undistored_point';1];
% homog_camera_coords = [((x - K(1,3)) / K(1,1)); ...
%                         ((y - K(2,3)) / K(2,2)); ...
%                              1];
% 
% world_coords = R' * pinv(intrinsic1) * homog_image_coords - R'*t;
% %world_cords = R' * homog_camera_coords - R'*t;
% 
% camera_pos = -R'* t; 
% 
% vec1 = [0;0;1;1];
% vec2 = [0;0;0;1];
% proj = [-R' worldpos];
% cur_vec = (proj * vec1) - (proj*vec2);
% 
% camera_dir = -cur_vec;
%
% world_coords = world_coords(1:3);
% world_coords2 = world_coords;
% world_coords2(1) = depth/scale;



%%%%%%%%%%% END CONVERT POINT FROM PIXELS TO WORLD COORDINATES %%%%%%%%%%%%%%%




















%%%%%%%%%%%%%%%%%%%  visulaize some stuff  %%%%55



temp = cell2mat(camera_structs);
world_poss = {temp.(SCALED_WORLD_POSITION)}';
world_poss = cell2mat(world_poss);

dirs = {temp.(DIRECTION)}';
dirs = cell2mat(dirs);
clear temp;

names = image_names;


X = world_poss(1:3:end-2)';
Y = world_poss(2:3:end-1)';
Z = world_poss(3:3:end)';

Xdir = dirs(1:3:end-2)';
Ydir = dirs(2:3:end-1)';
Zdir = dirs(3:3:end)';






image_path = fullfile(scene_path,RGB_IMAGES_DIR);


plotfig = figure;
scatter3(X,Y,Z,'r.'); %plot camera positions in X and Z
axis equal;
hold on;





quiver3(X,Y,Z,Xdir,Ydir,Zdir,'ShowArrowHead','off');




rotate3d on;
dcm_obj = datacursormode(plotfig); % data cursor object for selecing points

%scatter3(world_coords1(1),world_coords1(2),world_coords1(3),'b','filled');
%scatter3(world_coords2(1),world_coords2(2),world_coords2(3),'g','filled');
%scatter3(world_coords3(1),world_coords3(2),world_coords3(3),'k','filled')
scatter3(world_coords4(1),world_coords4(2),world_coords4(3),'k','filled');


imfig = figure;
figure(plotfig);
j = -1; % index of last point selected
old_highlight=0;
done = 0;

while (~done)
  waitforbuttonpress;
  if strcmp(get(dcm_obj,'Enable'),'on') % if data cursor is on, get a point
    
    cursor = getCursorInfo(dcm_obj);
    if length(cursor) > 0 % if user actually clicked on a data point
      cursor_pos = cursor.Position;
      
      if(max(abs(world_coords4 - cursor_pos')) == 0)
          done = 1;
      end

      % get index of data point selected by cursor
      worldpos = [X' Y' Z'];
      [distance, i] = pdist2(worldpos,cursor.Position,'euclidean','Smallest',1);

      %       highlight camera direction for selected data point
      highlight = quiver3(X(i),Y(i),Z(i),Xdir(i),Ydir(i),Zdir(i),'Color','b',...
                  'LineWidth',3.0,'AutoScaleFactor',700.5); 
      if j > 0
        % unhighlight previous direction
        set(old_highlight,'Visible','off');
      end
      j = i;
      old_highlight = highlight;

      figure(imfig);
      imshow(strcat(image_path, names{i})); % show image camera took at that position
      figure(plotfig);
    end
  end
end










%%%%%%%%%%%%%%%%%%%%%  end vis     %%%%%%%%%%%%%%%


































world_coords = world_coords4;

%%%%%%%%%%%%% FIND IMAGES THAT SEE THAT 3D Point   %%%%%%%%%%%%%%%%

found_image_names = cell(0);
found_points  =cell(0);

%for each possible image, see if it contains the labeled point
for i=1:length(image_names)
    cur_name = image_names{i};

    %skip the labeled image    
    if(strcmp(cur_name,labeled_image_name))
        continue;
    end
   


    cur_camera_struct = camera_struct_map(cur_name);
    
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
    M = intrinsic1 * [R t];
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
    suffix_index = strfind(cur_name,'b') + 1;
    depth_image = imread(fullfile(scene_path, ['raw_depth/raw_depth' labeled_image_name(suffix_index:end)] ));
    
    cur_depth = depth_image(floor(cur_image_point(2)), floor(cur_image_point(1)));
    
    camera_pos = cur_camera_struct.(SCALED_WORLD_POSITION);
    world_dist = pdist2(camera_pos', world_coords');
    
    if(abs(world_dist - depth) > occulsion_threshold  && depth >0)
        continue;
    end
    
    

   found_image_names{length(found_image_names)+1} = cur_name; 
   found_points{length(found_points)+1} = cur_image_point;
   
end%for i  image names



%%%%%%%%%%%%% END FIND IMAGES THAT SEE THAT 3D Point   %%%%%%%%%%%%%%%%














distorted_found_points = cell(1,length(found_points));



%%%%%%%%%%%%%%%%  RE-DISTORT FOUND POINTS   %%%%%%%%%%%%%%%%%%%%%

%from http://docs.opencv.org/modules/imgproc/doc/geometric_transformations.html#cv.InitUndistortRectifyMap
% InitUndistortRectifyMap

for i=1:length(found_points)
    
    
    undistorted_found_point = found_points{i};

    k1 = distortion1(1);
    k2 = distortion1(2);
    p1 = distortion1(3);
    p2 = distortion1(4);

    fx = intrinsic1(1,1);
    fy = intrinsic1(2,2);
    cx = intrinsic1(1,3);
    cy = intrinsic1(2,3);


    %points from corrected image
    u = undistorted_found_point(1);
    v = undistorted_found_point(2);

    r1 = sqrt( (u-cx)^2 + (v-cy)^2);


    x = (u - cx)/fx;
    y = (v - cy)/fy;
    
    r = sqrt(x^2 + y^2);

    R = eye(3);
    xyw = pinv(R) * [x;y;1];

    x_ = xyw(1)/xyw(3);
    y_ = xyw(2)/xyw(3);

    x__ = x_ *(1 + k1*(r^2) + k2*(r^4)) + 2*p1*x_*y_ + p2*(r^2 + 2*(x_^2));
    y__ = y_ *(1 + k1*(r^2) + k2*(r^4)) + p1*(r^2 + 2*(y_^2)) + 2*p2*x_*y_;

    ox  = floor(x__*fx + cx);
    oy  = floor(y__*fy + cy);
    
    distorted_found_points{i} = [ox oy];
    
end%for i in found points















%%%%%%%%%%%%%%%%% END RE-DISTORT FOUND POINTS   %%%%%%%%%%%%%%%%%%%%%




















%%%%%%%%%%%%%%%%%    DISPLAY FOUND IMAGES/POINTS  %%%%%%%%%%%%%%%%




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
          
          distorted_point = distorted_found_points{i};
          plot(distorted_point(1),distorted_point(2),'r.', 'MarkerSize',30);
          
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







%%%%%%%%%%%%%%%%%  END  DISPLAY FOUND IMAGES/POINTS  %%%%%%%%%%%%%%%%




