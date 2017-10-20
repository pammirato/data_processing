function varargout = box_editor(varargin)
% BOX_EDITOR a GUI for editing/removing bounding boxes in images 
%
%   Allows user to choose scene, then instance category. The user then can use GUI 
%     buttons or keyboard shortcuts to edit or remove the boxes for the chosen 
%     instance in the chosen scene.
%
%   Loads all rgb images for the given scene once the scene is selected, so for  
%     best performance, edit all instances in one scene before moving to the next scene
%
%   Bounding boxes are assumed to be in [xmin ymin xmax ymax] format
%
%   NOTE:  there currently is a bug that does not allow the user to change which scene
%          they are working on properly. So pick one scene, edit boxes, and then restart
%          the GUI for the next scene.

%% TODO  - load jpg images
%        - change scenes properly
%        - make sure loading of raw labeles gets most recent file, 
%             even ones after the GUI is started
%        - more memory for undo


%% Last Modified by GUIDE v2.5 16-Jan-2017 14:48:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @box_editor_OpeningFcn, ...
                   'gui_OutputFcn',  @box_editor_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before box_editor is made visible.
function box_editor_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
%
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to box_editor (see VARARGIN)

%get all the scene names and populate the drop down menu
init;
d = dir(ROHIT_BASE_PATH);
d = d(3:end);
all_scenes = {d.name};
handles.scene_pop_up_menu.String = cat(2, {'Pick a Scene'}, all_scenes);

% Choose default command line output for box_editor
handles.output = hObject;
handles.box_change_resolution = 4;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes box_editor wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = box_editor_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
%
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in delete_button.
function delete_button_Callback(hObject, eventdata, handles)
% remove current box/image from label list
%
% hObject    handle to delete_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%get the current list of image names and boxes, 
%as well as the index of the current image
image_names = handles.image_names;
bboxes = handles.bboxes;
cur_image_index = handles.cur_image_index;

%save the box/image we are about to delete incase user wants to undo
handles.last_deleted_name = image_names{cur_image_index};
handles.last_deleted_boxes = bboxes{cur_image_index};

%remove the box/image from the lists
image_names(cur_image_index) = [];
bboxes(cur_image_index) = [];

%make sure index does not go out of bounds
if(cur_image_index > length(image_names))
  cur_image_index = 1;
end

%set the new lists 
handles.image_names = image_names;
handles.bboxes = bboxes;
handles.cur_image_index = cur_image_index;

%update everything
guidata(hObject, handles);
handles = draw_current_image_and_box(hObject, eventdata,handles);
guidata(hObject, handles);
%next_button_Callback(hObject, eventdata, handles);
%prev_button_Callback(hObject, eventdata, handles);



% --- Executes on button press in corner_up_button.
function corner_up_button_Callback(hObject, eventdata, handles)
% moves bottom edge of box up by change resolution 
%
% hObject    handle to corner_up_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%get the current box 
bbox = handles.bboxes{handles.cur_image_index};

%move the bottom edge(ymax == bbox(4)) up, 
%but make sure the box still has height of 1
if(bbox(4) - handles.box_change_resolution >= bbox(2))
  bbox(4) = bbox(4) - handles.box_change_resolution;
else
  move_dist = bbox(4)-bbox(2);
  bbox(4) = bbox(4) - move_dist;
end

%bbox = convert_cropped_box_to_real_box(handles.large_box,bbox);
handles.bboxes{handles.cur_image_index} = bbox;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles);


% --- Executes on button press in corner_down_button.
function corner_down_button_Callback(hObject, eventdata, handles)
% moves the bottom edge of the box down by the change resolution
% but not out of the image
%
% hObject    handle to corner_down_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%get the box
bbox = handles.bboxes{handles.cur_image_index};

%move the edge, keeping it inbounds
if(bbox(4) + handles.box_change_resolution < handles.image_height)
  bbox(4) = bbox(4) + handles.box_change_resolution;
else
  move_dist = handles.image_height - bbox(4);
  bbox(4) = bbox(4) + move_dist;
end

%bbox = convert_cropped_box_to_real_box(handles.large_box,bbox);
handles.bboxes{handles.cur_image_index} = bbox;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles);

% --- Executes on button press in corner_right_button.
function corner_right_button_Callback(hObject, eventdata, handles)
% moves the right edge of the box right by the change resolution
% but not out of the image
%
% hObject    handle to corner_right_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%get the box 
bbox = handles.bboxes{handles.cur_image_index};

%move the edge
if(bbox(3) + handles.box_change_resolution < handles.image_width)
  bbox(3) = bbox(3) + handles.box_change_resolution;
else
  move_dist = handles.image_width - bbox(3);
  bbox(3) = bbox(3) + move_dist;
end
%bbox = convert_cropped_box_to_real_box(handles.large_box,bbox);
handles.bboxes{handles.cur_image_index} = bbox;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles);


% --- Executes on button press in corner_left_button.
function corner_left_button_Callback(hObject, eventdata, handles)
% moves the right edge of the box left by the change resolution
% but ensures a minimum width of 1 for the box 
%
% hObject    handle to corner_left_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%get the box
bbox = handles.bboxes{handles.cur_image_index};

%move the edge
if(bbox(3) - handles.box_change_resolution >= bbox(1))
  bbox(3) = bbox(3) - handles.box_change_resolution;
else
  move_dist = bbox(3)-bbox(1);
  bbox(3) = bbox(3) - move_dist;
end
%bbox = convert_cropped_box_to_real_box(handles.large_box,bbox);
handles.bboxes{handles.cur_image_index} = bbox;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles);




% --- Executes on button press in box_up_button.
function box_up_button_Callback(hObject, eventdata, handles)
% moves the entire box up by the change resolution,
% but keeps the box in the image
%
% hObject    handle to box_up_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%get the box
bbox = handles.bboxes{handles.cur_image_index};

%move the box
if(bbox(2) - handles.box_change_resolution >= 1)
  bbox(2) = bbox(2) - handles.box_change_resolution;
  bbox(4) = bbox(4) - handles.box_change_resolution;
else
  move_dist = bbox(2)-1;
  bbox(2) = bbox(2) - move_dist;
  bbox(4) = bbox(4) - move_dist;
end
%bbox = convert_cropped_box_to_real_box(handles.large_box,bbox);
handles.bboxes{handles.cur_image_index} = bbox;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles);


% --- Executes on button press in box_down_button.
function box_down_button_Callback(hObject, eventdata, handles)
% moves the entire box down by the change resolution,
% but keeps the box in the image
%
% hObject    handle to box_down_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%get the box
bbox = handles.bboxes{handles.cur_image_index};

%move the box
if(bbox(4) + handles.box_change_resolution < handles.image_height)
  bbox(2) = bbox(2) + handles.box_change_resolution;
  bbox(4) = bbox(4) + handles.box_change_resolution;
else
  move_dist = handles.image_height - bbox(4);
  bbox(2) = bbox(2) + move_dist;
  bbox(4) = bbox(4) + move_dist;
end
%bbox = convert_cropped_box_to_real_box(handles.large_box,bbox);
handles.bboxes{handles.cur_image_index} = bbox;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles);



% --- Executes on button press in box_right_button.
function box_right_button_Callback(hObject, eventdata, handles)
% moves the entire box right by the change resolution,
% but keeps the box in the image
%
% hObject    handle to box_right_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%get the box
bbox = handles.bboxes{handles.cur_image_index};

%move the box
if(bbox(3) + handles.box_change_resolution < handles.image_width)
  bbox(1) = bbox(1) + handles.box_change_resolution;
  bbox(3) = bbox(3) + handles.box_change_resolution;
else
  move_dist = handles.image_width - bbox(3);
  bbox(1) = bbox(1) + move_dist;
  bbox(3) = bbox(3) + move_dist;
end
%bbox = convert_cropped_box_to_real_box(handles.large_box,bbox);
handles.bboxes{handles.cur_image_index} = bbox;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles);

% --- Executes on button press in box_left_button.
function box_left_button_Callback(hObject, eventdata, handles)
% moves the entire box left by the change resolution,
% but keeps the box in the image
%
% hObject    handle to box_left_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%get the box
bbox = handles.bboxes{handles.cur_image_index};

%move the box
if(bbox(1) - handles.box_change_resolution > 0)
  bbox(1) = bbox(1) - handles.box_change_resolution;
  bbox(3) = bbox(3) - handles.box_change_resolution;
else
  move_dist = bbox(1)-1;
  bbox(1) = bbox(1) - move_dist;
  bbox(3) = bbox(3) - move_dist;
end
%bbox = convert_cropped_box_to_real_box(handles.large_box,bbox);
handles.bboxes{handles.cur_image_index} = bbox;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles);


% --- Executes on button press in prev_button.
function prev_button_Callback(hObject, eventdata, handles)
% move to the previous image (wraps around)
%
% hObject    handle to prev_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.cur_image_index = handles.cur_image_index -1;
if(handles.cur_image_index < 1)
  handles.cur_image_index = length(handles.image_names);
end
handles.cur_img = [];

guidata(hObject, handles);
handles = draw_current_image_and_box(hObject, eventdata,handles);
guidata(hObject, handles);

% --- Executes on button press in next_button.
function next_button_Callback(hObject, eventdata, handles)
% move to the next image (wraps around)
%
% hObject    handle to next_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.cur_image_index = handles.cur_image_index +1;
if(handles.cur_image_index > length(handles.image_names))
  handles.cur_image_index = 1;
end
handles.cur_img = [];
guidata(hObject, handles);
handles = draw_current_image_and_box(hObject, eventdata,handles);
guidata(hObject, handles);


% --- Executes on selection change in scene_pop_up_menu.
function scene_pop_up_menu_Callback(hObject, eventdata, handles)
% respond to user choice of scene in popup menu
% loads all rgb images for the scene and populates instance menu
%
% hObject    handle to scene_pop_up_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns scene_pop_up_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from scene_pop_up_menu
init;

%get the string values of the selected item from the menu and save it
contents = cellstr(get(hObject,'String'));
handles.selected_scene =  contents{get(hObject,'Value')};

%get all the instance names and populate the menu
instance_labels = dir(fullfile(ROHIT_META_BASE_PATH, handles.selected_scene, ...
                      'labels','raw_labels', 'bounding_boxes_by_instance', '*.mat'));
instance_labels = {instance_labels.name};
handles.label_pop_up_menu.String = cat(2,{'Pick a label'},instance_labels);


%get all the rgb image names for this scene
all_image_names = get_scenes_rgb_names(fullfile(ROHIT_BASE_PATH, ...
                                        handles.selected_scene));
images = cell(1,length(all_image_names));


load_images = questdlg('Would you like to load all images first?', 'Load', 'Yes','No','Yes');

load_images = strcmp(load_images,'Yes');

if(load_images)
  %load all the images
  %display progress to user
  tt = text(.3,.5,['Loaded Image ' num2str(0) '/' num2str(length(all_image_names))]);

  for il=1:length(all_image_names)
    cur_name = all_image_names{il};
    img = imread(fullfile(ROHIT_BASE_PATH,handles.selected_scene, 'jpg_rgb', ...
                        strcat(cur_name(1:10), '.jpg')));
    images{il} = img;
    delete(tt);
    tt = text(.3,.5,['Loaded Image ' num2str(il) '/' num2str(length(all_image_names))]);
    drawnow
  end
else
    cur_name = all_image_names{1};
    img = imread(fullfile(ROHIT_BASE_PATH,handles.selected_scene, 'jpg_rgb', ...
                        strcat(cur_name(1:10), '.jpg')));
end


%save all the loaded images into a map
handles.image_map = containers.Map(all_image_names, images);
handles.image_width = size(img,2);
handles.image_height = size(img,1);
handles.cur_img = [];

guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function scene_pop_up_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to scene_pop_up_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in label_pop_up_menu.
function label_pop_up_menu_Callback(hObject, eventdata, handles)
% load the labels(boxes) for the selected instance in the selected scene
%
% hObject    handle to label_pop_up_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns label_pop_up_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from label_pop_up_menu
init;

%get the string for the selected instance and save it
contents = cellstr(get(hObject,'String'));
handles.selected_instance =  contents{get(hObject,'Value')};

%load the mat file with the boxes
cur_instance_labels = load(fullfile(ROHIT_META_BASE_PATH, handles.selected_scene, ...
                            'labels', 'raw_labels', 'bounding_boxes_by_instance', ...
                              handles.selected_instance));

%save the current list of image names and boxes for this instance
handles.image_names = cur_instance_labels.image_names;
% handles.image_names = mat2cell(cur_instance_labels.image_names, ...
%                     size(cur_instance_labels.image_names,1),14);
handles.bboxes = mat2cell(cur_instance_labels.boxes, ...
        repmat(1,1,size(cur_instance_labels.boxes,1)), ...
            size(cur_instance_labels.boxes,2));
%start from the first image
handles.cur_image_index = 1;

guidata(hObject, handles);
handles = draw_current_image_and_box(hObject, eventdata,handles);
guidata(hObject, handles);


                            


% --- Executes during object creation, after setting all properties.
function label_pop_up_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to label_pop_up_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function [handles] = draw_current_image_and_box(hObject, eventdata,handles)
%draws the current image and box on the GUI
init;

%get the current image name, and image matrix
cur_image_name = handles.image_names{handles.cur_image_index};
img = handles.image_map(cur_image_name);
if(isempty(img))
  img = handles.cur_img;
end
if(isempty(img))
  img = imread(fullfile(ROHIT_BASE_PATH,handles.selected_scene, 'jpg_rgb', ...
                        strcat(cur_image_name(1:10), '.jpg')));
end
%plot the image, then draw the box on top
bbox = handles.bboxes{handles.cur_image_index};
width = (bbox(3)-bbox(1));
height = (bbox(4)-bbox(2));
large_box = [bbox(1) - 2*width, bbox(2)-2*height, bbox(3)+2*width, bbox(4)+2*height];
large_box(1) = max(1,large_box(1));
large_box(2) = max(1,large_box(2));
large_box(3) = min(1920,large_box(3));
large_box(4) = min(1080,large_box(4));

new_bbox = [bbox(1)-large_box(1),bbox(2)-large_box(2),bbox(3)-large_box(1),bbox(4)-large_box(2)];

%imshow(img);
imshow(img(large_box(2):large_box(4), large_box(1):large_box(3),:));
hold on;
%rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], ... 
%                     'LineWidth',2, 'EdgeColor','r');
rectangle('Position',[new_bbox(1) new_bbox(2) (new_bbox(3)-new_bbox(1)) (new_bbox(4)-new_bbox(2))], ... 
                     'LineWidth',2, 'EdgeColor','r');
                 
%indicate what box this is (i.e. box 3 of 100) 
box_string = [num2str(handles.cur_image_index) '/' ...
                num2str(length(handles.image_names))];
handles.box_counter.String = box_string;
%handles.large_box = large_box;
hold off;
%handles.cur_img = img;
guidata(hObject, handles);





% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% Make keyboard shortcuts. Map keypresses to button callbacks
%
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)

keyPressed = eventdata.Key;

switch keyPressed
  
  case 'n'
    next_button_Callback(hObject, eventdata, handles)
  case 'm'
    prev_button_Callback(hObject, eventdata, handles)
  case 'e'
    box_up_button_Callback(hObject, eventdata, handles)
  case 'd'
    box_down_button_Callback(hObject, eventdata, handles)
  case 's'
    box_left_button_Callback(hObject, eventdata, handles)
  case 'f'
    box_right_button_Callback(hObject, eventdata, handles)
  case 'i'
    corner_up_button_Callback(hObject, eventdata, handles)
  case 'k'
    corner_down_button_Callback(hObject, eventdata, handles)
  case 'j'
    corner_left_button_Callback(hObject, eventdata, handles)
  case 'l'
    corner_right_button_Callback(hObject, eventdata, handles)
  case 'x'
    delete_button_Callback(hObject, eventdata, handles)
  case 'u'
    undo_button_Callback(hObject, eventdata, handles)
  case 'v'
    res_down_button_Callback(hObject, eventdata, handles)
  case 'b'
    res_up_button_Callback(hObject, eventdata, handles)
  case 'a'
    use_mouse_button_Callback(hObject, eventdata, handles)
end


% --- Executes on button press in save_button.
function save_button_Callback(hObject, eventdata, handles)
% Saves the boxes for the current instance
% does not overwrite loaded boxes, but saves boxes in new folder as verified
%
% hObject    handle to save_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
init;
image_names = handles.image_names;
boxes = cell2mat(handles.bboxes);
if(size(boxes,1) < length(handles.bboxes))
  boxes = cell2mat(handles.bboxes');
end
save_dir = fullfile(ROHIT_META_BASE_PATH, handles.selected_scene, ...
                       LABELING_DIR, VERIFIED_LABELS, BBOXES_BY_INSTANCE);
if(~exist(save_dir,'dir'))
  mkdir(save_dir);
end
save(fullfile(save_dir, handles.selected_instance),'image_names','boxes' );
                            
%update labels by image instance
convert_boxes_by_instance_to_image_instance(handles.selected_scene, 'verified_labels');


% --- Executes on button press in res_up_button.
function res_up_button_Callback(hObject, eventdata, handles)
% increases the change resoluition 
% (how many pixels the box/edge will move for a single edit command)
%
% hObject    handle to res_up_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.box_change_resolution = min(handles.box_change_resolution+3,500);

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in res_down_button.
function res_down_button_Callback(hObject, eventdata, handles)
% decreases the change resoluition 
% (how many pixels the box/edge will move for a single edit command)
%
% hObject    handle to res_down_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.box_change_resolution = max(handles.box_change_resolution-3,1);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in undo_button.
function undo_button_Callback(hObject, eventdata, handles)
% undoes the last deletion.
% reinserts the last deleted box/image to the end of the lists
% only does ONE. i.e can not get back the second to last deleted box 
%
% hObject    handle to undo_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if(~isfield(handles, 'last_deleted_name'))
  return;
end
  
  name = handles.last_deleted_name;
  boxes = handles.last_deleted_boxes;
  
  handles.image_names{end+1} = name;
  handles.bboxes{end+1} = boxes;
  
  % Update handles structure
  guidata(hObject, handles);

  
 

function [real_box] =  convert_cropped_box_to_real_box(large_box,cropped_box)
    real_box = [cropped_box(1)+large_box(1),...
                cropped_box(2)+large_box(2),... 
                cropped_box(3)+large_box(1),... 
                cropped_box(4)+large_box(2)];

% --- Executes on button press in use_mouse_button.
function use_mouse_button_Callback(hObject, eventdata, handles)
%Allows user to make new box by click mouse clicks
%
% hObject    handle to use_mouse_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%get the box
bbox = handles.bboxes{handles.cur_image_index};

[x,y,but] = ginput(2)

bbox(1) = max(x(1), 1);
bbox(2) = max(y(1),1);
bbox(3) = min(x(2), 1080);
bbox(4) = min(y(2), 1920);

bbox = convert_cropped_box_to_real_box(handles.large_box,bbox);
handles.bboxes{handles.cur_image_index} = bbox;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles);
