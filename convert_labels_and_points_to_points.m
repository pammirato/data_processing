%takes a file with points and labels, and makes a new file with just the points
%

room_name = 'KitchenLiving12';

load_path = ['/home/ammirato/Data/' room_name '/' 'all_labeled_points.txt'];
save_path = ['/home/ammirato/Data/' room_name '/' 'all_points.txt'];




fid_load = fopen(load_path);
fid_save = fopen(save_path, 'wt');

fgetl(fid_load);
fgetl(fid_load);
line = fgetl(fid_load);

line = fgetl(fid_load);
while(ischar(line))

 
  fprintf(fid_save, [line '\n']);
  
  %get label
  line =fgetl(fid_load);
  line =fgetl(fid_load);
  
end
