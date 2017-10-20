%Projects object point clouds into each image and saves the resulting bounding
%box of the object in each image. 

%TODO  - project all objects into each image at once?
%       - remove boxes from prev labels with this single label 

%CLEANED -no  ish 
%TESTED - ish 


%initialize contants, paths and file names, etc. 

init;
%% USER OPTIONS

scene_name = 'Home_008_1'; %make this = 'all' to run all scenes
model_number = '0'; %colmap model number

method = 0; %0 - oclusion filtering, uses improved depth maps if they exist
            %1 - no ocllusion filtering
            

debug =0;

%size of rgb image in pixels
kImageWidth = 1920;
kImageHeight = 1080;

%% SET UP GLOBAL DATA STRUCTURES

all_scenes = {scene_name};

%% MAIN LOOP
% for il=1:length(all_scenes)
%  
%   %% set scene specific data structures
%   scene_name = all_scenes{il};
%   scene_path =fullfile(ROHIT_BASE_PATH, scene_name);
%   meta_path = fullfile(ROHIT_META_BASE_PATH, scene_name);
% 
%   ish_names = dir(fullfile(meta_path,'compressed_high_res_depth','*.png'));
%   ish_names = {ish_names.name};
% 
%   %will hold all the depth images
%   depth_images = cell(1,length(ish_names));
% 
%   %for each image image, load a depth image
%   for jl=1:length(ish_names)
%       %display progress
%       if(mod(jl,50)==0)
%         disp(jl);
%       end
% 
%       depth_images{jl} = imread(fullfile(meta_path, 'high_res_depth', ... 
%                 ish_names{jl}));
%       end
%   end% for jl,  each image name
%   %put all the images in a map by rgb image name 
%   depth_img_map = containers.Map(ish_names, depth_images);
%   depths_loaded = 1;%indicate depths are loded


  names = dir(fullfile(meta_path,'raw_depth','*.png'));
  names = {names.name};


  for jl=1:length(names)

    cur_name = names{jl};

    index_string = sprintf('%06d', jl);

    scene_string = '00081';

    new_raw_name = strcat(scene_string, index_string,'0102.png');

    copyfile(fullfile(meta_path,'raw_depth',cur_name),...
             fullfile(meta_path,'new_raws', new_raw_name));


  end%for jl, names 












