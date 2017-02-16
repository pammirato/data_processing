function [] = run_all_post_process(scene_name)

disp('removing reference images...');
remove_reference_image_from_boxes_by_instance(scene_name);
disp('changing frame names...');
change_vatic_label_frame_names(scene_name);
disp('combining object parts...');
combine_instance_vatic_outputs(scene_name);
disp('transforming labels...');
transform_vatic_output(scene_name);
disp('converting to final format...');
convert_vatic_output_to_final_format(scene_name);
disp('done!');



end%function
