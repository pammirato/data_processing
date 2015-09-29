
images_per_room = 2;

base_path = '/home/ammirato/Data/';


d = dir(base_path);
d = d(3:end);




for i=1:length(d)
    
    room_name = d(i).name();
    
    dr = dir(fullfile(base_path, room_name,'/rgb/'));
    dr = dr(3:end);
    
    for j=1:1:length(dr)%floor(length(dr)/images_per_room):length(dr)
        rgb_name = dr(j).name;
        
        fullfile(base_path, room_name,'rgb/', rgb_name)
        
        img = imread(fullfile(base_path, room_name,'rgb/', rgb_name));
        index = rgb_name(strfind(rgb_name,'b')+1:end);
        raw_depth = imread(fullfile(base_path,room_name,'/raw_depth/',['raw_depth' index]));
        
        fullfile(base_path,room_name,'/raw_depth/',['raw_depth' index])
        
        imshow(img);
        hold on;
        h = imagesc(raw_depth);
        set(h,'AlphaData',.5);
        
        input('1');
    end
    
end