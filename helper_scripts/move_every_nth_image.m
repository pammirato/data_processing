

scene_name = 'Kitchen_Living_02_2';

n = 3;
move_to_all_dests = 1;

copy = 1;

%folder_path = '/playpen/ammirato/Data/RohitData/Kitchen_Living_11/rgb/';
base_path = fullfile('/playpen/ammirato/Data/RohitMetaData' ,scene_name);
source_path = fullfile(base_path, 'rgb_for_recon_g1');
dest1_path = fullfile(base_path, 'rgb_for_recon_g2');
dest2_path = fullfile(base_path, 'rgb_for_recon_g3');

dests = {dest1_path, dest2_path};


d = dir(fullfile(source_path, '*.png'));

source_names = {d.name};

for il = 1:length(source_names)

  filename = source_names{il};

  if ~(mod(il,n) == 0)
    continue;
  end
   


  if(move_to_all_dests)

    for jl=1:length(dests)
      dest_path = dests{jl};
      if(copy)
        copyfile(fullfile(source_path, filename), fullfile(dest_path, filename));
      else
        movefile(fullfile(source_path, filename), fullfile(dest_path, filename));
      end
    end

  else 
    dest_path = dests{mod(il+length(dests)-1,length(dests))+1};



    if(copy)
      copyfile(fullfile(source_path, filename), fullfile(dest_path, filename));
    else
      movefile(fullfile(source_path, filename), fullfile(dest_path, filename));
    end
  end%if move to all dests
end%for il

