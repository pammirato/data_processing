base_path = '/home/ammirato/Data/';

dirs = dir(base_path);
dirs = dirs(3:end);


     
     
for i=1:length(dirs)
    compress_jpg(dirs(i).name);
end