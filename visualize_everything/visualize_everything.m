% creates an interactive figure with 4 subplots:
% 1) 3D plot of all the positions in the scene where the camera took a picture
% 2) 3D plot of reconstructed world points
% 3) image corresponding to a camera view, and bounding boxes labeled
%    with recognition results for that image.
% 4) image cutout and recognition score for a selected bounding box

function visualize_everything

  %initialize constants, paths and file names, etc.
  init;
  scene_path = fullfile(BASE_PATH, scene_name);
  image_path = fullfile(scene_path, RGB_IMAGES_DIR);
  results_path = fullfile(scene_path, RECOGNITION_DIR, FAST_RCNN_RESULTS);


  % load data about each view. Each camera struct contains the image name, camera
  % position, camera orientation, translation vector, rotation matrix, quaternion
  % orientation, and scaled world position
  camera_structs_path = fullfile(scene_path,RECONSTRUCTION_DIR,CAMERA_STRUCTS_FILE);
  if (~exist(camera_structs_path,'file'))
    save_camera_structs;
  end
  camera_structs_file = load(camera_structs_path);
  camera_structs = camera_structs_file.(CAMERA_STRUCTS);
  scene_scale = camera_structs_file.scale;

  %get a list of all the image file names and corresponding camera position/orientation
  temp = cell2mat(camera_structs);
  names = {temp.(IMAGE_NAME)};
  worldpos = cell2mat({temp.(WORLD_POSITION)})';
  worlddir = cell2mat({temp.(DIRECTION)})';
  clear temp;

  %make a map from image name to camera_struct
  camera_struct_map = containers.Map(names, camera_structs);

  % sort the camera view data so we can move through views in order
  [names, camera_structs, worldpos, worlddir] = sort_image_data(names, camera_structs, worldpos, worlddir);

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
    save_name_to_points_maps2;
  end
  name_to_point_ids = load(name_to_point_id_path);
  name_to_point_ids = name_to_point_ids.(NAME_TO_POINTS_MAP);

  id_to_point_path = fullfile(scene_path, RECONSTRUCTION_DIR, ID_TO_POINT_MAT_FILE);
  id_to_point = load(id_to_point_path);
  id_to_point = id_to_point.(ID_TO_POINT_MAP);

  % set up the display figure with subplots for camera positions, images, etc
  plotfig = figure('units','normalized','outerposition',[0 0 1 1]);
  % set up UserData for the figure to save data and display elements between events
  data = struct('link', [],...
                'scene_path', scene_path,...
                'image_path', image_path,...
                'results_path', results_path,...
                'index', 1,...
                'highlight_index', -1,...
                'names', cell(1,1),...
                'scale', scene_scale,...
                'worldpos', worldpos,...
                'worlddir', worlddir,...
                'bboxes', cell(1,1),...
                'scores', cell(1,1),...
                'categories', cell(1,1),...
                'points', [],...
                'selected_view', [],...
                'selected_bbox', [],...
                'selected_point', [],...
                'bbox_img', [],...
                'bbox_depth_img', [],...
                'bbox_points', [],...
                'views_of_object', [],...
                'views_indices', [],...
                'name_to_camera_struct', camera_struct_map,...
                'name_to_point_ids', name_to_point_ids,...
                'id_to_point', id_to_point);
  data.names = names;
  set(plotfig, 'UserData', data);

  view_axes = display_camera_views(worldpos(:,1), worldpos(:,2), worldpos(:,3),...
                                   worlddir(:,1), worlddir(:,2), worlddir(:,3));

  point_axes = display_reconstructed_points(points3D);

  % link axes together so they rotate together in rotate3d mode
  hlink = linkprop([view_axes,point_axes], {'CameraPosition','CameraUpVector',...
                   'CameraTarget', 'CameraViewAngle'});
  userData = get(plotfig, 'UserData');
  userData.link = hlink;
  set(plotfig, 'UserData', userData);

  % display results for the first image so the display isn't blank.
  highlight_camera_view(1);
  image_axes = display_image(1);
  display_bounding_boxes(1);
  select_bounding_box(700, 800);
  select_object(259,257);

  % set up buttons for iterating through images
  t = uitoolbar(plotfig);
  [pathstr, name, ext] = fileparts(which('visualize_everything'));

  img_la = imread(fullfile(pathstr,'leftarrow.jpg'));
  leftarrow = uipushtool(t,'TooltipString','Previous view','CData',img_la,...
                 'ClickedCallback', @switchViewCallback);
  img_ra = imread(fullfile(pathstr,'rightarrow.jpg'));
  rightarrow = uipushtool(t,'TooltipString','Next view','CData',img_ra,...
                 'ClickedCallback', @switchViewCallback);
  img_lab = imread(fullfile(pathstr,'leftarrowblue.jpg'));
  leftarrow_blue = uipushtool(t,'TooltipString','Previous highlighted view','CData',img_lab,...
                  'ClickedCallback', @switchViewCallback);
  img_rab = imread(fullfile(pathstr,'rightarrowblue.jpg'));
  rightarrow = uipushtool(t,'TooltipString','Next highlighted view','CData',img_rab,...
                  'ClickedCallback', @switchViewCallback);


  % set figure to call pick_data when a data point is selected
  % by the user in data cursor mode
  dcm_obj = datacursormode(plotfig); % get the data cursor object
  set(dcm_obj, 'UpdateFcn', {@pick_data, view_axes, image_axes, point_axes});

  rotate_obj = rotate3d;
  rotate_obj.Enable = 'on';
  rotate_obj.RotateStyle = 'box';
  setAllowAxesRotate(rotate_obj, image_axes, false);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% UI callbacks and other misc. functions %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This function gets called when the user clicks in data cursor mode.
% Based on what subplot axes the event came from, choose the correct response.
function output = pick_data(~, event_obj, view_axes, image_axes, point_axes)
  output = [];
  targetAxes = get(event_obj.Target, 'parent');
  cursor = get(event_obj);

  if isequal(targetAxes, view_axes)
    select_view_for_point(event_obj);
  elseif isequal(targetAxes, image_axes)
    select_bounding_box(cursor.Position(1), cursor.Position(2));
  elseif isequal(targetAxes, point_axes)
    %select_reconstructed_point(cursor.Position);
  else % must be the bottom-right subplot
    select_object(cursor.Position(1), cursor.Position(2));
  end
end

function output = switchViewCallback(source, event_data)
  userData = get(gcf, 'UserData');
  num_views = length(userData.names);
  hviews = userData.views_indices;
  idx = userData.index;
  hidx = userData.highlight_index;

  if strcmp(source.TooltipString, 'Next view')
    if idx >= num_views-2
      select_view(1);
    else
      % increment by 3 since 3 pictures are taken at each position, this keeps
      % it at the same elevation but changes the angle/location
      select_view(idx + 3);
    end
  elseif strcmp(source.TooltipString, 'Previous view')
    if idx <= 3
      select_view(num_views);
    else
      select_view(idx - 3);
    end
  elseif strcmp(source.TooltipString, 'Next highlighted view')
    if length(hviews) < 1
      return;
    end
    if hidx == -1 && ~ismember(idx, hviews)
      select_view(hviews(1));
    else
      vidx = find(hviews==idx);
      if (idx >= hviews(end))
        select_view(hviews(1));
      else
        select_view(hviews(vidx+1));
      end
    end
  elseif strcmp(source.TooltipString, 'Previous highlighted view')
    if length(hviews) < 1
      return;
    end
    if hidx == -1 && ~ismember(idx, hviews)
      select_view(hviews(1));
    else
      vidx = find(hviews==idx);
      if (idx <= hviews(1))
        select_view(hviews(end));
      else
        select_view(hviews(vidx-1));
      end
    end
  end
end

% sorts image names and position/orientation data into alphabetical order by
% by image name. The numbers in the image names must be padded first for the
% sorting to work properly. Then the images are in the order they were taken
% by the robot.
function [snames, sstructs, spos, sdir] = sort_image_data(names, structs, pos, dirs)

  [snames, index] = sort(names);
  sstructs = structs(index);
  spos = pos(index,:);
  sdir = dirs(index,:);
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
function select_view_for_point(event_obj)
  userData = get(gcf, 'UserData');
  worldpos = userData.worldpos;
  cursor = get(event_obj);

  % get index of data point selected by cursor
  [distance, i] = pdist2(worldpos, cursor.Position, 'euclidean', 'Smallest', 1);
  userData.index = i;
  set(gcf, 'UserData', userData);

  select_view(i)
end

function select_view(idx)
  userData = get(gcf, 'UserData');
  subplot(2,2,1);

  userData.index = idx;
  if ismember(idx, userData.views_indices)
    userdata.highlight_index = idx;
  end
  set(gcf, 'UserData', userData);

  highlight_camera_view(idx);
  display_image(idx);
  display_bounding_boxes(idx);
end

% highlights the direction camera was facing for the image capture idx
function highlight_camera_view(idx)
  userData = get(gcf, 'UserData');
  worldpos = userData.worldpos;
  worlddir = userData.worlddir;
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
  set(gcf, 'UserData', userData);
end

% Highlight camera orientation for given array of indices
function highlight_views_of_object(views)
  userData = get(gcf, 'UserData');
  subplot(2,2,1);

  % clear previous views highlight
  if length(userData.views_of_object) > 0
    delete(userData.views_of_object);
  end

  worldpos = userData.worldpos;
  worlddir = userData.worlddir;

  % highlight camera view for selected data point
  new_highlight = quiver3(worldpos(views,1), worldpos(views,2), worldpos(views,3),...
                      worlddir(views,1), worlddir(views,2), worlddir(views,3),...
                      'Color', 'c', 'LineWidth', 2.0);

  % set views to unhighlight next time
  userData.views_of_object = new_highlight;
  set(gcf,'UserData',userData);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%% Functions for top-right subplot display %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% displays image specified by idx
function ax = display_image(idx)
  userData = get(gcf, 'UserData');
  ax = subplot(2,2,2);

  image_name = userData.names{idx};
  image_name = [image_name(1:11) 'jpg'];

  imshow([userData.image_path image_name]);
  hold on;
end

% displays bounding boxes with top recognition scores
% for the image specified by idx
function display_bounding_boxes(idx)
  userData = get(gcf, 'UserData');
  subplot(2,2,2);

  % clear existing display of recognition results
  for j = 1:size(userData.bboxes,2)
    delete(userData.bboxes{j});
  end
  userData.bboxes = cell(1,1);
  userData.scores = cell(1,1);
  userData.categories = cell(1,1);

  % load recognition results. 'dets' struct gets loaded.
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

  % sort recongition scores into descending order, then sort category labels to match
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
    % save recognition score and category for this bounding box
    userData.scores{i} = score;
    userData.categories{i} = categories{i};
  end

  set(gcf, 'UserData', userData);
end

function select_bounding_box(x, y);
  userData = get(gcf, 'UserData');
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
    display_image_portion(userData.index, pos);
    display_recognition_score(selected_score, selected_category);
    highlight_points(selected_bbox);
  end
end

function highlight_bounding_box(bbox, score, object)
  userData = get(gcf,'UserData');
  subplot(2,2,2);

  % clear previous bounding box highlight
  if length(userData.selected_bbox) > 0
    delete(userData.selected_bbox);
  end

  % highlight selected bounding box
  new_bbox = rectangle('Position', bbox.Position, 'EdgeColor', 'g', 'LineWidth', 2);

  % set new box to unhighlight next time
  userData.selected_bbox = new_bbox;
  set(gcf, 'UserData', userData);
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

function select_reconstructed_point(position)
  userData = get(gcf,'UserData');
  clusters = userData.bbox_points;
  distance_to_cluster = zeros(length(clusters),1);

  % choose cluster closest to selected point
  for i=1:length(clusters)
    points = [(clusters{i}.XData)' (clusters{i}.YData)' (clusters{i}.ZData)'];
    distance_to_cluster(i) = pdist2(points, position, 'euclidean', 'Smallest', 1);
  end
  [m, idx] = min(distance_to_cluster);

  % highlight selected cluster
  clusters{idx}.MarkerFaceColor = 'c';

  % highlight views that can see the object identified by the chosen cluster
  points = [(clusters{idx}.XData)' (clusters{idx}.YData)' (clusters{idx}.ZData)'];
  get_all_views_of_object(points);
end

function highlight_points(bbox)
  userData = get(gcf,'UserData');
  subplot(2,2,3);

  % clear previously highlighted points
  if length(userData.bbox_points) > 0
    for i=1:length(userData.bbox_points)
      delete(userData.bbox_points{i});
    end
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

  points = values(userData.id_to_point, pt_ids);
  points = cell2mat(points);
  X = zeros(num_pts, 1);
  Y = zeros(num_pts, 1);
  Z = zeros(num_pts, 1);

  for i=0:num_pts-1
    X(i+1) = points((i*6)+1);
    Y(i+1) = points((i*6)+2);
    Z(i+1) = points((i*6)+3);
  end

  points = [X Y Z];
  eva = evalclusters(points,'linkage','silhouette','KList',[1:10]);
  idx = clusterdata([X Y Z], eva.OptimalK);

  bbox_points = cell(1,1);
  colors = ['g' 'r' 'b' 'y' 'm'];
  colors = [colors colors];

  for i=1:eva.OptimalK
    bbox_points{i} = scatter3(X(idx==i), Y(idx==i), Z(idx==i), 50, colors(i), 'filled');
  end

  userData.bbox_points = bbox_points;
  set(gcf,'UserData',userData);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% Functions for bottom-right subplot display %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% pos is the bounding box Position field, [x y w h]
function display_image_portion(idx, pos)
  userData = get(gcf,'UserData');
  subplot(2,2,4);

  if length(userData.bbox_img) > 0
    delete(userData.bbox_img);
    delete(userData.bbox_depth_img)
  end

  xmin = int16(max([pos(1) 1]));
  ymin = int16(max([pos(2) 1]));
  xmax = int16(min([pos(1)+pos(3) 1920]));
  ymax = int16(min([pos(2)+pos(4) 1080]));

  image_name = userData.names{idx};
  image_name = [image_name(1:11) 'jpg'];

  img = imread([userData.image_path image_name]);
  himage = imshow(img(ymin:ymax, xmin:xmax, :));
  hold on;

  % overlay depth image
  suffix_index = 11;
  depth_name = [image_name(1:9) '3.png'];
  raw_depth = imread(fullfile(userData.scene_path, ['raw_depth/' depth_name]));
  depth_image = imagesc(raw_depth(ymin:ymax, xmin:xmax, :));
  set(depth_image,'AlphaData',.5);

  % overlay object segmentation outline
  seg_img = extract_foreground(image_name, pos);
  seg_img = im2bw(seg_img, 2/255);
  [B,L] = bwboundaries(seg_img,'noholes');
  seg_img = seg_img .* 85;
  plotfig = gcf;
  newfig = figure;
  imshow(seg_img);
  hold on;
  for k = 1:length(B)
    boundary = B{k};
    plot(boundary(:,2), boundary(:,1), 'r', 'LineWidth', 2)
  end
  figure(plotfig);

  userData.bbox_img = himage;
  userData.bbox_depth_img = depth_image;
  set(gcf,'UserData',userData);
end

function display_recognition_score(score, object)

  subplot(2,2,4);

  % display the recognition score for the bounding box
  title([object ':  ' num2str(score)]);
end

function select_object(x, y)
  userData = get(gcf,'UserData');

  r = userData.selected_bbox;
  x = x + r.Position(1);
  y = y + r.Position(2);

  views = get_all_views_of_object(userData.names{userData.index}, x, y);
  userData.views_indices = views;
  set(gcf,'UserData',userData);

  highlight_views_of_object(views);
end
