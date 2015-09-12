

points_path = 'home/ammirato/Documents/objects';

object_name = 'cup';


fid = fopen([points_path object_name], 'r');


fgetl(fid);
fgetl(fid);
line = fgetl(fid);

points = cell(1,1);

i = 1;
cur_point = -ones(1,3);

while(ischar(line))

  %get point info
  line = fgetl(fid_images);
  line = strsplit(line);

  cur_point(1,1) = str2num(line(1)); 
  cur_point(1,2) = str2num(line(2)); 
  cur_point(1,3) = str2num(line(3)); 
 
  points{i} = cur_point;

  i = i+1;
end






