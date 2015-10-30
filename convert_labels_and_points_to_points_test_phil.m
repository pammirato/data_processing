%takes a file with points and labels, and makes a new file with just the points
%
%for use with sparse_object_point_labeling.m and
%find_images_that_see_point.m

init;

scene_name = 'Room15';



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






    load_path = fullfile(scene_path, 'all_labeled_points.txt');
    save_path = fullfile(scene_path, 'all_points.txt');




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
end
