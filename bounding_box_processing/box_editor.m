function varargout = box_editor(varargin)
% BOX_EDITOR MATLAB code for box_editor.fig
%      BOX_EDITOR, by itself, creates a new BOX_EDITOR or raises the existing
%      singleton*.
%
%      H = BOX_EDITOR returns the handle to a new BOX_EDITOR or the handle to
%      the existing singleton*.
%
%      BOX_EDITOR('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BOX_EDITOR.M with the given input arguments.
%
%      BOX_EDITOR('Property','Value',...) creates a new BOX_EDITOR or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before box_editor_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to box_editor_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help box_editor

% Last Modified by GUIDE v2.5 18-Jul-2016 15:19:07

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
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to box_editor (see VARARGIN)

init;
d = dir(ROHIT_BASE_PATH);
d = d(3:end);
all_scenes = {d.name};
handles.scene_pop_up_menu.String = cat(2, {'Pick a Scene'}, all_scenes);

% Choose default command line output for box_editor
handles.output = hObject;
handles.box_change_resolution = 5;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes box_editor wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = box_editor_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in delete_button.
function delete_button_Callback(hObject, eventdata, handles)
% hObject    handle to delete_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
images = handles.images;
image_names = handles.image_names;
bboxes = handles.bboxes;
cur_image_index = handles.cur_image_index;

images(cur_image_index) = [];
image_names(cur_image_index) = [];
bboxes(cur_image_index) = [];

if(cur_image_index > length(images))
  cur_image_index = 1;
end

handles.images = images;
handles.image_names = image_names;
handles.bboxes = bboxes;
handles.cur_image_index = cur_image_index;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles)



% --- Executes on button press in corner_up_button.
function corner_up_button_Callback(hObject, eventdata, handles)
% hObject    handle to corner_up_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
bbox = handles.bboxes{handles.cur_image_index};

if(bbox(4) - handles.box_change_resolution >= bbox(2))
  bbox(4) = bbox(4) - handles.box_change_resolution;
else
  move_dist = bbox(4)-bbox(2);
  bbox(4) = bbox(4) - move_dist;
end
handles.bboxes{handles.cur_image_index} = bbox;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles)


% --- Executes on button press in corner_down_button.
function corner_down_button_Callback(hObject, eventdata, handles)
% hObject    handle to corner_down_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
bbox = handles.bboxes{handles.cur_image_index};

if(bbox(4) + handles.box_change_resolution < size(handles.images{1},1))
  bbox(4) = bbox(4) + handles.box_change_resolution;
else
  move_dist = size(handles.images{1},1) - bbox(4);
  bbox(4) = bbox(4) + move_dist;
end
handles.bboxes{handles.cur_image_index} = bbox;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles)

% --- Executes on button press in corner_right_button.
function corner_right_button_Callback(hObject, eventdata, handles)
% hObject    handle to corner_right_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
bbox = handles.bboxes{handles.cur_image_index};

if(bbox(3) + handles.box_change_resolution < size(handles.images{1},2))
  bbox(3) = bbox(3) + handles.box_change_resolution;
else
  move_dist = size(handles.images{1},2) - bbox(3);
  bbox(3) = bbox(3) + move_dist;
end
handles.bboxes{handles.cur_image_index} = bbox;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles)


% --- Executes on button press in corner_left_button.
function corner_left_button_Callback(hObject, eventdata, handles)
% hObject    handle to corner_left_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
bbox = handles.bboxes{handles.cur_image_index};

if(bbox(3) - handles.box_change_resolution >= bbox(1))
  bbox(3) = bbox(3) - handles.box_change_resolution;
else
  move_dist = bbox(3)-bbox(1);
  bbox(3) = bbox(3) - move_dist;
end
handles.bboxes{handles.cur_image_index} = bbox;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles)




% --- Executes on button press in box_up_button.
function box_up_button_Callback(hObject, eventdata, handles)
% hObject    handle to box_up_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
bbox = handles.bboxes{handles.cur_image_index};

if(bbox(2) - handles.box_change_resolution >= 1)
  bbox(2) = bbox(2) - handles.box_change_resolution;
  bbox(4) = bbox(4) - handles.box_change_resolution;
else
  move_dist = bbox(2)-1;
  bbox(2) = bbox(2) - move_dist;
  bbox(4) = bbox(4) - move_dist;
end
handles.bboxes{handles.cur_image_index} = bbox;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles)


% --- Executes on button press in box_down_button.
function box_down_button_Callback(hObject, eventdata, handles)
% hObject    handle to box_down_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
bbox = handles.bboxes{handles.cur_image_index};

if(bbox(4) + handles.box_change_resolution < size(handles.images{1},1))
  bbox(2) = bbox(2) + handles.box_change_resolution;
  bbox(4) = bbox(4) + handles.box_change_resolution;
else
  move_dist = size(handles.images{1},1) - bbox(4);
  bbox(2) = bbox(2) + move_dist;
  bbox(4) = bbox(4) + move_dist;
end
handles.bboxes{handles.cur_image_index} = bbox;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles)



% --- Executes on button press in box_right_button.
function box_right_button_Callback(hObject, eventdata, handles)
% hObject    handle to box_right_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
bbox = handles.bboxes{handles.cur_image_index};

if(bbox(3) + handles.box_change_resolution < size(handles.images{1},2))
  bbox(1) = bbox(1) + handles.box_change_resolution;
  bbox(3) = bbox(3) + handles.box_change_resolution;
else
  move_dist = size(handles.images{1},2) - bbox(3);
  bbox(1) = bbox(1) + move_dist;
  bbox(3) = bbox(3) + move_dist;
end
handles.bboxes{handles.cur_image_index} = bbox;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles)

% --- Executes on button press in box_left_button.
function box_left_button_Callback(hObject, eventdata, handles)
% hObject    handle to box_left_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
bbox = handles.bboxes{handles.cur_image_index};
if(bbox(1) - handles.box_change_resolution > 0)
  bbox(1) = bbox(1) - handles.box_change_resolution;
  bbox(3) = bbox(3) - handles.box_change_resolution;
else
  move_dist = bbox(1)-1;
  bbox(1) = bbox(1) - move_dist;
  bbox(3) = bbox(3) - move_dist;
end
handles.bboxes{handles.cur_image_index} = bbox;

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles)


% --- Executes on button press in prev_button.
function prev_button_Callback(hObject, eventdata, handles)
% hObject    handle to prev_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.cur_image_index = handles.cur_image_index -1;
if(handles.cur_image_index < 1)
  handles.cur_image_index = length(handles.images);
end

guidata(hObject, handles);
draw_current_image_and_box(hObject, eventdata,handles)

% --- Executes on button press in next_button.
function next_button_Callback(hObject, eventdata, handles)
% hObject    handle to next_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.cur_image_index = handles.cur_image_index +1;
if(handles.cur_image_index > length(handles.images))
  handles.cur_image_index = 1;
end

guidata(hObject, handles);

draw_current_image_and_box(hObject, eventdata,handles)


% --- Executes on selection change in scene_pop_up_menu.
function scene_pop_up_menu_Callback(hObject, eventdata, handles)
% hObject    handle to scene_pop_up_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns scene_pop_up_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from scene_pop_up_menu
init;
contents = cellstr(get(hObject,'String'));
handles.selected_scene =  contents{get(hObject,'Value')};
instance_labels = dir(fullfile(ROHIT_META_BASE_PATH, handles.selected_scene, ...
                      'labels','raw_labels', 'bounding_boxes_by_instance', '*.mat'));
instance_labels = {instance_labels.name};

handles.label_pop_up_menu.String = cat(2,{'Pick a label'},instance_labels);

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
% hObject    handle to label_pop_up_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns label_pop_up_menu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from label_pop_up_menu
init;
text(.3,.5,'Loading Images...');

contents = cellstr(get(hObject,'String'));
handles.selected_instance =  contents{get(hObject,'Value')};
cur_instance_labels = load(fullfile(ROHIT_META_BASE_PATH, handles.selected_scene, ...
                            'labels', 'raw_labels', 'bounding_boxes_by_instance', handles.selected_instance));
handles.image_names = cur_instance_labels.image_names;
handles.bboxes = cur_instance_labels.boxes;

handles.cur_image_index = 1;

handles.images = cell(1,length(handles.image_names));



for il=1:length(handles.image_names)
  cur_name = handles.image_names{il};
  img = imread(fullfile(ROHIT_BASE_PATH,handles.selected_scene, 'rgb', ...
                      strcat(cur_name(1:10), '.png')));
  handles.images{il} = img;
end

draw_current_image_and_box(hObject, eventdata,handles)
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



function draw_current_image_and_box(hObject, eventdata,handles)

img = handles.images{handles.cur_image_index};
imshow(img);
hold on;
bbox = handles.bboxes{handles.cur_image_index};
rectangle('Position',[bbox(1) bbox(2) (bbox(3)-bbox(1)) (bbox(4)-bbox(2))], ... 
                     'LineWidth',2, 'EdgeColor','r');
hold off;





% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
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
end

