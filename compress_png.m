%losselss compression rgb, unreg_depth, raw_depth 


function compress_png(room_name)

rgb_image_path = ['/home/ammirato/Data/' room_name '/rgb/'];
unreg_depth_image_path = ['/home/ammirato/Data/' room_name '/unreg_depth/'];
raw_depth_image_path = ['/home/ammirato/Data/' room_name '/raw_depth/'];

base_save_path = ['/home/ammirato/png_compressed_Data/' room_name]
rgb_save_path = [base_save_path '/rgb/'];
unreg_depth_save_path = [base_save_path '/unreg_depth/'];
raw_depth_save_path = [base_save_path '/raw_depth/'];

mkdir(base_save_path);
mkdir(rgb_save_path);
mkdir(unreg_depth_save_path);
mkdir(raw_depth_save_path);

rgb_dir = dir(rgb_image_path);
rgb_dir = rgb_dir(3:end);

unreg_depth_dir = dir(unreg_depth_image_path);
unreg_depth_dir = unreg_depth_dir(3:end);




for i=1:length(rgb_dir)
    i
    try
  img = imread([rgb_image_path rgb_dir(i).name]);
  imwrite(img, [rgb_save_path rgb_dir(i).name]);
    catch
        disp ('phil wake up');
    end
end


for i=1:length(unreg_depth_dir)
    i
  img = imread([unreg_depth_image_path unreg_depth_dir(i).name]);
  imwrite(img, [unreg_depth_save_path unreg_depth_dir(i).name]);
end


try

raw_depth_dir = dir(raw_depth_image_path);
raw_depth_dir = raw_depth_dir(3:end);
for i=1:length(raw_depth_dir)
    i
  img = imread([raw_depth_image_path raw_depth_dir(i).name]);
  imwrite(img, [raw_depth_save_path raw_depth_dir(i).name]);
end

catch
    disp('no raw depth');
    room_name
end


end

