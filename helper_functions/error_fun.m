function E = error_fun(params, RL, RR)
% params = [alpha, beta, gamma, t1, t2, t3, s], alpha --> x-axis, beta --> y-axis, gamma --> z=axis

    % Unravel parameters
    alpha = params(1);
    beta = params(2);
    gamma = params(3);
    t = [params(4); params(5); params(6)];
    s = params(7);

    % Full rotation matrix
    R = eul2rotm([gamma, beta, alpha])';

    % Similarity transform matrix
    P = [s*R, t; zeros(1,3), 1];
    
    % Evaluation differentials
    diff = zeros(4,4,size(RL,3));
    for i = 1 : size(RL,3)
        diff(:,:,i) = RL(:,:,i) \ (P * RR(:,:,i));
    end
    
    % Differential angle
    angle = abs(acos((diff(1,1,:) + diff(2,2,:) + diff(3,3,:) - 1) / 2));
%    denom = sqrt((diff(3,2,:) - diff(2,3,:)).^2 + (diff(1,3,:) - diff(3,1,:)).^2 + (diff(2,1,:) - diff(1,2,:)).^2);
%    axis = [(diff(3,2,:) - diff(2,3,:)) ./ denom; (diff(1,3,:) - diff(3,1,:)) ./ denom; (diff(2,1,:) - diff(1,2,:)) ./ denom];
   
    % Differential distance
    trans_norm = sqrt(sum(diff(1:3,4,:).^2));
    max(trans_norm)
    P
    
    E = [angle(:); trans_norm(:)];
%     tmp = diff(1:3,4,:);
%     E = [angle(:); tmp(:)];