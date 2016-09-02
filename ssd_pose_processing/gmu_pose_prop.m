





base_path = fullfile('/playpen/ammirato/Data/gmu_kitchen_dataset/');

scene_name = 'gmu_scene_001';

object_pc_path = fullfile(base_path, 'scene_annotation', 'objects3D', ...
                        scene_name);

object_pc_names = dir(fullfile(object_pc_path, '*.ply'));


image_structs = load(fullfile(base_path, 'scene_pose_info', ...
                strcat(scene_name, '_reconstruct_info_frame_sort.mat')));

image_structs = image_structs.frames; 
all_image_names = {image_structs.imgName};
image_structs_map = containers.Map(all_image_names, cell(1,length(all_image_names)));
for il=1:length(image_structs)
  image_structs_map(all_image_names{il}) = image_structs(il);
end

pose_label_fid = fopen(fullfile(base_path, 'object_pose_labels', ...
                        'pose_labels.txt'));

line = fgetl(pose_label_fid); %get the header
line = fgetl(pose_label_fid);
while(ischar(line))
  
  line = strsplit(line);
  
  scene_name = line{1};
  frame_index = line{2};
  labeled_image_name = line{3};
  labeled_pose_angle = str2num(line{4});
  object_id = line{5};
  
  
  
  cur_object_pc = pcread(fullfile(object_pc_path, ...
                      strcat('object', object_id, '.ply')));
                    
                    
  obj_pt = mean(cur_object_pc.Location);
  
  %TODO - is this right?
  instance_loc2d = double(obj_pt([1 3]));
  
  labeled_image_struct = image_structs_map(labeled_image_name);

  labeled_loc = -(labeled_image_struct.Rw2c)' * labeled_image_struct.Tw2c';
  labeled_loc2d = double(labeled_loc([1 3]));
  
  
  
  %% propogate the pose label
  
  for jl=1:length(all_image_names)
    
    cur_image_name = all_image_names{jl};
    cur_image_struct = image_structs_map(cur_image_name);
    
    cur_loc = -(cur_image_struct.Rw2c)' * (cur_image_struct.Tw2c)';
    cur_loc2d = double(cur_loc([1 3]));
    
    %get lengths of sides of triangle
    sidea = pdist2(labeled_loc2d', cur_loc2d');
    sideb = pdist2(labeled_loc2d', instance_loc2d);
    sidec = pdist2(instance_loc2d, cur_loc2d');

    [label_to_cur_angle,~,~] = get_triangle_angles_from_sides(sidea, sideb, sidec);


    if(~isreal(label_to_cur_angle))
      label_to_cur_angle = 0;
    end

    cur_is_left = left(instance_loc2d, labeled_loc2d, cur_loc2d);


    cur_pose_angle = label_to_cur_angle;
    if(cur_is_left)
      cur_pose_angle = mod(labeled_pose_angle + cur_pose_angle, 360); 
    else
      cur_pose_angle = mod(labeled_pose_angle - cur_pose_angle, 360); 
    end 



  
    
    
    
    
  end%for jl, each image name
  
  
  
  
  
  
  
  
  
  
  
  
  line = fgetl(pose_label_fid);
end%while line is a char

fclose(pose_label_fid);

