%show a figure with the camera positions plotted in 3D for a scene, 
%possible also show a line coming from each point indicating the 
%orientation of the camera at that point

%initialize contants, paths and file names, etc. 
init;



scene_name = 'all'; %make this = 'all' to run all scenes

%should the lines indicating orientation be drawn?
view_orientation = 1;


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

    save_path = fullfile(BASE_PATH, 'tosend', scene_name);
    mkdir(save_path);
    mkdir(fullfile(save_path, 'rgb'));
    mkdir(fullfile(save_path, 'depth'));


    scene_dir = dir(fullfile(scene_path, 'rgb'));
    scene_dir = scene_dir(3:end);

    rgb_names = {scene_dir.name};


    for k=1:floor(length(rgb_names)/100)+1:length(rgb_names)
      copyfile(fullfile(scene_path,'rgb',rgb_names{k}), fullfile(save_path,'rgb',rgb_names{k}));
     
      suffix = rgb_names{k};
      suffix = suffix(strfind(suffix,'b')+1:end);
      depth_name = strcat('raw_depth', suffix); 

      copyfile(fullfile(scene_path,'raw_depth',depth_name), ...
                          fullfile(save_path, 'depth',depth_name)); 
    end
    

end%for each scene


