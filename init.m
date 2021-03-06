%this files defines file paths, names, and string literals that are used in
%multiple files, and may need to be changed for different machines.

scene_name = 'FB209';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%              DIRECTORIES             %%%%%%%%%%%%%%%

%directory that holds one directory per scene
BASE_PATH = '/Users/phahn/work/bvision/data/';

RGB_IMAGES_DIR = 'rgb/';

%holds original 424x512 depth images
UNREG_DEPTH_IMAGES_DIR = 'unreg_depth/';

%holds raw, registered depth images(1080x1920, but has 0's)
RAW_DEPTH_IMAGES_DIR = 'raw_depth/';

%holds outputs from reconstruction, and other data structures that relate
RECONSTRUCTION_DIR = 'reconstruction_results/';

%hold outputs from recongition systems(detectors, classifers, parsers, etc)
RECOGNITION_DIR = 'recognition_results/';

    FAST_RCNN_RESULTS = 'fast-rcnn/';

%holds miscellanueous files
MISC_DIR = 'misc/';








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%              FILE  NAMES             %%%%%%%%%%%%%%%

NAME_TO_POS_DIRS_MAT_FILE = 'name_to_pos_dirs_map.mat';
CAMERA_STRUCTS_FILE = 'camera_structs.mat';

NAME_TO_POINTS_STRUCTS_FILE = 'point_2d_structs.mat';
NAME_TO_POINT_ID_MAT_FILE = 'name_to_point_id.mat';
ID_TO_POINT_MAT_FILE = 'id_to_point.mat';

IMAGES_RECONSTRUCTION = 'images.txt';
POINTS_3D = 'points3D.txt';
POINTS_3D_MAT_FILE = 'points3D.mat';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%              VARIABLE  NAMES             %%%%%%%%%%%%%
NAME_TO_POS_DIRS_MAP = 'name_to_pos_dirs_map';
NAME_TO_POINTS_MAP = 'name_to_points_map';
ID_TO_POINT_MAP = 'id_to_point_map';
POINTS_3D_MATRIX = 'point_matrix';

CAMERA_STRUCTS = 'camera_structs';
SCALE = 'scale';

NAME_TO_POINTS_STRUCTS = 'point_2d_structs';
PIXEL_TO_POINT = 'points_2d';

IMAGE_NAME = 'image_name';
TRANSLATION_VECTOR = 't';
ROTATION_MATRIX = 'R';
WORLD_POSITION = 'world_pos';
DIRECTION = 'direction';
QUATERNION = 'quat';
SCALED_WORLD_POSITION = 'scaled_world_pos';

LABEL_TO_IMAGES_THAT_SEE_IT_MAP = 'label_to_images_that_see_it_map';
X = 'x';
Y = 'y';
DEPTH = 'depth';


DETECTIONS_STRUCT = 'dets';
