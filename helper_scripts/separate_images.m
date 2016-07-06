clearvars;


boring_threshold = 50; %1080*1920*.15;
not_blurry_threshold = 120;
pick_out_every = 13;


cluster_size = 12;
max_images = 1000;
min_images_per_cluster = 5;

debug = 0;

base_path = '/playpen/ammirato/Data/RohitMetaData/Kitchen_Living_04_2/';

%where to move the images

moved_rgb_path = fullfile(base_path, 'rgb_not_for_reconstruction');
mkdir(moved_rgb_path);

rgb_image_path = fullfile(base_path, 'rgb');


rgb_image_names = dir(fullfile(rgb_image_path, '*.png'));
rgb_image_names = {rgb_image_names.name};


%set up data to make sure at least min_images_per_cluster images per cluster are kept
org_num_images = length(rgb_image_names);
num_clusters = org_num_images / cluster_size;

%make sure each cluster has the same number of images
assert(mod(org_num_images,cluster_size) == 0);
%each cluster needs >= min_images_per_cluster pints, to define its circle
min_images = num_clusters *min_images_per_cluster;
max_images = max(max_images, min_images);
fprintf('Max images: %d\n', max_images);

num_images_removed = 0;


%make data structure to keep track of how many images each cluster still has
%cluster-id - on per cluster
%images-kept, true/false if the ith image in the cluster will be kept for reconstruction
%cluster_struct = struct('cluster_id', 1, 'images_kept', ones(1,cluster_size));
%cluster_structs = repmat(cluster_struct, 1, num_clusters); %one struct per cluster

cluster_images_kept = ones(num_clusters, cluster_size);


%first remove all the boring images 
for il = 1:length(rgb_image_names)

  %if we already removed as many images as we want, stop
  if((org_num_images - num_images_removed) == max_images)
    break;
  end 

  cur_image_name = rgb_image_names{il};

  rgb_img = imread(fullfile(rgb_image_path, cur_image_name));


  metric = get_single_metric_for_image(rgb_img, 'boring');

  %if this image is boring, try to remove it
  if(metric < boring_threshold)
    [cluster_images_kept, success] = remove_image(cluster_images_kept, cur_image_name, ...
                                                  min_images_per_cluster); 
   
    if(success)
      num_images_removed = num_images_removed + 1;
      movefile(fullfile(rgb_image_path, cur_image_name), ...
                fullfile(moved_rgb_path, cur_image_name));
    end
  end

  if(debug)
    if(1 < 50)
      imshow(rgb_img);
      hold on;
      title(num2str(metric));
      ginput(1);
    end
 end%if debug
end%for il, each iamge name







%while((org_num_images - num_images_removed) ~= max_images)
%
%
%  rand_inds = randi(org_num_images, 1, (org_num_images-num_images_removed - max_images));
%
%  for jl=1:length(rand_inds)
%
%    cur_image_name = rgb_image_names{rand_inds(jl)};
%
%    [cluster_images_kept, success] = remove_image(cluster_images_kept, cur_image_name, ...
%                                                min_images_per_cluster); 
%   
%    if(success)
%      num_images_removed = num_images_removed + 1;
%      movefile(fullfile(rgb_image_path, cur_image_name), ...
%                fullfile(moved_rgb_path, cur_image_name));
%    end
%
%  end%for jl, reach random index
%
%  disp('while loop');
%
%end %while we still have too many images







