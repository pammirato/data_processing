% creates an interactive figure with 2 subplots:
% 1) 3D plot of all the positions in the scene where the camera took a picture
% 2) image corresponding to a camera position, and bounding boxes labeled
%    with recognition results for that image.

function visualize_everything

  scene_name = 'FB209';

  %should the lines indicating orientation be drawn?
  view_orientation = 1;

  %initialize contants, paths and file names, etc.
  init;
  scene_path = fullfile(BASE_PATH, scene_name);
  image_path = fullfile(scene_path, RGB_IMAGES_DIR);
  results_path = fullfile(scene_path, RECOGNITION_DIR, FAST_RCNN_RESULTS);
  save_figure_path = fullfile(scene_path, MISC_DIR);

  % load maps from image name to camera data and vice versa
  % camera data is an array with the camera position and a point along is orientation vector
  % [CAM_X CAM_Y CAM_Z DIR_X DIR_Y DIR_Z]
  name_to_camera_data_path = fullfile(scene_path, RECONSTRUCTION_DIR, NAME_TO_POS_DIRS_MAT_FILE);
  if (~exist(name_to_camera_data_path,'file'))
    save_camera_pos_dirs;
  end
  name_to_camera_data = load(name_to_camera_data_path);
  name_to_camera_data = name_to_camera_data.(NAME_TO_POS_DIRS_MAP);

  %get all the camera_data, gives only a 1D matrix
  names = name_to_camera_data.keys;
  values = cell2mat(name_to_camera_data.values);

  %each image has a data vector 6 long, so index every 6
  X = values(1:6:end-5);
  Y = values(2:6:end-4);
  Z = values(3:6:end-3);
  Xdir = values(4:6:end-2);
  Ydir = values(5:6:end-1);
  Zdir = values(6:6:end);
  

  worldpos = [X' Y' Z'];
  worlddir = [Xdir' Ydir' Zdir'];

  % load reconstructed 3d points for the scene
  points3D_path = fullfile(scene_path, RECONSTRUCTION_DIR, POINTS_3D_MAT_FILE);
  if (~exist(points3D_path,'file'))
    save_reconstructed_points;
  end
  points3D = load(points3D_path);
  points3D = points3D.point_matrix;

  % set up the display figure with subplots for camera positions, images, etc
  plotfig = figure;
  % set up UserData for the figure to save display elements between events
  data = struct('link',[],...
                'index',1,...
                'names',cell(1,1),...
                'image_path',image_path,...
                'bboxes',cell(1,1),...
                'scores',cell(1,1),...
                'categories',cell(1,1),...
                'points',[],...
                'selected_view',[],...
                'selected_bbox',[],...
                'selected_score',[],...
                'selected_point',[],...
                'bbox_img',[]);
  data.names = names;
  set(plotfig,'UserData',data);

  view_axes = subplot(2,2,1);
  scatter3(X,Y,Z,'r.'); %plot camera positions in X and Z
  hold on;
  quiver3(X,Y,Z,Xdir,Ydir,Zdir,'ShowArrowHead','off');

  axis equal;
  axis vis3d;
  view(-4,-66); % set a nicer viewing angle
  print(save_figure_path,'-djpeg'); % save a JPEG image of the figure
  savefig(save_figure_path); % save figure in FIG format

  point_axes = display_reconstructed_points(points3D);

  % link axes together so they rotate together in rotate3d mode
  hlink = linkprop([view_axes,point_axes],{'CameraPosition','CameraUpVector',...
                   'CameraTarget','CameraViewAngle'});
  data = get(plotfig,'UserData');
  data.link = hlink;
  set(plotfig,'UserData',data);

  % display results for the first image so the display isn't blank.
  highlight_camera_view(1, worldpos, worlddir);
  image_axes = display_image(1, image_path, names);
  display_recognition_results(1, results_path, names);
  select_bounding_box(700,800);
  select_bounding_box(900,800);

  % set figure to call select_camera_position when a data point is selected
  % by the user in data cursor mode
  dcm_obj = datacursormode(plotfig); % get the data cursor object
  set(dcm_obj,'UpdateFcn',{@pick_data, worldpos, worlddir, names, image_path,...
                            results_path, view_axes, image_axes, point_axes});

  rotate_obj = rotate3d;
  rotate_obj.Enable = 'on';
  rotate_obj.RotateStyle = 'box';
  setAllowAxesRotate(rotate_obj,image_axes,false);

end

% displays image specified by idx
function ax = display_image(idx, image_path, names)
  ax = subplot(2,2,2);
  imshow([image_path names{idx}]); % show image camera took at that position
  hold on;
end

function display_image_portion(idx, xmin, xmax, ymin, ymax)
  plotfig = gcf;
  userData = get(plotfig,'UserData');
  subplot(2,2,4);

  if length(userData.bbox_img) > 0
    delete(userData.bbox_img);
  end

  img = imread([userData.image_path userData.names{idx}]);
  himage = imshow(img(int16(ymin):int16(ymax),int16(xmin):int16(xmax),:));

  userData.bbox_img = himage;
  set(plotfig,'UserData',userData);
end

% displays recognition results (bounding boxes and recognition scores)
% for the image specified by idx
function display_recognition_results(idx, results_path, names)

  plotfig = gcf;
  userData = get(plotfig,'UserData');
  subplot(2,2,2);

  % clear existing display of recognition results
  for j = 1:size(userData.bboxes,2)
    delete(userData.bboxes{j});
  end
  userData.bboxes = cell(1,1);
  userData.scores = cell(1,1);
  userData.categories = cell(1,1);

  % load detection results. 'dets' struct gets loaded.
  [pathstr,name,ext] = fileparts(names{idx});
  load([results_path name '.mat']);

  % pick out detections from the categories we're looking for.
  det_tables = {'sofa' 'person' 'monitor' 'diningtable' 'bottle' 'pottedplant' 'chair'};
  categories = cell(1,1);
  num_categories = 0;
  boxes_scores = [];
  for i=1:7
    cur_category = det_tables{i};
    detections = getfield(dets, cur_category);
    boxes_scores = [boxes_scores; detections];
    for j=1:size(detections,1)
      categories{num_categories+1,1} = cur_category;
      num_categories = num_categories + 1;
    end
  end

  % sort detection scores into descending order
  [boxes_scores, SortIndex] = sortrows(boxes_scores,-5);
  categories = categories(SortIndex);

  num_bboxes_shown = 10;
  for i=1:num_bboxes_shown
    score = boxes_scores(i,5);
    if score < 0.3
      break;
    end
    x = boxes_scores(i,1);
    y = boxes_scores(i,2);
    w = boxes_scores(i,3) - boxes_scores(i,1);
    h = boxes_scores(i,4) - boxes_scores(i,2);
    r = rectangle('Position',[x y w h],'EdgeColor','r','LineWidth',2);
    userData.bboxes{i} = r;
    % save detection score and category for this bounding box
    userData.scores{i} = score;
    userData.categories{i} = categories{i};
  end

  set(plotfig,'UserData',userData);
end

% display reconstructed 3D points from the scene
function ax = display_reconstructed_points(points)

    ax = subplot(2,2,3);
    % only take a small subset of points, otherwise there are too many for
    % matlab to handle easily. Using 1/50 of the points for now.
    points = points(1:15:end,:);
    % some points outside the scene end up being produced in error,
    % so I try to cut out most of those by only plotting points whose
    % positions are within 2-3 std devs of the mean in each direction.
    std_devs = std(points(:,1:3));
    means = mean(points(:,1:3));
    xlimit = 1.5*std_devs(1);
    ybottom = 1.5*std_devs(2);
    ytop = 3*std_devs(2);
    zlimit = 1.5*std_devs(3);
    scatter3(points(:,1), points(:,2), points(:,3), 10,...
             points(:,4:6)/255.5, 'filled');
    axis equal;
    axis vis3d;
    axis([-xlimit xlimit -ybottom ytop -zlimit zlimit]);

end


% This function gets called when the user clicks in data cursor mode.
% Based on what subplot axes the event came from, choose the correct response.
function output = pick_data(~, event_obj, worldpos, worlddir, names, image_path,...
                            results_path, view_axes, image_axes, point_axes)

  targetAxes = get(event_obj.Target,'parent');

  if isequal(targetAxes,view_axes)
    output = [];
    select_view(event_obj,worldpos,worlddir,names,image_path,results_path);
  elseif isequal(targetAxes,image_axes)
    output = [];
    cursor = get(event_obj);
    select_bounding_box(cursor.Position(1),cursor.Position(2));
  elseif isequal(targetAxes,point_axes)
    output = 'reconstructed points';
    select_reconstructed_point();
  end

end

% This function highlights a camera position and direction in response to
% the user clicking on a data point, and displays the image and recognition
% results corresponding to that capture.
function select_view(event_obj, worldpos, worlddir, names, image_path,...
                              results_path)
  cursor = get(event_obj);
  plotfig = gcf;
  userData = get(plotfig,'UserData');
  subplot(2,2,1);

  % get index of data point selected by cursor
  [distance, i] = pdist2(worldpos,cursor.Position,'euclidean','Smallest',1);
  userData.index = i;
  set(plotfig,'UserData',userData);

  highlight_camera_view(i, worldpos, worlddir);
  display_image(i, image_path, names);
  display_recognition_results(i, results_path, names);

end

function select_bounding_box(x,y);
  plotfig = gcf;
  userData = get(plotfig,'UserData');
  selected_bbox = [];
  selected_score = [];
  selected_category = [];
  min_dist = Inf;

  % select the bounding box whose center is closest to (x,y) among all boxes
  % that contain (x,y)
  for i=1:size(userData.bboxes,2)
    pos = userData.bboxes{i}.Position;
    if x >= pos(1) && x <= pos(1)+pos(3) && y >= pos(2) && y <= pos(2)+pos(4)
      center = [pos(1)+(pos(3)/2) pos(2)+(pos(4)/2)];
      dist_from_center = pdist([x y; center]);
      if dist_from_center < min_dist
        min_dist = dist_from_center;
        selected_bbox = userData.bboxes{i};
        selected_score = userData.scores{i};
        selected_category = userData.categories{i};
      end
    end
  end

  if size(selected_bbox) > 0
    highlight_bounding_box(selected_bbox,selected_score,selected_category);
    pos = selected_bbox.Position;
    display_image_portion(userData.index, pos(1), pos(1)+pos(3), pos(2), pos(2)+pos(4));
    highlight_points(selected_bbox);
  end
end

function select_reconstructed_point();
end

% highlights the direction camera was facing for the image capture idx
function highlight_camera_view(idx, worldpos, worlddir)

  plotfig = gcf;
  userData = get(plotfig,'UserData');
  subplot(2,2,1);

  % clear previous view highlight
  if length(userData.selected_view) > 0
    delete(userData.selected_view);
  end

  % highlight camera view for selected data point
  new_highlight = quiver3(worldpos(idx,1),worldpos(idx,2),worldpos(idx,3),...
                      worlddir(idx,1),worlddir(idx,2),worlddir(idx,3),...
                      'Color','b','LineWidth',3.0,'AutoScaleFactor',1.5);

  % set new view to unhighlight next time
  userData.selected_view = new_highlight;
  set(plotfig,'UserData',userData);
end

function highlight_bounding_box(bbox, score, object)
  plotfig = gcf;
  userData = get(plotfig,'UserData');
  subplot(2,2,2);

  % clear previous bounding box highlight and score
  if length(userData.selected_bbox) > 0
    delete(userData.selected_bbox);
    delete(userData.selected_score);
  end

  % highlight selected bounding box
  new_bbox = rectangle('Position',bbox.Position,'EdgeColor','g','LineWidth',2);

  % display the recognition score for the bounding box
  new_score = text(bbox.Position(1)+20, bbox.Position(2)+40, [object ' ' num2str(score)],...
          'Color','g','FontSize',12,'FontWeight','bold');

  % set new view to unhighlight next time
  userData.selected_bbox = new_bbox;
  userData.selected_score = new_score;
  set(plotfig,'UserData',userData);
end

function highlight_points(bbox)
end
