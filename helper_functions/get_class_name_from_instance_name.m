function [class_name] = get_class_name_from_instance_name(instance_name)
%gives the class that this instance belongs to

  %for now just remove any number at the end
  class_name = regexprep(instance_name, '[1-9]$', '');

end%function
