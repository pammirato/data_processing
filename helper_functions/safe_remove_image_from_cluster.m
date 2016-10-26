function [cluster_images_kept, success] = safe_remove_image_from_cluster(...
                                                      cluster_images_kept, image_name,...
                                                      min_images_per_cluster)
%Determines if an image can be removed from a cluster without breaking
% min_images_per_cluster constraint
%
% FOR use with separate_images_for_reconstruction.m script 


  %if the iamge was removed or not
  success = 0;

  cluster_size = size(cluster_images_kept, 2);

  %get the index of the image
  image_index = str2double(image_name(1:6));

  %get the cluster of the image
  cluster_id =  ceil(image_index/cluster_size);
  cluster_index = image_index - (cluster_id-1)*cluster_size;


  cluster_kept = cluster_images_kept(cluster_id, :);

  %make sure the cluster will stil have at least min_images_per_cluster images, and 
  %the image wasn't alredy removed
  if((sum(cluster_kept) > min_images_per_cluster) &&  ...
      cluster_images_kept(cluster_id, cluster_index))
    cluster_images_kept(cluster_id, cluster_index) = 0;
    success = 1;  
  end
end%remove image funciton
