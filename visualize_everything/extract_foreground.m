% Perform image segmentation to identify pixels corresponding to selected object.
% Detection bounding box used to initialize trimap for GrabCut algorithm

% OpenCV GrabCut works very well, but only supports RGB images
function trimap = extract_foreground(img, bbox)
  subplot(2,2,2);

  img3 = img(:,:,1:3);

  rect = rectangle('Position',bbox,'EdgeColor','c','LineWidth',2);

  % openCV uses 0-based indices, so translate bbox by 1
  [ trimap ] = cv.grabCut(img3, bbox-1, 'IterCount', 1);

  subplot(2,2,4);
end
