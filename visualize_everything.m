% creates an interactive figure with 4 subplots:
% 1) 3D plot of all the positions in the scene where the camera took a picture
% 2) 3D plot of reconstructed world points
% 3) image corresponding to a camera view, and bounding boxes labeled
%    with recognition results for that image.
% 4) image cutout and recognition score for a selected bounding box

function visualize_everything

  scene_name = 'SN208';

  %should the lines indicating orientation be drawn?
  view_orientation = 1;

  %initialize constants, paths and file names, etc.
  init;
  scene_path = fullfile(BASE_PATH, scene_name);
  image_path = fullfile(scene_path, RGB_IMAGES_DIR);
  results_path = fullfile(scene_path, RECOGNITION_DIR, FAST_RCNN_RESULTS);

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
  posdir_values = cell2mat(name_to_camera_data.values);

  %each image has a data vector 6 long, so index every 6
  X = posdir_values(1:6:end-5);
  Y = posdir_values(2:6:end-4);
  Z = posdir_values(3:6:end-3);
  Xdir = posdir_values(4:6:end-2);
  Ydir = posdir_values(5:6:end-1);
  Zdir = posdir_values(6:6:end);

  worldpos = [X' Y' Z'];
  worlddir = [Xdir' Ydir' Zdir'];

  % load reconstructed 3d points for the scene
  points3D_path = fullfile(scene_path, RECONSTRUCTION_DIR, POINTS_3D_MAT_FILE);
  if (~exist(points3D_path,'file'))
    save_reconstructed_points;
  end
  points3D = load(points3D_path);
  points3D = points3D.point_matrix;

  % load map from image name to point IDs and map from point ID to point data
  % load reconstructed 3d points for the scene
  name_to_point_id_path = fullfile(scene_path, RECONSTRUCTION_DIR, NAME_TO_POINT_ID_MAT_FILE);
  if (~exist(name_to_point_id_path,'file'))
    save_name_to_points_maps;
  end
  name_to_point_ids = load(name_to_point_id_path);
  name_to_point_ids = name_to_point_ids.(NAME_TO_POINTS_MAP);

  id_to_point_path = fullfile(scene_path, RECONSTRUCTION_DIR, ID_TO_POINT_MAT_FILE);
  id_to_point = load(id_to_point_path);
  id_to_point = id_to_point.(ID_TO_POINT_MAP);

  % set up the display figure with subplots for camera positions, images, etc
  plotfig = figure;
  % set up UserData for the figure to save data and display elements between events
  data = struct('link', [],...
                'index', 1,...
                'names', cell(1,1),...
                'image_path', image_path,...
                'results_path', results_path,...
                'bboxes', cell(1,1),...
                'scores', cell(1,1),...
                'categories', cell(1,1),...
                'points', [],...
                'selected_view', [],...
                'selected_bbox', [],...
                'selected_point', [],...
                'bbox_img', [],...
                'bbox_points', [],...
                'name_to_point_ids', name_to_point_ids,...
                'id_to_point', id_to_point);
  data.names = names;
  set(plotfig, 'UserData', data);

  view_axes = display_camera_views(X, Y, Z, Xdir, Ydir, Zdir);
  point_axes = display_reconstructed_points(points3D);

  % link axes together so they rotate together in rotate3d mode
  hlink = linkprop([view_axes,point_axes], {'CameraPosition','CameraUpVector',...
                   'CameraTarget', 'CameraViewAngle'});
  userData = get(plotfig, 'UserData');
  userData.link = hlink;
  set(plotfig, 'UserData', userData);

  % display results for the first image so the display isn't blank.
  highlight_camera_view(1, worldpos, worlddir);
  image_axes = display_image(1);
  display_bounding_boxes(1);
  select_bounding_box(700, 800);

  % set figure to call pick_data when a data point is selected
  % by the user in data cursor mode
  dcm_obj = datacursormode(plotfig); % get the data cursor object
  set(dcm_obj, 'UpdateFcn', {@pick_data, worldpos, worlddir, view_axes,...
                              image_axes, point_axes});

  rotate_obj = rotate3d;
  rotate_obj.Enable = 'on';
  rotate_obj.RotateStyle = 'box';
  setAllowAxesRotate(rotate_obj, image_axes, false);
end

% This function gets called when the user clicks in data cursor mode.
% Based on what subplot axes the event came from, choose the correct response.
function output = pick_data(~, event_obj, worldpos, worlddir, view_axes,...
                            image_axes, point_axes)

  targetAxes = get(event_obj.Target, 'parent');

  if isequal(targetAxes, view_axes)
    output = [];
    select_view(event_obj, worldpos, worlddir);
  elseif isequal(targetAxes, image_axes)
    output = [];
    cursor = get(event_obj);
    select_bounding_box(cursor.Position(1), cursor.Position(2));
  elseif isequal(targetAxes, point_axes)
    output = 'reconstructed points';
    select_reconstructed_point();
  end

end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% Functions for top-left subplot display %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ax = display_camera_views(X, Y, Z, Xdir, Ydir, Zdir)
  ax = subplot(2,2,1);
  scatter3(X, Y, Z, 'r.'); %plot camera positions in X and Z
  hold on;
  quiver3(X, Y, Z, Xdir, Ydir, Zdir, 'ShowArrowHead', 'off');

  axis equal;
  axis vis3d;
  view(-4, -66); % set a nicer viewing angle
end

% This function highlights a camera position and direction in response to
% the user clicking on a data point, and displays the image and recognition
% results corresponding to that capture.
function select_view(event_obj, worldpos, worlddir)
  cursor = get(event_obj);
  plotfig = gcf;
  userData = get(plotfig, 'UserData');
  subplot(2,2,1);

  % get index of data point selected by cursor
  [distance, i] = pdist2(worldpos, cursor.Position, 'euclidean', 'Smallest', 1);
  userData.index = i;
  set(plotfig, 'UserData', userData);

  highlight_camera_view(i, worldpos, worlddir);
  display_image(i);
  display_bounding_boxes(i);
end

% highlights the direction camera was facing for the image capture idx
function highlight_camera_view(idx, worldpos, worlddir)

  plotfig = gcf;
  userData = get(plotfig, 'UserData');
  subplot(2,2,1);

  % clear previous view highlight
  if length(userData.selected_view) > 0
    delete(userData.selected_view);
  end

  % highlight camera view for selected data point
  new_highlight = quiver3(worldpos(idx,1), worldpos(idx,2), worldpos(idx,3),...
                      worlddir(idx,1), worlddir(idx,2), worlddir(idx,3),...
                      'Color', 'b', 'LineWidth', 3.0, 'AutoScaleFactor', 1.5);

  % set new view to unhighlight next time
  userData.selected_view = new_highlight;
  set(plotfig, 'UserData', userData);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% Functions for top-right subplot display %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% displays image specified by idx
function ax = display_image(idx)
  plotfig = gcf;
  userData = get(plotfig, 'UserData');
  ax = subplot(2,2,2);

  imshow([userData.image_path userData.names{idx}]);
  hold on;
end

% displays bounding boxes with top detection scores
% for the image specified by idx
function display_bounding_boxes(idx)

  plotfig = gcf;
  userData = get(plotfig, 'UserData');
  subplot(2,2,2);

  % clear existing display of recognition results
  for j = 1:size(userData.bboxes,2)
    delete(userData.bboxes{j});
  end
  userData.bboxes = cell(1,1);
  userData.scores = cell(1,1);
  userData.categories = cell(1,1);

  % load detection results. 'dets' struct gets loaded.
  [pathstr, name, ext] = fileparts(userData.names{idx});
  load([userData.results_path name '.mat']);

  % pick out detections from the categories we're looking for.
  det_tables = {'sofa' 'person' 'monitor' 'diningtable' 'bottle' 'pottedplant' 'chair'};
  categories = cell(1,1);
  num_categories = 0;
  boxes_scores = [];
  % build array of scores and array category labels that matches up with scores
  for i=1:7
    cur_category = det_tables{i};
    detections = getfield(dets, cur_category);
    boxes_scores = [boxes_scores; detections];
    for j=1:size(detections, 1)
      categories{num_categories+1,1} = cur_category;
      num_categories = num_categories + 1;
    end
  end

  % sort detection scores into descending order, then sort category labels to match
  [boxes_scores, SortIndex] = sortrows(boxes_scores, -5);
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

  set(plotfig, 'UserData', userData);
end

function select_bounding_box(x, y);
  plotfig = gcf;
  userData = get(plotfig, 'UserData');
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
    highlight_bounding_box(selected_bbox, selected_score, selected_category);
    pos = selected_bbox.Position;
    display_image_portion(userData.index, pos(1), pos(1)+pos(3), pos(2), pos(2)+pos(4));
    display_detection_score(selected_score, selected_category);
    highlight_points(selected_bbox);
  end
end

function highlight_bounding_box(bbox, score, object)
  plotfig = gcf;
  userData = get(plotfig,'UserData');
  subplot(2,2,2);

  % clear previous bounding box highlight
  if length(userData.selected_bbox) > 0
    delete(userData.selected_bbox);
  end

  % highlight selected bounding box
  new_bbox = rectangle('Position', bbox.Position, 'EdgeColor', 'g', 'LineWidth', 2);

  % set new box to unhighlight next time
  userData.selected_bbox = new_bbox;
  set(plotfig, 'UserData', userData);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Functions for bottom-left subplot display %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% display reconstructed 3D points from the scene
function ax = display_reconstructed_points(points)

    ax = subplot(2,2,3);
    % only take a small subset of points, otherwise there are too many for
    % matlab to handle easily.
    points = points(1:15:end,:);
    % some points outside the scene end up being produced in error,
    % so I try to cut out most of those by only plotting points whose
    % positions are within some distance of the mean in each direction.
    std_devs = std(points(:,1:3));
    means = mean(points(:,1:3));
    xlimit = 1.5*std_devs(1);
    ybottom = 1.5*std_devs(2);
    ytop = 3*std_devs(2);
    zlimit = 1.5*std_devs(3);
    scatter3(points(:,1), points(:,2), points(:,3), 10,...
             points(:,4:6)/255.5, 'filled');
    hold on;
    axis equal;
    axis vis3d;
    axis([-xlimit xlimit -ybottom ytop -zlimit zlimit]);
end

function select_reconstructed_point();
end

function highlight_points(bbox)
  plotfig = gcf;
  userData = get(plotfig,'UserData');
  subplot(2,2,3);

  % clear previously highlighted points
  if length(userData.bbox_points) > 0
    delete(userData.bbox_points);
  end

  % get IDs for 3D points seen in the current image
  name2pt = userData.name_to_point_ids(userData.names{userData.index});
  bbox_pos = userData.selected_bbox.Position;
  xmin = bbox_pos(1);
  xmax = xmin + bbox_pos(3);
  ymin = bbox_pos(2);
  ymax = ymin + bbox_pos(4);
  pt_ids = cell(1,1);
  num_pts = 0;

  for i=1:3:length(name2pt)
    x = name2pt(i);
    y = name2pt(i+1);
    % find all reconstructed points within bounding box whose point ID is not -1
    if (x > xmin && x < xmax && y > ymin && y < ymax && name2pt(i+2) ~= -1)
      num_pts = num_pts + 1;
      pt_ids{num_pts} = name2pt(i+2);
    end
  end

  points = values(userData.id_to_point,pt_ids);
  points = cell2mat(points);
  X = zeros(num_pts, 1);
  Y = zeros(num_pts, 1);
  Z = zeros(num_pts, 1);

  for i=0:num_pts-1
    X(i+1) = points((i*6)+1);
    Y(i+1) = points((i*6)+2);
    Z(i+1) = points((i*6)+3);
  end

  bbox_points = scatter3(X, Y, Z, 50, 'g', 'filled');
  userData.bbox_points = bbox_points;
  set(plotfig,'UserData',userData);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Functions for bottom-right subplot display %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function display_image_portion(idx, xmin, xmax, ymin, ymax)
  plotfig = gcf;
  userData = get(plotfig,'UserData');
  subplot(2,2,4);

  if length(userData.bbox_img) > 0
    delete(userData.bbox_img);
  end

  xmin = int16(max([xmin 1]));
  ymin = int16(max([ymin 1]));
  xmax = int16(min([xmax 1920]));
  ymax = int16(min([ymax 1080]));

  img = imread([userData.image_path userData.names{idx}]);
  himage = imshow(img(ymin:ymax, xmin:xmax, :));

  userData.bbox_img = himage;
  set(plotfig,'UserData',userData);
end

function display_detection_score(score, object)

  subplot(2,2,4);

  % display the recognition score for the bounding box
  title([object ':  ' num2str(score)]);
end
