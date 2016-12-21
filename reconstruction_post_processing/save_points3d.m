%saves 3D positions and RGB for all reconstructed points in each scene 



%CLEANED - yes 
%TESTED - yes 

%initialize contants, paths and file names, etc. 
init;


%% USER OPTIONS

scene_name = 'Kitchen_Living_02_2'; %make this = 'all' to run all scenes
model_number = '0';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 




%% SET UP GLOBAL DATA STRUCTURES


%get the names of all the scenes
d = dir(ROHIT_BASE_PATH);
d = d(3:end);
all_scenes = {d.name};


%determine which scenes are to be processed 
if(use_custom_scenes && ~isempty(custom_scenes_list))
  %if we are using the custom list of scenes
  all_scenes = custom_scenes_list;
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



  %read in the file
  fid_points3d = fopen(fullfile(meta_path,RECONSTRUCTION_RESULTS, ...
                                'colmap_results', model_number, 'points3D.txt'),'r');
 
  if(fid_points3d == -1)
    disp(strcat('could not open points3d.txt for', scene_name));
  end


  %get the header
  line = fgetl(fid_points3d);
  line = fgetl(fid_points3d);
  line = fgetl(fid_points3d);
  
  %get first line
  line = fgetl(fid_points3d);
  
  all_structs = cell(0);
  
  while(ischar(line))
    line = strsplit(line);

    %safety check        
    if(length(line) < 9)
      line = fgetl(fid_points3d);
      continue;
    end
   
    %get the data 
    id = str2num(line{1});
    x = str2num(line{2});
    y = str2num(line{3});
    z = str2num(line{4});
    r = str2num(line{5});
    g = str2num(line{6});
    b = str2num(line{7});
    p_error = str2num(line{8});
   
    %get image and point2 id(correspoints to image_structs and point2D_structs) 
    %many images may have 'seen' this one point
    image_id = [line(9:2:end)];
    point2_id = {line{10:2:end}};
   
    %convert the ids to numbers from strings 
    image_id = cellfun(@str2num,image_id(2:end));
    point2_id = cellfun(@str2num,point2_id(2:end));
    num_image_ids = length(image_id);
    
    cur_struct = struct('id',id,'x',x,'y',y,'z',z,'r',r,'g',g,'b',b,...
                        'error',p_error,'image_ids',image_id,'point2_ids',point2_id, ...
                            'num_image_ids',num_image_ids);
    
    %store the current struct                
    all_structs{end+1} = cur_struct;
    
    line = fgetl(fid_points3d);
    
  end%while is char
  
  fclose(fid_points3d);
 

  %save all the structs 
  points3d = cell2mat(all_structs);
  save(fullfile(meta_path,RECONSTRUCTION_RESULTS, ...
                     'colmap_results', model_number', 'points3D.mat'),'points3d');
  
end%for il, each scene
