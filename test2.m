


for i=1:length(labeled_images)
    
   label = labeled_images{i};
 
   rgb_image = imread([base_path '/rgb/' label{1}]);
   
   imshow(rgb_image);
   hold on;
   
   rect = zeros(1,4);
   
   rect(1:2) = detections(i,1:2);
   rect(3) = detections(i,3) - detections(i,1);
   rect(4) = detections(i,4) - detections(i,2);
   
   
   rectangle('Position',rect,'LineWidth',2, 'EdgeColor','b');
   
   detections(i,5)
   
   [xi yi but] = ginput(1);
   
   hold off;
    
end