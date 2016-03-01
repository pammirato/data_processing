

init;



scene_path = fullfile('/home/ammirato/Data/Test/SN208_2');




odom_fid = fopen(fullfile(scene_path,'vsfm.txt'));


num_points = 239;


points = zeros(10,num_points);


line = fgetl(odom_fid);
line = fgetl(odom_fid);
line = fgetl(odom_fid);

for i=1:num_points
    
    line = fgetl(odom_fid);
    
    
    line = strsplit(line);
    
    for j=2:length(line)
        a = str2double(line(j));
        points(j-1,i) = a;
    end
%     x = str2double(line(2));
%     y = str2double(line(3));
%     z = str2double(line(4));
%      
%     points(:,i) = [x; y; z];
    
end%for i


%figure;
%plot3(points(1,:), points(2,:), points(3,:), 'r.');

%figure;
%plot(points(2,:),points(3,:), 'r.');
%axis equal;


for i=1:10
    for j=(i+1):10
        figure;
        title(strcat(num2str(i),',',num2str(j)));
        plot(points(i,:),points(j,:),'r.');
        title(strcat(num2str(i),',',num2str(j)));

    end
end