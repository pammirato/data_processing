%saves a camera poistions and orientations from text file outputted from reconstruction
%saves a cell array of these 'image structs', and also saves the scale 
%also saves a list of reconstructed 3d points seen by each image


%TODO - better name, processing for points2d

clearvars;

%initialize contants, paths and file names, etc. 
init;



%% USER OPTIONS

scene_name = 'Bedroom11'; %make this = 'all' to run all scenes
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



  blank_struct = struct(IMAGE_NAME, '', TRANSLATION_VECTOR, [], ...
                       ROTATION_MATRIX, [], WORLD_POSITION, [], ...
                       DIRECTION, [], QUATERNION, [], ...
                       SCALED_WORLD_POSITION, [0,0,0], IMAGE_ID,'',...
                       CAMERA_ID, '', 'cluster_id', -1, 'rotate_cw', -1, ...
                       'rotate_ccw',-1, 'translate_forward',-1,'translate_backward',-1);



  %save everything
  recon_struct_file = load(fullfile(meta_path,RECONSTRUCTION_DIR,'colmap_results_1',...
                        'reconstructed_image_structs.mat'));
   
  image_structs_1 = recon_struct_file.image_structs;
  scale = recon_struct_file.scale;

  recon_struct_file = load(fullfile(meta_path,RECONSTRUCTION_DIR,'colmap_results_2',...
                        'reconstructed_image_structs.mat'));
  image_structs_2 = recon_struct_file.image_structs;


  %now find the structs that are in both
  image_structs_2_map = containers.Map({image_structs_2.image_name},...
                                   {image_structs_2.image_name});


  shared_image_names = cell(0);

  for jl=1:length(image_structs_1)
  
    cur_image_name = image_structs_1(jl).image_name;

    try
      name = image_structs_2_map(cur_image_name);
      shared_image_names{end+1} = cur_image_name;
    catch
    end


  end%for jl 


  image_structs_1_names = {image_structs_1.image_name};
  image_structs_map1 = containers.Map(image_structs_1_names,...
                                 cell(1,length(image_structs_1_names)));

  for jl=1:length(image_structs_1_names)
    image_structs_map1(image_structs_1_names{jl}) = image_structs_1(jl);
  end


  image_structs_2_names = {image_structs_2.image_name};
  image_structs_map2 = containers.Map(image_structs_2_names,...
                                 cell(1,length(image_structs_2_names)));

  for jl=1:length(image_structs_2_names)
    image_structs_map2(image_structs_2_names{jl}) = image_structs_2(jl);
  end


  shared_structs1 = repmat(image_structs_1(1), 1, length(shared_image_names));
  shared_structs2 = repmat(image_structs_1(1), 1, length(shared_image_names));


  for jl=1:length(shared_image_names)
    cur_name = shared_image_names{jl};

    shared_structs1(jl) = image_structs_map1(cur_name);
    shared_structs2(jl) = image_structs_map2(cur_name);

  end%for jl



  ref_struct1 = shared_structs1(1);
  ref_struct2 = shared_structs2(1);



  ref_R1 = ref_struct1.R;
  ref_t1 = ref_struct1.t;

  scale_factor1 = 1/norm(ref_t1);
  subtract_1 = ref_t1;
  sub_scaled_1 = ref_t1*scale_factor1;

  w1_org = zeros(3,length(shared_structs1));
  w1_ts = zeros(3,length(shared_structs1));
  w1_tss = zeros(3,length(shared_structs1));
  w1_rt = zeros(3,length(shared_structs1));
  w1_no_sub = zeros(3,length(shared_structs1));
  w1_just_sub = zeros(3,length(shared_structs1));
  w1_r_sub = zeros(3,length(shared_structs1));
  w1_all = zeros(3,length(shared_structs1));





  ref_R2 = ref_struct2.R;
  ref_t2 = ref_struct2.t;

  scale_factor2 = 1/norm(ref_t2);
  subtract_2 = ref_t2;
  sub_scaled_2 = ref_t2*scale_factor2;

  w2_org = zeros(3,length(shared_structs1));
  w2_ts = zeros(3,length(shared_structs1));
  w2_tss = zeros(3,length(shared_structs1));
  w2_rt = zeros(3,length(shared_structs1));
  w2_no_sub = zeros(3,length(shared_structs1));
  w2_just_sub = zeros(3,length(shared_structs1));
  w2_r_sub = zeros(3,length(shared_structs1));
  w2_all = zeros(3,length(shared_structs1));





  ptc1 = pointCloud([shared_structs1.t]')
  ptc2 = pointCloud([shared_structs2.t]')
  tform = pcregrigid(ptc2,ptc1);
  
  

  




  %now convert all the structs for this recon
  for jl=1:length(shared_structs1)
    
    cur_struct = shared_structs1(jl);
    
    cur_struct1 = cur_struct;

    R = cur_struct.R;
    t = cur_struct.t;

    R1 = R;
    t1 = t;

    %cur_struct.R = cur_struct.R * ref_R1' ; 
    %cur_struct.t = cur_struct.t - ref_t1; 
    %cur_struct.t = cur_struct.t*scale_factor1 - subtract_1; 
    %cur_struct.t = cur_struct.t*scale_factor1; 

%    w1_org(:,jl) = (-R' * t);
%    w1_ts(:,jl) = -R' * (t*scale_factor1);
%    w1_tss(:,jl) = -R' * (t*scale_factor1 - sub_scaled_1);   
%    w1_rt(:,jl) = -(R*ref_R1')' * (t);   
%    w1_no_sub(:,jl) = -(R*ref_R1')' * (t*scale_factor1);   
%    w1_just_sub(:,jl) = -(R')' * (t-subtract_1);   
%    w1_r_sub(:,jl) = -(R*ref_R1')' * ((t-subtract_1)*.805);   
%    w1_all(:,jl) = -(R*ref_R1')' * (t*scale_factor1 - sub_scaled_1);   
    
    %shared_structs1(jl) = cur_struct;



    %% recon 2


    cur_struct = shared_structs2(jl);

    R = cur_struct.R;
    t = cur_struct.t;
    
    %cur_struct.R = cur_struct.R * ref_R2'; 
    %cur_struct.t = cur_struct.t + t_diff2; 
    %cur_struct.t = cur_struct.t*scale_factor2 - subtract_2; 
    %cur_struct.t = cur_struct.t*scale_factor2; 

%    w2_org(:,jl) = (-R' * t);
%    w2_ts(:,jl) = -R' * (t*scale_factor2);
%    w2_tss(:,jl) = -R' * (t*scale_factor2 - sub_scaled_2);   
%    w2_rt(:,jl) = -(R*ref_R2')' * (t);   
%    w2_no_sub(:,jl) = -(R*ref_R2')' * (t*scale_factor2);   
%    w2_just_sub(:,jl) = -(R')' * (t-subtract_2);   
%    w2_r_sub(:,jl) = -(R*ref_R2')' * (t-subtract_2);   
%    w2_all(:,jl) = -(R*ref_R2')' * (t*scale_factor2 - sub_scaled_2);   

    %shared_structs2(jl) = cur_struct;



    t1_trans = tform.T * [t1;1];
    t2_trans = tform.T * [t;1];
    

    


  end%for jl



% 
% 
% 
%  figure;
%  plot(w1_org(1,:), w1_org(3,:), 'r.');
%  hold on
%  plot(w2_org(1,:), w2_org(3,:), 'k.');
%  title('org');
%  hold off
% 
%  figure;
%  plot(w1_ts(1,:), w1_ts(3,:), 'r.');
%  hold on
%  plot(w2_ts(1,:), w2_ts(3,:), 'k.');
%  title('t scaled only');
%  hold off
% 
%  figure;
%  plot(w1_tss(1,:), w1_tss(3,:), 'r.');
%  hold on
%  plot(w2_tss(1,:), w2_tss(3,:), 'k.');
%  title('t scaled and subtracted');
%  hold off
% 
%  figure;
%  plot(w1_rt(1,:), w1_rt(3,:), 'r.');
%  hold on
%  plot(w2_rt(1,:), w2_rt(3,:), 'k.');
%  title('R right multiple with ref-R^-1');
%  hold off
% 
%  figure;
%  plot(w1_no_sub(1,:), w1_no_sub(3,:), 'r.');
%  hold on
%  plot(w2_no_sub(1,:), w2_no_sub(3,:), 'k.');
%  title('t scaled,  R right multiple with ref-R^-1');
%  hold off
% 
%  figure;
%  plot(w1_just_sub(1,:), w1_just_sub(3,:), 'r.');
%  hold on
%  plot(w2_just_sub(1,:), w2_just_sub(3,:), 'k.');
%  title('t subbed');
%  hold off
% 
%  figure;
%  plot(w1_r_sub(1,:), w1_r_sub(3,:), 'r.');
%  hold on
%  plot(w2_r_sub(1,:), w2_r_sub(3,:), 'k.');
%  title('t subbed  R right multiple with ref-R^-1');
%  hold off
% 
%  figure;
%  plot(w1_all(1,:), w1_all(3,:), 'r.');
%  hold on
%  plot(w2_all(1,:), w2_all(3,:), 'k.');
%  title('t scaled, substracted, R right multiple with ref-R^-1');
%  hold off
% 
% 
% 








  %% Marc Eder stuff
%  num_images = length(shared_structs1);
%
%
%  P_1 = zeros(4,4,length(shared_structs1));
%  P_1(4,4,:) = 1;
%  P_2 = zeros(4,4,length(shared_structs1));
%  P_2(4,4,:) = 1;
%
%  for jl=1:length(shared_structs1)
%
%    assert(strcmp(shared_structs1(jl).image_name, shared_structs2(jl).image_name));
%
%    P_1(1:3, 4, jl) = shared_structs1(jl).t;
%    P_2(1:3, 4, jl) = shared_structs2(jl).t;
%
%
%    P_1(1:3, 1:3, jl) = shared_structs1(jl).R;
%    P_2(1:3, 1:3, jl) = shared_structs2(jl).R;
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




