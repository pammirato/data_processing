%this files defines file paths, names, and string literals that are used in
%multiple files, and may need to be changed for different machines.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%              DIRECTORIES             %%%%%%%%%%%%%%%

%directory that holds one directory per scene
BASE_PATH = '/playpen/ammirato/Data/';

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

%holds labels and data used for labeling
LABELING_DIR = 'labeling';

    %data_for_labeling
    DATA_FOR_LABELING_DIR = 'data_for_labeling';







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%              FILE  NAMES             %%%%%%%%%%%%%%%

NAME_TO_POS_DIRS_MAT_FILE = 'name_to_pos_dirs_map.mat';

IMAGES_RECONSTRUCTION = 'images.txt';

POINTS_3D = 'points3D.txt';

POINTS_3D_MAT_FILE = 'points3D.mat';

CAMERA_STRUCTS_FILE = 'camera_structs.mat';

ALL_LABELED_POINTS_FILE = 'all_labeled_points.txt';





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%              VARIABLE  NAMES             %%%%%%%%%%%%%
NAME_TO_POS_DIRS_MAP = 'name_to_pos_dirs_map';
POINTS_3D_MATRIX = 'point_matrix';
CAMERA_STRUCTS = 'camera_structs';

SCALE = 'scale';

IMAGE_NAME = 'name';
TRANSLATION_VECTOR = 't';
ROTATION_MATRIX = 'R';
WORLD_POSITION = 'world_pos';
DIRECTION = 'direction';
QUATERNION = 'quat';
SCALED_WORLD_POSITION = 'scaled_world_pos';




