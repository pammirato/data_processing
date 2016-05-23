


labels_path = fullfile(meta_path,'recognition_results/fast_rcnn','bounding_boxes_by_image_instance');



d = dir(fullfile(labels_path,'*.mat'));

fns = {d.name};


for i=1:length(fns)

  fn = fns{i};

  if(i>101)
    berakp=1;
  end

  a = load(fullfile(labels_path,fn));

  if(~isfield(a,'chair1'))
    a.('chair1') = [];
    save(fullfile(labels_path,fn), '-struct','a');
  end

end

