function visualize_with_bboxes
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

  % directory containing camera position/orientation data
  path = '/Users/phahn/work/bvision/data/SN208/reconstruction_results/';

  % directory containing images captured by the camera
  image_path = '/Users/phahn/work/bvision/data/SN208/rgb/';

  % directory containing detection scores for bounding boxes
  results_path = '/Users/phahn/work/bvision/data/SN208/recognition_results/fast-rcnn/';

  % directory/filename to save figure to
  save_file = '/Users/phahn/work/bvision/data/SN208/misc/';

  fid_images = fopen([path 'images.txt']);
  fgetl(fid_images);
  fgetl(fid_images);
  line = fgetl(fid_images);

  images = cell(1,1);
  names = cell(1,1);

  cur_image = zeros(1,CAMERA_ID);

  i = 1;

  while(ischar(line))

    %get image info
    line = fgetl(fid_images);
    line = strsplit(line);

    names{i} = line{end};
    cur_image = str2double(line(1:end-1));
    images{i} = cur_image;

    %get Points2D
    line =fgetl(fid_images);

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

  Xdir = X-dX;
  Ydir = Y-dY;
  Zdir = Z-dZ;

  worldpos = [X' Y' Z'];
  worlddir = [Xdir' Ydir' Zdir'];

  % set up the display figure with subplots for camera positions, images, etc
  plotfig = figure;
  subplot(1,2,1);
  scatter3(X,Y,Z,'r.'); %plot camera positions in X and Z
  hold on;
  quiver3(X,Y,Z,Xdir,Ydir,Zdir,'ShowArrowHead','off');

  axis equal;
  view(-4,-66); % set a nicer viewing angle
  print(save_file,'-djpeg'); % save a JPEG image of the figure
  savefig(save_file); % save figure in FIG format

  % set figure to call select_camera_position when a data point is selected
  % by the user in data cursor mode
  dcm_obj = datacursormode(plotfig); % get the data cursor object
  set(dcm_obj,'UpdateFcn',{@select_camera_position, worldpos, worlddir,...
                           names, image_path, results_path});
  
  % set up UserData for the figure to save display elements between events
  data = struct('highlight',[],'bboxes',cell(1,1),'scores',cell(1,1));
  set(plotfig,'UserData',data);

  rotate3d on;
  subplot(1,2,1);

end % visualize_with_bboxes()

% This function highlights a camera position and direction in response to
% the user clicking on a data point, and displays the image and recognition
% results corresponding to that capture.
function output = select_camera_position(~, event_obj, worldpos, worlddir,...
                                         names, image_path, results_path)
  cursor = get(event_obj);
  output = [];
  plotfig = gcf;
  subplot(1,2,1);

  % get index of data point selected by cursor
  [distance, i] = pdist2(worldpos,cursor.Position,'euclidean','Smallest',1);

  highlight_camera_position(i, worldpos, worlddir)

  display_image(i, image_path, names);

  display_recognition_results(i, results_path, names);

  subplot(1,2,1);

end

% highlights the direction camera was facing for the image capture idx
function highlight_camera_position(idx, worldpos, worlddir)
  
  % highlight camera direction for selected data point
  new_highlight = quiver3(worldpos(idx,1),worldpos(idx,2),worldpos(idx,3),...
                      worlddir(idx,1),worlddir(idx,2),worlddir(idx,3),...
                      'Color','b','LineWidth',3.0,'AutoScaleFactor',1.5);

  % clear previous direction highlight
  plotfig = gcf;
  userData = get(plotfig,'UserData');
  if length(userData.highlight) > 0
    delete(userData.highlight);
  end

  % set new direction to unhighlight next time
  userData.highlight = new_highlight;
  set(plotfig,'UserData',userData);
end

% displays image specified by idx
function display_image(idx, image_path, names)
  subplot(1,2,2);
  imshow([image_path names{idx}]); % show image camera took at that position
  hold on;
end

% displays recognition results (bounding boxes and recognition scores)
% for the image specified by idx
function display_recognition_results(idx, results_path, names)
  
  plotfig = gcf;
  userData = get(plotfig,'UserData');

  % clear existing display of recognition results
  for j = 1:size(userData.bboxes,2)
    delete(userData.bboxes{j});
    delete(userData.scores{j});
  end
  userData.bboxes = cell(1,1);
  userData.scores = cell(1,1);

  % load detection results. 'dets' struct gets loaded.
  [pathstr,name,ext] = fileparts(names{idx});
  load([results_path name '.mat']);

  % show bounding boxes with detection score at least 0.1
  for j = 1:size(dets.chair,1)
    score = dets.chair(j,5);
    if score < 0.1
      break;
    else
      r = rectangle('Position',dets.chair(j,1:4),'EdgeColor','r','LineWidth',2);
      userData.bboxes{j} = r;
      % show detection score for this bounding box
      t = text(double(dets.chair(j,1))+20, double(dets.chair(j,2))+40, num2str(dets.chair(j,5)),...
              'Color','r','FontSize',12,'FontWeight','bold');
      userData.scores{j} = t;
    end
  end

  set(plotfig,'UserData',userData);
end