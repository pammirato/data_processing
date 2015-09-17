














IMAGE_ID = 1;
QW = 2;
QX = 3;
QY = 4;
QZ = 5;
TX = 6;
TY = 7;
TZ = 8;
CAMERA_ID = 9;
NAME = 10;



room_name = 'kitchenette2';
class_name = 'chair';

base_path = '/home/ammirato/Data/';







%d =dir(base_path);
%d = d(3:end);


%for i=1:length(d)
    
   % if(~d(i).isdir)
   %     continue;
   % end



    %room_name = d(i).name;


    image_path = ['/home/ammirato/Data/' room_name '/rgb/'];
    recognition_results_path = [base_path room_name '/recognition_results/fast-rcnn/' class_name '/'];
    positions_path =[ '/home/ammirato/Data/' room_name '/reconstruction_results/'];







    fid_positions = fopen([positions_path 'images.txt']); 

    fgetl(fid_positions); 
    fgetl(fid_positions); 
    line = fgetl(fid_positions); 

    images = cell(1,1); 
    names = cell(1,1); 

    cur_image = zeros(1,CAMERA_ID); 

    i = 1;

    while(ischar(line))

      %get image info
      line = fgetl(fid_positions);
      line = strsplit(line);

      names{i} = line{end}; 
      cur_image = str2double(line(1:end-1)); 
      images{i} = cur_image; 

      %get Points2D 
      line =fgetl(fid_positions); 

      i = i+1;
    end

    images = images(1:end-1);

    %holds camera positions
    X = zeros(1,length(images)); 
    Y = zeros(1,length(images));
    Z = zeros(1,length(images));

    %holds camera directions
    dX = zeros(1,length(images));
    dY = zeros(1,length(images));
    dZ = zeros(1,length(images));

    cur_vec = zeros(1,3);
    vec1 = [0;0;1;1];
    vec2 = [0;0;0;1];


    for i=1:length(images)

      cur_image = images{i};
      t = [cur_image(TX); cur_image(TY); cur_image(TZ)];
      quat = [cur_image(QW); cur_image(QX); cur_image(QY); cur_image(QZ)];
      R = quaternion_to_matrix(quat); % get rotation matrix from quaternion orientation
      %world camera positions = -(R)^T t (rotation matrix from quaternion(QX...) and t = TX, ...
      worldpos = -R' * t;

      X(i) = worldpos(1); 
      Y(i) = worldpos(2); 
      Z(i) = worldpos(3); 

      proj = [-R' worldpos];

      cur_vec = (proj * vec1) - (proj*vec2);

      dX(i) = worldpos(1) + cur_vec(1);
      dY(i) = worldpos(2) + cur_vec(2);
      dZ(i) = worldpos(3) + cur_vec(3);

    end%for i 

    %------------------------------------%
    % Uncomment this section to get a 3D plot of camera
    % positions and orientation

    Xdir = X-dX;
    Ydir = Y-dY;
    Zdir = Z-dZ;
    
    
    
    plotfig = figure;
    scatter3(X,Y,Z,'r.'); %plot camera positions in X and Z
    axis equal;
    hold on;
    quiver3(X,Y,Z,Xdir,Ydir,Zdir,'ShowArrowHead','off');
    
     
    savefig([positions_path 'fig.fig']);
    
    view([0 1 0]);
    drawnow;
    print([positions_path 'vis.jpg'], '-djpeg');
%end

% 
% 
% plotfig = figure;
% scatter3(X,Y,Z,'r.'); %plot camera positions in X and Z
% axis equal;
% hold on;
% quiver3(X,Y,Z,Xdir,Ydir,Zdir,'ShowArrowHead','off');
% rotate3d on;
% dcm_obj = datacursormode(plotfig); % data cursor object for selecing points
% 
% 
% imfig = figure;
% figure(plotfig);
% j = -1; % index of last point selected
% old_highlight=0;
% 
% while 1
%   waitforbuttonpress;
%   if strcmp(get(dcm_obj,'Enable'),'on') % if data cursor is on, get a point
%     
%     cursor = getCursorInfo(dcm_obj);
%     if length(cursor) > 0 % if user actually clicked on a data point
%       cursor_pos = cursor.Position;
% 
%       % get index of data point selected by cursor
%       worldpos = [X' Y' Z'];
%       [distance, i] = pdist2(worldpos,cursor.Position,'euclidean','Smallest',1);
% 
%       % highlight camera direction for selected data point
%       highlight = quiver3(X(i),Y(i),Z(i),Xdir(i),Ydir(i),Zdir(i),'Color','b',...
%                   'LineWidth',3.0,'AutoScaleFactor',1.5); 
%       if j > 0
%         % unhighlight previous direction
%         set(old_highlight,'Visible','off');
%       end
%       j = i;
%       old_highlight = highlight;
% 
%       figure(imfig);
%       try
%           imshow(strcat(recognition_results_path, names{i}));
%       catch
%           disp('no chair');
%          imshow(strcat(image_path, names{i})); % show image camera took at that position
%       end
%       figure(plotfig);
%     end
%   end
% end










