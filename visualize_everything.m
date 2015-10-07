% creates an interactive figure with 2 subplots:
% 1) 3D plot of all the positions in the scene where the camera took a picture
% 2) image corresponding to a camera position, and bounding boxes labeled
%    with recognition results for that image.

function visualize_with_bboxes

  scene_name = 'SN208';

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
  name_to_camera_data = load(fullfile(BASE_PATH, scene_name, RECONSTRUCTION_DIR, NAME_TO_POS_DIRS_MAT_FILE));
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

  % set up the display figure with subplots for camera positions, images, etc
  plotfig = figure;
  subplot(1,2,1);
  scatter3(X,Y,Z,'r.'); %plot camera positions in X and Z
  hold on;
  quiver3(X,Y,Z,Xdir,Ydir,Zdir,'ShowArrowHead','off');

  axis equal;
  view(-4,-66); % set a nicer viewing angle
  print(save_figure_path,'-djpeg'); % save a JPEG image of the figure
  savefig(save_figure_path); % save figure in FIG format

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
