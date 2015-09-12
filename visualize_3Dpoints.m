POINT_ID  = 1;
X = 2;
Y = 3;
Z = 4;
R = 5;
G = 6;
B = 7;
ERROR = 8;


%where to read points from
points_path = '/home/ammirato/results1/shared-intrinsics-fisheye/';

fid_points = fopen([points_path 'points3D.txt']);

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



scatter3(xs,ys,zs,10,rgbs/255.0,'filled');
axis equal;
axis([-30 30 -1 3 -30 30]);
