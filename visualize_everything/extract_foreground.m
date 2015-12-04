% Perform image segmentation to identify pixels corresponding to selected object.
% Detection bounding box used to initialize trimap for GrabCut algorithm

function trimap = extract_foreground(image_name, bbox)
  userData = get(gcf, 'UserData');

  img = imread([userData.image_path image_name]);

  % openCV uses 0-based indices, so translate bbox by 1
  [ trimap ] = cv.grabCut(img, bbox-1);
end
