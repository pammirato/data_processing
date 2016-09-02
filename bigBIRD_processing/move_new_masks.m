clearvars;
init_bigBIRD;


%TODO - add   rotation
%             alpha composition
%             illumination
%





debug = 0;

objs_list = { ...
      'aunt_jemima_original_syrup',  ...
      'coca_cola_glass_bottle', ...
      'listerine_green',  ...
       'red_bull', ...
       'softsoap_clear'};






new_masks_names = dir(fullfile('/playpen/ammirato/Data/BigBIRD/new_masks/*.png'));
new_masks_names = {new_masks_names.name};

img_names = dir('/playpen/ammirato/Data/BigBIRD/advil_liqui_gels/rgb/*.jpg');
img_names = {img_names.name};

img_names = repmat(img_names, 1,5);


t_fid = fopen('/playpen/ammirato/Detectors/SegNet/BigBIRD/test.txt');
t = fgetl(t_fid);
fclose(t_fid);
t = strsplit(t);

mask = ones(1024,1280);

for il=1:length(new_masks_names)

  nn = new_masks_names{il};

  img = imread(fullfile('/playpen/ammirato/Data/BigBIRD/new_masks/', nn));

  img = ~logical(img);
  img = imresize(img, [525,681]);
  %img = imresize(img, [1024,1280]);
  %img = [zeros(250,size(img,2)); img; zeros(250,size(img,2))];
  
  mask(250:(1024-250),300:(1280-300)) = img;
  img = mask;
  
  
  
  obs_ind = floor(il/601) + 1;
  
  ind = (il - 600*(obs_ind-1)-1)*3;
  np_ind = floor(ind/121) + 1;
  
  %f = strcat('NP', num2str(np_ind), '_', num2str(ind),'....');
  %f = img_names{il};
  f = t{il*2-1};
  f = strsplit(f,'/');
  f = strsplit(f{end},'_');
  f = strcat(f{end-1},'_', f{end});
  f = strcat(f(1:end-4), '.jpg');
  
  rgb = imread(fullfile('/playpen/ammirato/Data/BigBIRD/', objs_list{obs_ind}, 'rgb', f));
%   
%   imshow(rgb);
%   hold on;
%   h = imagesc(img);
%   set(h,'AlphaData',.5);
%   hold off;
%   ginput(1);
  
  imwrite(img, fullfile('/playpen/ammirato/Data/BigBIRD/', objs_list{obs_ind}, ...
                          '/masks', strcat(f(1:end-4), '_mask.pbm')));

end
