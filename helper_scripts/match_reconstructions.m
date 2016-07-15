function match_reconstructions(shared_structs1, shared_structs2)

    %% Load and analyze Colmap output

    num_images = length(shared_structs1);


    % Build camera matrices from quaternions and translations
    init_P_matching= buildCameraMatrix(shared_structs2);
    init_P_ref = buildCameraMatrix(shared_structs1);

    % Analyze initial reconstructtion differences
    [init_dist_diff, init_angle_diff] = compare_camera_poses(init_P_matching, init_P_ref);
    fprintf('Reconstruction mean translation error, initial: %.4f\n', mean(init_dist_diff));
    fprintf('Reconstruction mean rotation error (Euler angles in degrees), initial: %.4f %.4f %.4f\n', mean(init_angle_diff));

    %% ROTATE P_matching TO MATCH P_ref

    % Initial params
    init_camera = 6;
    init_P_H = init_P_ref(:,:,init_camera) / init_P_matching(:,:,init_camera); % P_ref * inv(P_matching) s.t. P_ref = init_P_H * P_matching
    init_R_H = init_P_H(1:3,1:3,1);
    init_t_H = init_P_H(1:3, 4, 1);
    init_eul_H = rotm2eul(init_R_H'); % ZYX Euler angles from the transformation
    init_s_H = 1;

    % Optimization options
    options = optimoptions('lsqnonlin','MaxFunEvals', 7000);%'Display','iter'

    
    % Minimize joint error
    [optTRS_params] = lsqnonlin( ...
        @(params)error_fun(params, init_P_ref, init_P_matching, 'joint'), ... % Anonymous function defining error function
        ... %         [mean(init_angle_diff), mean(init_P_matching(1:3,4,:) - init_P_ref(1:3,4,:),3)', init_s_H], ... % Initial parameters
        [init_eul_H, init_t_H', init_s_H], ... % Initial parameters
        [], ...
        [], ...
        options); % Optimization options


    % Optimized transformation matrix
    optTRS_P_H = [optTRS_params(7) * eul2rotm(optTRS_params(1:3)), optTRS_params(4:6)'; zeros(1,3), 1];
    
    % Perform transformations
    optTRS_P_matching = zeros(size(init_P_matching));
    for i = 1 : num_images
        optTRS_P_matching(:,:,i) = optTRS_P_H * init_P_matching(:,:,i);
    end
    
    % Extract camera poses
    [init_R_ref, init_C_ref] = extract_pose(init_P_ref);
    [init_R_matching, init_C_matching] = extract_pose(init_P_matching);
%     [optR_R_matching, optR_C_matching] = extract_pose(optT_P_matching);
    [optTRS_R_matching, optTRS_C_matching] = extract_pose(optTRS_P_matching);
    
    % Plot camera poses
    figure;
    hold on
    grid on
    axis equal
    axis manual
    xlim([-20,20]);
    ylim([-20,20]);
    zlim([-20,20]);
    for i = 1: num_images














        % Reference cameras original locations - RED
        plotCamera('Location', init_C_ref(:,i), 'Orientation', init_R_ref(:,:,i), 'Opacity', 0.1, ...
            'Size', 0.3, 'Color', [1,0,0], 'Label', num2str(i));

        % Matching cameras original locations - GREEN
        plotCamera('Location', init_C_matching(:,i), 'Orientation', init_R_matching(:,:,i), 'Opacity', 0.1, ...
            'Size', 0.3, 'Color', [0,1,0]);

        % Maching cameras transformed locations using optimal rotation - BLUE
%         plotCamera('Location', optR_C_matching(:,i), 'Orientation', optR_R_matching(:,:,i), 'Opacity', 0, ...
%             'Size', 0.3, 'Color', [0,0,1]);

        % Matching cameras transformed locations using optimal rotation, translation, and scale - BLACK
        plotCamera('Location', optTRS_C_matching(:,i), 'Orientation', optTRS_R_matching(:,:,i), 'Opacity', 0, ...
            'Size', 0.3, 'Color', [0,0,0]);

    end

    [optTRS_dist_diff, optTRS_angle_diff] = compare_camera_poses(optTRS_P_matching, init_P_ref);
    fprintf('Reconstruction mean translation error, final: %.4f\n', mean(optTRS_dist_diff));
    fprintf('Reconstruction mean rotation error (Euler angles in degrees), final: %.4f %.4f %.4f\n', ...
        mean(optTRS_angle_diff));
end

%% Helper functions

function cameras = loadCameras(path, num_images)
% Function to load camera pose from colmap files

    fid = fopen(path, 'r');
    
    % Skip the first 4 header lines
    for i = 1:4
        fgetl(fid);
    end
    
    % Parse the cameras from file
    cameras = zeros(num_images, 7);
    tline = fgetl(fid);
    while ischar(tline)
        tok = strsplit(tline, ' ');
        for j = 2 : 8
            cameras(str2double(tok{1}), j-1) = str2double(tok{j});
        end
        fgetl(fid);
        tline = fgetl(fid);
    end
end

function P = buildCameraMatrix(structs_array)
% Convert the quaternion-translation vector to a 4x4 camera matrix

    
    num_images = length(structs_array);

    P = zeros(4,4,num_images);
    P(4,4,:) = 1;

    for i = 1 : num_images
        cur_struct = structs_array(i);
        quat = cur_struct.quat';
        t = cur_struct.t;
        P(1:3, 4, i) = t;
        P(1:3, 1:3, i) = quat2rotm(quat);
    end
end

function [R_pose, C_pose] = extract_pose(P)
% Extract the camera pose from the projection matrix
%
% INPUT
% P         :   3x4xN or 4x4xN matrix of N projection matrices as[R_pose', -R_pose' * C_pose]
% 
% OUTPUT
% R_pose    :   3x3xN orthonormal camera rotation matrices (the transpose/inverse of the projection matrix's rotation)
% C_pose    :   3xN camera center locations

    R_pose = permute(P(1:3,1:3,:), [1,2,3]);

    C_pose = zeros(3, size(P,3));
    for i = 1 : size(C_pose, 2)
        C_pose(:, i) = -P(1:3,1:3,i)' * P(1:3,4,i);
    end
end

function [dist, angles] = compare_camera_poses(cameras1, cameras2)
% Determines the Euclidean distance and Euler angles comprising the
% difference between each corresponding camera in two reconstruction

    num_cameras = size(cameras1, 3);
    rot = zeros(3,3,num_cameras);
    for i = 1 : num_cameras
        rot(:,:,i) = cameras1(1:3,1:3,i) \ cameras2(1:3,1:3,i);
    end
    dist = sqrt(sum((cameras1(1:3,4,:) - cameras2(1:3,4,:)).^2));
    angles = rad2deg(rotm2eul(rot));

end

function E = error_fun(params, cameras1, cameras2, type)
% params = [euler_angle1, euler_angle2, euler_angle3, t1, t2, t3, s]
% type : {'rotation', 'translation', 'joint'}

    % Unravel parameters
    eul_angles = params(1:3);
    t = [params(4); params(5); params(6)];
    s = params(7);

    % Full rotation matrix
    R = eul2rotm(eul_angles)';

    % Similarity transform matrix
    P = [s*R, t; zeros(1,3), 1];
    
    % Evaluation differentials
    diff = zeros(4,4,size(cameras1,3));
    for i = 1 : size(cameras1,3)
        %diff(:,:,i) = cameras1(:,:,i) \ (P * cameras2(:,:,i));
        diff(:,:,i) = cameras1(:,:,i) - (P * cameras2(:,:,i));
    end
    
    % Different error terms depending on type
    switch type
        case 'translation'
            trans_norm = sqrt(sum(diff(1:3,4,:).^2)); % Differential distance
            E = trans_norm(:);
        case 'rotation'
            angle = abs(acos((diff(1,1,:) + diff(2,2,:) + diff(3,3,:) - 1) / 2)); % Differential angle
            E = angle(:);
        case 'joint'
            angle = abs(acos((diff(1,1,:) + diff(2,2,:) + diff(3,3,:) - 1) / 2)); % Differential angle
            trans_norm = sqrt(sum(diff(1:3,4,:).^2)); % Differential distance
            trans_norm = sqrt(sum(diff(1:3,4,:).^2)); % Differential distance
            E = [angle(:); 1000*trans_norm(:)];
        otherwise
            error('Error function type not recognized')
    end
end
