

scene_name = input('Enter scene_name: ', 's');
start_ind = input('Enter start index');
end_ind = input('Enter end index');



scene_path = fullfile('/playpen/ammirato/Data/RohitData', scene_name);
rgb_path =  fullfile(scene_path, 'rgb');
depth_path =  fullfile(scene_path, 'high_res_depth');
save_path = fullfile(scene_path, 'filled_high_res_depth');

mkdir(save_path);

rgb_image_names = dir(fullfile(rgb_path, '*.png'));
rgb_image_names = {rgb_image_names.name};

end_ind = max(end_ind, length(rgb_image_names));


for il=start_ind:end_ind
    fprintf('%d of %d\n', il, length(rgb_image_names)); 
    cur_rgb_name = rgb_image_names{il};
    cur_depth_name = strcat(cur_rgb_name(1:8), '03.png');
    imgRgb = imread(fullfile(rgb_path, cur_rgb_name));
    imgDepthAbs = imread(fullfile(depth_path, cur_depth_name));


    imgDepthFilled = fill_depth_colorization(double(imgRgb), double(imgDepthAbs), 1);


    img_out = uint16(imgDepthFilled);

    imwrite(img_out, fullfile(save_path, strcat(cur_rgb_name(1:8), '04.png')));
end

