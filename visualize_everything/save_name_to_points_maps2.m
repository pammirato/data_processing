% use this if you have points_2d_structs.mat and points3D.txt
% use save_name_to_points_maps.m when you have images.txt and points3D.txt

% gets all the reconstructed points for an image in the reconstruction output and
% saves them in a map data structure, in a mat file. The structure maps from image name to a
% a vector [x1,y1,ID1,x2,y2,...,xn,yn,IDn] where for each xi of the n
% reconstructed points, [xi, yi] is a pixel and IDi is the ID of the reconstructed
% 3D point corresponding to that pixel in the image.

% A second map is also saved in a separate mat file, mapping each point ID to
% a vector [X, Y, Z, R, G, B] specifying the position and color of the point.

%initialize contants, paths and file names, etc.
init;

POINT_ID  = 1;
X = 2;
Y = 3;
Z = 4;

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


    positions_path =fullfile(scene_path, RECONSTRUCTION_DIR);

%%%%%%%%%%%%%%%%%%%% Build the image name to points map %%%%%%%%%%%%%%%%%%%%%%%%

    name_to_points_structs_file = load(fullfile(scene_path,RECONSTRUCTION_DIR,NAME_TO_POINTS_STRUCTS_FILE));
    name_to_points_structs = name_to_points_structs_file.(NAME_TO_POINTS_STRUCTS);

    temp = cell2mat(name_to_points_structs);
    names = {temp.(IMAGE_NAME)};
    pixel_to_pt = {temp.(PIXEL_TO_POINT)};
    clear temp;

    name_to_points_map = containers.Map(names, pixel_to_pt);

    save(fullfile(scene_path, RECONSTRUCTION_DIR, NAME_TO_POINT_ID_MAT_FILE), NAME_TO_POINTS_MAP);


%%%%%%%%%%%%%%%%% Build point ID to [X, Y, Z, R, G, B] map %%%%%%%%%%%%%%%%%%%%%

    % get the reconstructed points
    points_file = fopen(fullfile(positions_path, POINTS_3D));
    if(points_file == -1)
        continue;
    end

    %get the first two comment lines
    fgetl(points_file);
    fgetl(points_file);

    %get the first points' line
    line = fgetl(points_file);

    %hold point IDs
    ids = cell(1,1);
    %holds data for every point
    points = cell(1,6);
    %holds data for one point
    cur_point = zeros(1,7);

    i = 1;

    %while another line of data
    while(ischar(line))

      %info is space separated
      line = strsplit(line);
      if(length(line) < 7)
          break;
      end
      cur_point = str2double(line(1:7));
      ids{i} = cur_point(1);
      points{i} = cur_point(2:7);

      %get next point line
      line = fgetl(points_file);

      i = i+1;
    end

    fclose(points_file);

    id_to_point_map = containers.Map(ids, points);
    save(fullfile(scene_path, RECONSTRUCTION_DIR, ID_TO_POINT_MAT_FILE), ID_TO_POINT_MAP);

end
