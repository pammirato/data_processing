

clear;
init;







scene_name = 'FB341'; %make this = 'all' to run all scenes



%get the names of all the scenes
d = dir(BASE_PATH);
d = d(3:end);

%determine if just one or all scenes are being processed
if(strcmp(scene_name,'all'))
    num_scenes = length(d);
else
    num_scenes = 1;
end

for i=1:num_scenes
    
    %if we are processing all scenes
    if(num_scenes >1)
        scene_name = d(i).name();
    end

    scene_path =fullfile(BASE_PATH, scene_name);


    fid_points3d = fopen(fullfile(scene_path,RECONSTRUCTION_DIR,'points3D.txt'),'r');
    
    %get the header
    line = fgetl(fid_points3d);
    line = fgetl(fid_points3d);
    
    %get first line
    line = fgetl(fid_points3d);
    
    all_structs = cell(0);
    
    while(ischar(line))
        line = strsplit(line);
        
        if(length(line) < 9)
            line = fgetl(fid_points3d);
            continue;
        end
        
        id = str2num(line{1});
        x = str2num(line{2});
        y = str2num(line{3});
        z = str2num(line{4});
        r = str2num(line{5});
        g = str2num(line{6});
        b = str2num(line{7});
        error = str2num(line{8});
        
        image_id = [line(9:2:end)];
        point2_id = {line{10:2:end}};
        
        image_id = cellfun(@str2num,image_id(2:end));
        point2_id = cellfun(@str2num,point2_id(2:end));
        num_image_ids = length(image_id);
        
        cur_struct = struct('id',id,'x',x,'y',y,'z',z,'r',r,'g',g,'b',b,...
                            'error',error,'image_ids',image_id,'point2_ids',point2_id, ...
                                'num_image_ids',num_image_ids);
                        
        all_structs{end+1} = cur_struct;
        
        line = fgetl(fid_points3d);
        
    end%while is char
    
    fclose(fid_points3d);
    
    points3d = cell2mat(all_structs);
    
    save(fullfile(scene_path,RECONSTRUCTION_DIR,'points3D.mat'),'points3d');
    
end