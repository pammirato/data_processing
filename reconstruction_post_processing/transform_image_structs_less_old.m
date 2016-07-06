%saves a camera poistions and orientations from text file outputted from reconstruction
%saves a cell array of these 'image structs', and also saves the scale 
%also saves a list of reconstructed 3d points seen by each image


%TODO - better name, processing for points2d

clearvars;

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Kitchen_Living_02_2'; %make this = 'all' to run all scenes
ref_group = 'group1'
trans_group = 'group2';
use_custom_scenes = 0;%whether or not to run for the scenes in the custom list
custom_scenes_list = {};%populate this 

cluster_size = 12;%how many images are in each cluster

debug = 0;

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




for il=1:length(all_scenes)
 
  %% set scene specific data structures
  scene_name = all_scenes{il}
  scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
  meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);


  all_image_names = get_names_of_X_for_scene(scene_name, 'rgb_images');


  %place holder for struct arrays
  blank_struct = struct(IMAGE_NAME, '', TRANSLATION_VECTOR, [], ...
                       ROTATION_MATRIX, [], WORLD_POSITION, [], ...
                       DIRECTION, [], QUATERNION, [], ...
                       SCALED_WORLD_POSITION, [0,0,0], IMAGE_ID,'',...
                       CAMERA_ID, '', 'cluster_id', -1, 'rotate_cw', -1, ...
                       'rotate_ccw',-1, 'translate_forward',-1,'translate_backward',-1);


  %load the image structs for each reconstruction
  recon_struct_file = load(fullfile(meta_path,RECONSTRUCTION_DIR,ref_group,'colmap_results',...
                        '0', 'image_structs.mat'));
   
  ref_image_structs = recon_struct_file.image_structs;
  scale = recon_struct_file.scale;

  recon_struct_file = load(fullfile(meta_path,RECONSTRUCTION_DIR,trans_group,'colmap_results',...
                        '0','image_structs.mat'));
  trans_image_structs = recon_struct_file.image_structs;





  %% now find the structs that are in both reconstructions

  %make a map from image name to image name, with all the image names
  %from the reconstruciton to be transformed
  trans_image_structs_map = containers.Map({trans_image_structs.image_name},...
                                   {trans_image_structs.image_name});

 
  %hold all the image names that are in both reconstructions 
  shared_image_names = cell(0);

  %for each name in the referecne reconstruction, see if that name is in the 
  % reconstruction to be transformed
  for jl=1:length(ref_image_structs)
    cur_image_name = ref_image_structs(jl).image_name;
    try
      name = trans_image_structs_map(cur_image_name);
      shared_image_names{end+1} = cur_image_name;
    catch
    end
  end%for jl 



  %% make a map from image name to image_struct for both reconstructions
  ref_image_structs_names = {ref_image_structs.image_name};
  ref_image_structs_map = containers.Map(ref_image_structs_names,...
                                 cell(1,length(ref_image_structs_names)));

  for jl=1:length(ref_image_structs_names)
    ref_image_structs_map(ref_image_structs_names{jl}) = ref_image_structs(jl);
  end


  trans_image_structs_names = {trans_image_structs.image_name};
  trans_image_structs_map = containers.Map(trans_image_structs_names,...
                                 cell(1,length(trans_image_structs_names)));

  for jl=1:length(trans_image_structs_names)
    trans_image_structs_map(trans_image_structs_names{jl}) = trans_image_structs(jl);
  end



  %% make struct arrays containing the shared structs for each reconstruction
  shared_structs_ref = repmat(ref_image_structs(1), 1, length(shared_image_names));
  shared_structs_trans = repmat(ref_image_structs(1), 1, length(shared_image_names));


  for jl=1:length(shared_image_names)
    cur_name = shared_image_names{jl};

    shared_structs_ref(jl) = ref_image_structs_map(cur_name);
    shared_structs_trans(jl) = trans_image_structs_map(cur_name);

  end%for jl

  %sort the structs base on image name, ascending order
  shared_structs_ref = nestedSortStruct2(shared_structs_ref, 'image_name');
  shared_structs_trans = nestedSortStruct2(shared_structs_trans, 'image_name');

  




  inds_to_use = [1:200];
  shared_structs_ref = shared_structs_ref(inds_to_use);
  shared_structs_trans = shared_structs_trans(inds_to_use);









  ref_struct1 = shared_structs_ref(1);
  ref_struct2 = shared_structs_trans(1);



  ref_R1 = ref_struct1.R;
  ref_t1 = ref_struct1.t;
  P1 = [ref_R1 ref_t1];
  P1 = [P1; 0 0 0 1];
  trans1 = pinv(P1);



  scale2 = .9;

  ref_R2 = ref_struct2.R;
  ref_t2 = ref_struct2.t*scale2;
  P2 = [ref_R2 ref_t2];
  P2 = [P2; 0 0 0 1];
  trans2 = pinv(P2);

%  ptc1 = pointCloud([shared_structs_ref.t]')
%  ptc2 = pointCloud([shared_structs_trans.t]')
%  tform = pcregrigid(ptc2,ptc1);
  
  

  

  w1 = zeros(3,length(shared_structs_ref));
  w2 = zeros(3,length(shared_structs_ref));

  w1_org = zeros(3,length(shared_structs_ref));
  w2_org = zeros(3,length(shared_structs_ref));


  tranforms = zeros(4,4,length(shared_structs_ref));

  %now convert all the structs for this recon
  for jl=1:length(shared_structs_ref)
    
    cur_struct = shared_structs_ref(jl);
    
    cur_struct1 = cur_struct;

    R = cur_struct.R;
    t = cur_struct.t;


    w1_org(:,jl) = (-R' * t);


    cur_p1 = [R t];
    cur_p1 = [cur_p1; 0 0 0 1];

  %  new_p1 = trans1 * cur_p1;
    new_p1 =  cur_p1;
    %% recon 2


    cur_struct = shared_structs_trans(jl);

    R = cur_struct.R;
    t = cur_struct.t*scale2;

    w2_org(:,jl) = (-R' * t);
    
    cur_p2 = [R t];
    cur_p2 = [cur_p2; 0 0 0 1];


    new_p2 = cur_p2 * trans2;
    new_p2 =  new_p2 * pinv(trans1);   


    ts1 = pinv(cur_p1);
    ts2 = pinv(cur_p2);
    transforms(:,:,jl) = ts2 * pinv(ts1);


    c1 = -new_p1(1:3,1:3)' * new_p1(1:3,4);
    c2 = -new_p2(1:3,1:3)' * new_p2(1:3,4);
   
    w1(:,jl) = c1; 
    w2(:,jl) = c2; 
 
    
    x = 1;

%    t1_trans = tform.T * [t1;1];
%    t2_trans = tform.T * [t;1];
    

    


  end%for jl




  avg_trans = sum(transforms,3) / size(transforms,3);



  w2_avg = zeros(3,length(shared_structs_ref));
  %now convert all the structs for this recon
  for jl=1:length(shared_structs_trans)
    

    cur_struct = shared_structs_trans(jl);

    R = cur_struct.R;
    t = cur_struct.t*scale2;

    cur_p2 = [R t];
    cur_p2 = [cur_p2; 0 0 0 1];


    new_p2 = cur_p2 * avg_trans;

    c2 = -new_p2(1:3,1:3)' * new_p2(1:3,4);
   
    w2_avg(:,jl) = c2; 
  end%for jl



  figure;
  plot(w1_org(1,:), w1_org(3,:), 'r.');
  hold on
  plot(w2_org(1,:), w2_org(3,:), 'g.');
  %plot(w2_avg(1,:), w2_avg(3,:), 'm.');
  plot(w2(1,:), w2(3,:), 'k.');
  %legend('org_ref', 'org_move', 'new_ref', 'new_move');
  hold off



%  figure;
%  plot(w1(1,:), w1(3,:), 'r.');
%  hold on
%  plot(w2(1,:), w2(3,:), 'k.');
%  title('transformed');
%  hold off
 
 
 








  %% Marc Eder stuff
%  num_images = length(shared_structs_ref);
%
%
%  P_1 = zeros(4,4,length(shared_structs_ref));
%  P_1(4,4,:) = 1;
%  P_2 = zeros(4,4,length(shared_structs_ref));
%  P_2(4,4,:) = 1;
%
%  for jl=1:length(shared_structs_ref)
%
%    assert(strcmp(shared_structs_ref(jl).image_name, shared_structs_trans(jl).image_name));
%
%    P_1(1:3, 4, jl) = shared_structs_ref(jl).t;
%    P_2(1:3, 4, jl) = shared_structs_trans(jl).t;
%
%
%    P_1(1:3, 1:3, jl) = shared_structs_ref(jl).R;
%    P_2(1:3, 1:3, jl) = shared_structs_trans(jl).R;
%
%
%
%  end%for jl
%
%
%  P_trans_init = P_2(:,:,1) / P_1(:,:,1);
%  R_trans_init = P_trans_init(1:3,1:3,1);
%  t_trans_init = P_trans_init(1:3,4,1);
%  eul_init = rotm2eul(R_trans_init); 
%  s_trans_init = 1;
%
%  fun = @(params)error_fun(params, P_2, P_1); 
%
%  init_params = [zeros(1,6),1];
%  options = optimoptions('lsqnonlin', 'Display', 'iter', 'MaxFunEvals', 7000);
%  [final_params, resnorm] = lsqnonlin(fun, init_params, [], [], options);
%
%  % Final params
%  R_trans_final = eul2rotm(final_params(3:-1:1))';
%  t_trans_final = [final_params(4); final_params(5); final_params(6)];
%  s_trans_final = final_params(7);
%
%  % Similarity transform matrix
%  P_trans_final = [s_trans_final*R_trans_final, t_trans_final; zeros(1,3), 1]; 
%
%
%  P_new_1_init = zeros(4,4,num_images);
%  P_new_1_opt = zeros(4,4,num_images);
%  for jl = 1 : num_images
%
%
%      P_2_plot = (P_2(:,:,jl));
%      p_2_loc =  -P_2_plot(1:3,1:3) \ P_2_plot(1:3,4);
%
%      P_new_1_init(:,:,jl) = (P_trans_init * P_1(:,:,jl));
%      p_1_init_loc = -P_new_1_init(1:3,1:3,jl) \ P_new_1_init(1:3,4,jl);
%
%
%      P_new_1_opt(:,:,jl) = (P_trans_final * P_1(:,:,jl));
%      p_1_opt_loc = -P_new_1_opt(1:3,1:3,jl) \ P_new_1_opt(1:3,4,jl);
%
%
%      plot3(p_2_loc(1),p_2_loc(2), p_2_loc(3), 'r.');
%      hold on;
%      plot3(p_1_init_loc(1),  p_1_init_loc(2), p_1_init_loc(3), 'k.');
%      plot3(p_1_opt_loc(1), p_1_opt_loc(2), p_1_opt_loc(3), 'b.');
%
%
%
%      % Sift cameras original locations - RED
%%      P_2_plot = (P_2(:,:,jl));
%%      plotCamera('Location', -P_2_plot(1:3,1:3) \ P_2_plot(1:3,4), 'Orientation', P_2_plot(1:3,1:3), 'Opacity', 0.2, ...
%%          'Size', 0.3, 'Color', [1,0,0], 'Label', num2str(jl));
%%  % 
%%      hold on;
%%      % MN cameras original locations - GREEN
%%      P_1_plot = (P_1(:,:,jl));
%%      plotCamera('Location', -P_1_plot(1:3,1:3) \ P_1_plot(1:3,4), 'Orientation', P_1_plot(1:3,1:3), 'Opacity', 0, ...
%%          'Size', 0.3, 'Color', [0,1,0]);
%%
%%      % MN cameras transformed locations via initialization only - BLUE
%%      P_new_1_init(:,:,jl) = (P_trans_init * P_1(:,:,jl));
%%      plotCamera('Location', -P_new_1_init(1:3,1:3,jl) \ P_new_1_init(1:3,4,jl), 'Orientation', P_new_1_init(1:3,1:3,jl), 'Opacity', 0, ...
%%          'Size', 0.3, 'Color', [0,0,1]);
%%
%%      % MN cameras transformed locations via optimized tranform - BLACK
%%      P_new_1_opt(:,:,jl) = (P_trans_final * P_1(:,:,jl));
%%      plotCamera('Location', -P_new_1_opt(1:3,1:3,jl) \ P_new_1_opt(1:3,4,jl), 'Orientation', P_new_1_opt(1:3,1:3,jl), 'Opacity', 0, ...
%%          'Size', 0.3, 'Color', [0,0,0]);
%
%  end%for jl


end%for i, each scene




