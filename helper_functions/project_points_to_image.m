function [projected_points] = project_points_to_image(world_points, ...
                                                    intrinsic,rotation,translation,distortion)
%PROJECT_POINTS_TO_IMAGE - projects a set of given 3D points in world coordintes to 
%an image described by the given intrinsic, extrinsic, and distortion parameters
%disotortion model:  
%http://docs.opencv.org/master/db/d58/group__calib3d__fisheye.html#gsc.tab=0 



  %set the camera parameters
  k1 = distortion(1);
  k2 = distortion(2);
  k3 = distortion(3);
  k4 = distortion(4);

  fx = intrinsic(1,1);
  fy = intrinsic(2,2);
  cx = intrinsic(1,3);
  cy = intrinsic(2,3);

  R = rotation;
  t = translation;


  XC = R* world_points' + repmat(t,1,size(world_points',2));
  a = XC(1,:) ./ XC(3,:);
  b = XC(2,:) ./ XC(3,:);
  

  r = sqrt( (a).^2 + (b).^2);
  theta = atan(r);

  thetad = theta .* (1 + k1*(theta.^2) + k2*(theta.^4) + k3*(theta.^6) + k4*(theta.^8));

  xx = (thetad./r) .* a;
  yy = (thetad./r) .* b;


  u = fx*(xx + 0*yy) + cx;
  v = fy*yy + cy;


  projected_points = round([u;v]);





end
