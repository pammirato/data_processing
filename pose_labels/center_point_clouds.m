%Centers point clouds around origin
%
% NOT USED

%CLEAN - NO
%TESTED - NO 
 

init;


base_path = '/playpen/ammirato/Data/RohitMetaMetaData/aligned_object_point_clouds/';
object_names = dir(fullfile(base_path,'*.ply'));
object_names = {object_names.name};


%% MAIN LOOP

for il=1:length(object_names)
 
  cur_name = object_names{il};


  cur_pc = pcread(fullfile(base_path,cur_name));
  
  locs = cur_pc.Location;
  com = mean(locs);
  locs = locs - repmat(com, size(locs,1), 1);
  cur_pc = pointCloud(locs,'Color',cur_pc.Color);
  
  pcwrite(cur_pc, fullfile(base_path,cur_name));
  
end%for il, each object_name
