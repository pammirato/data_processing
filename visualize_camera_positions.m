

base_path = '/home/ammirato/Data/';




room_name = 'Room11';
view_directions = 1;




%%%allow user to set variables before running script
% flag = exist('room_name','var' );
% 
% if(flag ~=1)
%     room_name = 'Room11';
% end
% 
% 
% flag = exist ('view_directions','var');
% if( flag~=1)
%     view_directions = 0;
% end


disp(room_name);
disp(view_directions);


%load a map from image name to camera data
%camera data is an arraywith the camera position and a point along is orientation vector
% [CAM_X CAM_Y CAM_Z DIR_X DIR_Y DIR_Z]
camera_data_map = load(fullfile(base_path, room_name, 'reconstruction_results/camera_data_map.mat'));
camera_data_map = camera_data_map.camera_data_map;



%get all the camera_data, gives only a 1D matrix :(
values = cell2mat(camera_data_map.values);

%each image has a data vector 6 long, so index every 6

%plot the camera positions
plot3(values(1:6:end-5), values(2:6:end-4), values(3:6:end-3), '.r');


if(view_directions)
    hold on;
    
    hold off;
end
    



