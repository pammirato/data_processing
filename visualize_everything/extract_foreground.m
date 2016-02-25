% Perform image segmentation to identify pixels corresponding to selected object.
% Detection bounding box used to initialize trimap for GrabCut algorithm

% function trimap = extract_foreground(img, bbox)
%   subplot(2,2,2);
%
%   rect = rectangle('Position',bbox,'EdgeColor','c','LineWidth',2);
%
%   % openCV uses 0-based indices, so translate bbox by 1
%   [ trimap ] = cv.grabCut(img, bbox-1, 'IterCount', 1);
%
%   subplot(2,2,4);
% end

function trimap = extract_foreground(img, bbox)
  plotfig = gcf;

  warning('off','all');

  % initialize trimap with all pixels outside of bounding box marked background
  fixedBG = img;
  fixedBG(bbox(2):bbox(2)+bbox(4), bbox(1):bbox(1)+bbox(3), :) = 0;
  fixedBG = sum(fixedBG, 3);
  fixedBG = logical(fixedBG);

  format long g;

  % compute Beta parameter for GrabCut algorithm
  Beta = compute_beta(img);

  min_foreground = Inf;
  for k=1:10
      G = 50;
      maxIter = 1;
      Beta = 0.3;
      diffThreshold = 0.001;
      imd = double(img);

      % Run GrabCut algorithm on RGBD image to obtain segmentation
      trimap = GCAlgo(imd, fixedBG,k,G,maxIter, Beta, diffThreshold, []);
      trimap = double(1 - trimap).*3;
      foreground_size = nnz(trimap);
      if foreground_size < min_foreground
          min_foreground = foreground_size;
          disp(double([k Beta G maxIter diffThreshold foreground_size]));
      end
  end

  figure;
  subplot(2,2,1);
  imshow(fixedBG);
  subplot(2,2,2);
  imshow(trimap.*255);
  subplot(2,2,3);
  histogram(trimap);
  subplot(2,2,4);

  im_seg = imd(:,:,1:3).*repmat(trimap./3 , [1 1 3]);
  imshow(im_seg);
  figure(plotfig);

  subplot(2,2,4);
end
