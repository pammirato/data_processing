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

% 
% clearvars;
%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

% scene_name = 'Home_02_2';
% scene_path = fullfile(ROHIT_BASE_PATH, scene_name);
% meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);
% pose_images_path = fullfile(meta_path,'labels/pose_images/');
% pose_image_names = dir(fullfile(pose_images_path,'*.jpg'));
% pose_image_names = {pose_image_names.name};
% pose_image_names = cell2mat(pose_image_names);
% image_names = pose_image_names(:,1:10);
% object_names = pose_image_names(:,12:end-4);
% 
% object_to_image_map = containers.Map();
% for il=1:size(image_names,1)
%   object_to_image_map(object_names(il,:)) = image_names(il,:);
% end



instance_name_to_id_map = get_instance_name_to_id_map();


base_path = '/playpen/ammirato/Data/RohitMetaMetaData/aligned_object_point_clouds/meshes';
object_names = dir(fullfile(base_path,'*.off'));
object_names = {object_names.name};


%% MAIN LOOP

class_names = cell(1,length(object_names));
cads = cell(1,length(object_names));

for il=1:length(object_names)
 
  cur_name = object_names{il};

  [vertices,faces] = load_off_file(fullfile(base_path, cur_name));


  class_names{il} = cur_name(1:end-4);
  s = struct('vertices',vertices,'faces',faces);
  cads{il} = s;
  
  
%   %make annotation for pose labeling tool
%   image_name = object_to_image_map(cur_name(1:end-4));
%   bounding_boxes = load(fullfile(meta_path,'labels','verified_labels',...
%                     'bounding_boxes_by_image_instance', ...
%                     strcat(image_name,'.mat')));
%             
%   boxes = bounding_boxes.boxes;
%   cur_id = instance_name_to_id_map(cur_name(1:end-4));
%   cur_box = boxes(boxes(:,5)==cur_id,:);
%   
%   
%   record = struct();
%   record.filename = strcat(image_name,'_',cur_name(1:end-4),'.jpg');
%   
%   objects = struct();
%   objects.class = cur_name(1:end-4);
%   objects.bbox = cur_box(1:4);
%   objects.cad_index = cur_id;
%   objects.truncated = 0;
%   objects.occluded = 0;
%   objects.difficult = 0;
%   objects.viewpoint = [];
%   
%   record.objects = objects;
%   
%   save(fullfile(meta_path,'labels','pose_labeler_annotations',...
%         strcat('n_',image_name,'.mat')),'record');
%   
  
end%for il, each object_name


save(fullfile('/playpen/ammirato/Data/RohitMetaMetaData/cads.mat'), ...
        'cads', 'class_names');
      
% save(fullfile(meta_path,'labels','cads.mat'), ...
%   'cads', 'class_names');




