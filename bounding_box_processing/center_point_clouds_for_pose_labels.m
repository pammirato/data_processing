%function classify_boxes(scene_name, label_type)
%
%INPUTS:
%         scene_name: char array of single scene name, 'all' for all scenes, 
%                     or a cell array of char arrays, one for each desired scene
%         label_type: OPTIONAL 'verified_labels'(default) or 'raw_labels'
%

%TODO

%CLEANED - no 
%TESTED - no


clearvars;
%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Home_02_2'; %make this = 'all' to run all scenes
model_number = '0';
%use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
%custom_scenes_list = {'Bedroom_01_1', 'Kitchen_Living_01_1', 'Kitchen_Living_02_1', 'Kitchen_Living_03_1', 'Kitchen_Living_04_2', 'Kitchen_05_1', 'Kitchen_Living_06', 'Office_01_1'};%populate this 





%which instances to use
label_to_process = 'advil_liqui_gels'; %make 'all' for every label
label_names = {label_to_process};

% if(nargin <2)
   label_type = 'verified_labels';  %raw_labels - automatically generated labels
% end                                %verified_labels - boxes looked over by human


debug =0;

kImageWidth = 1920;
kImageHeight = 1080;
%% SET UP GLOBAL DATA STRUCTURES


%get the names of all the scenes
d = dir(ROHIT_BASE_PATH);
d = d(3:end);
all_scenes = {d.name};


%determine which scenes are to be processed 
if(iscell(scene_name))
  %if we are using the custom list of scenes
  all_scenes = scene_name;
elseif(~strcmp(scene_name, 'all'))
  %if not using custom, or all scenes, use the one specified
  all_scenes = {scene_name};
end




%% MAIN LOOP

for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il};
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);

  %get the names of all the labels
  if(strcmp(label_to_process, 'all'))
    instance_name_to_id_map = get_instance_name_to_id_map();
    label_names = keys(instance_name_to_id_map);
  end





  %% get info about camera position for each image
  image_structs_file =  load(fullfile(meta_path,'reconstruction_results', ...
                                'colmap_results', model_number,IMAGE_STRUCTS_FILE));
  image_structs = image_structs_file.(IMAGE_STRUCTS);
  scale  = image_structs_file.scale;

  %get a list of all the image file names
  image_names = {image_structs.(IMAGE_NAME)};

  %make a map from image name to image_struct
  image_structs_map = containers.Map(image_names,...
                                 cell(1,length(image_names)));
  %populate the map
  for jl=1:length(image_names)
    image_structs_map(image_names{jl}) = image_structs(jl);
  end







  %for each  instance label
  for jl=1:length(label_names)
    
    %get the name of the label
    cur_label_name = label_names{jl};
    disp(cur_label_name);%display progress

    %load the labeled point cloud for this label in this scene
    try
      cur_pc = pcread(fullfile(meta_path,LABELING_DIR, ...
                    OBJECT_POINT_CLOUDS, strcat(cur_label_name, '.ply')));
                  
      cur_pc = pcread(fullfile('/playpen/ammirato/Data/RohitMetaMetaData/', ...
                    'aligned_object_point_clouds', strcat(cur_label_name, '.ply')));
    catch
      %this instance does not have a point cloud
      disp([cur_label_name ' has no point cloud!']);
      continue;
    end
  

    %center the point cloud around zero
%     locations = cur_pc.Location;
%     com = mean(locations);
%     centered_locations = locations - repmat(com, size(locations,1),1);
%     
%     cur_pc = pointCloud(centered_locations, 'Color',cur_pc.Color);
    
%     pcwrite(cur_pc, fullfile('/playpen/ammirato/Data/RohitMetaMetaData/aligned_object_point_clouds', ...
%                     strcat(cur_label_name, '.ply')));
    
    pcshow(cur_pc);
%     hold on;
%     set(gca,'CameraPosition',[0 0 1]);
%     zoom on;
%     zoom(.25);
%     lims = axis;
%     set(gca,'Visible','off');
%     plot3(lims(1:2),[0 0], [0 0], 'r-', 'LineWidth',3);
%     plot3([0 0],lims(3:4), [0 0], 'b-','LineWidth',3);
%     plot3([0 0], [0 0],lims(5:6), 'g-','LineWidth',3);
%     
%     
%     cur_axis = ' ';
%     while(cur_axis ~= 'q')
%       cur_axis = input('Enter axis: ', 's');
%       angle = input('Enter angle: ');
%       
%       tform = get_affine3d_transform_matrix(cur_axis,angle);
%       
%       cur_pc = pctransform(cur_pc, tform);
%       
%       hold off;
%       pcshow(cur_pc);
%       hold on;
%       set(gca,'CameraPosition',[0 0 1]);
%       zoom on;
%       zoom(.25);
%       lims = axis;
%       set(gca,'Visible','off');
%       plot3(lims(1:2),[0 0], [0 0], 'r-', 'LineWidth',3);
%       plot3([0 0],lims(3:4), [0 0], 'b-','LineWidth',3);
%       plot3([0 0], [0 0],lims(5:6), 'g-','LineWidth',3);
%                
%     end
%       
    breakp = 1;

  end%for jl, each instance label name 

end%for il, each scene_name



