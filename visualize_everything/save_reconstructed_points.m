% Saves a scene's reconstructed points in a .mat file for use
% in visualizations.

%initialize contants, paths and file names, etc.
init;

POINT_ID  = 1;
X = 2;
Y = 3;
Z = 4;
R = 5;
G = 6;
B = 7;
ERROR = 8;

fid_points = fopen(fullfile(BASE_PATH, scene_name, RECONSTRUCTION_DIR, POINTS_3D));

%get the first two comment lines
fgetl(fid_points);
fgetl(fid_points);

%get the first points' line
line = fgetl(fid_points);

%holds data for every point
points = cell(1,1);
%names = cell(1,1);

%holds data for one point
cur_point = zeros(1,B);

i = 1;

%while another line of data
while(ischar(line))

  %info is space separated
  line = strsplit(line);
  if(length(line) < B)
      break;
  end
  cur_point = str2double(line(1:B));
  points{i} = cur_point;

  %get Points2D
  line =fgetl(fid_points);

  i = i+1;
end


xs = zeros(length(points),1);
ys = zeros(length(points),1);
zs = zeros(length(points),1);
rgbs = zeros(length(points),3);

for i=1:length(points)

  cur_point = points{i};

  xs(i) = cur_point(X);
  ys(i) = cur_point(Y);
  zs(i) = cur_point(Z);
  rgbs(i,1) = cur_point(R);
  rgbs(i,2) = cur_point(G);
  rgbs(i,3) = cur_point(B);

end

point_matrix = [xs ys zs rgbs];

save(fullfile(BASE_PATH, scene_name, RECONSTRUCTION_DIR, POINTS_3D_MAT_FILE),...
     POINTS_3D_MATRIX);
