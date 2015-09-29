

function compress_jpg(room_name)

    rgb_image_path = ['/home/ammirato/Data/' room_name '/rgb/'];
    unreg_depth_image_path = ['/home/ammirato/Data/' room_name '/unreg_depth/'];
    raw_depth_image_path = ['/home/ammirato/Data/' room_name '/raw_depth/'];

    base_save_path = ['/home/ammirato/jpg_Data/' room_name]
    rgb_save_path = [base_save_path '/rgb/'];
    unreg_depth_save_path = [base_save_path '/unreg_depth/'];
    raw_depth_save_path = [base_save_path '/raw_depth/'];

    mkdir(base_save_path);
    mkdir(rgb_save_path);
    % mkdir(unreg_depth_save_path);
    % mkdir(raw_depth_save_path);

    rgb_dir = dir(rgb_image_path);
    rgb_dir = rgb_dir(3:end);

    unreg_depth_dir = dir(unreg_depth_image_path);
    unreg_depth_dir = unreg_depth_dir(3:end);



      old_name = rgb_dir(1).name;
      prefix = old_name(1:strfind(old_name, '.'));
      img = imread([rgb_image_path rgb_dir(1).name]);
      imwrite(img, [rgb_save_path prefix 'jpg']);




    for i=1:length(rgb_dir)
        i
        try
      old_name = rgb_dir(i).name;
      prefix = old_name(1:strfind(old_name, '.'));
      img = imread([rgb_image_path rgb_dir(i).name]);
      imwrite(img, [rgb_save_path prefix 'jpg']);
        catch
            disp ('phil wake up');
        end
    end

    % 
    % for i=1:length(unreg_depth_dir)
    %     i
    %   old_name = unreg_depth_dir(i).name;
    %   prefix = old_name(1:strfind(old_name, '.'));
    %   img = imread([unreg_depth_image_path unreg_depth_dir(i).name]);
    %   imwrite(img, [unreg_depth_save_path prefix 'jpeg'],'jpeg', 'Bitdepth', 16);
    % end
    % 
    % 
    % try
    % 
    % raw_depth_dir = dir(raw_depth_image_path);
    % raw_depth_dir = raw_depth_dir(3:end);
    % for i=1:length(raw_depth_dir)
    %     i
    %   old_name = raw_depth_dir(i).name;
    %   prefix = old_name(1:strfind(old_name, '.'));
    %   img = imread([raw_depth_image_path raw_depth_dir(i).name]);
    %   imwrite(img, [raw_depth_save_path prefix 'jpg'],'jpg', 'Bitdepth', 16);
    % end
    % 
    % catch
    %     disp('no raw depth');
    %      room_name
    % end
end