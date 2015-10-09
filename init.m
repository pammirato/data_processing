%this files defines file paths, names, and string literals that are used in
%multiple files, and may need to be changed for different machines.



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

IMAGES_RECONSTRUCTION = 'images.txt';

POINTS_3D = 'points3D.txt';

POINTS_3D_MAT_FILE = 'points3D.mat';







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%              VARIABLE  NAMES             %%%%%%%%%%%%%
NAME_TO_POS_DIRS_MAP = 'name_to_pos_dirs_map';
POINTS_3D_MATRIX = 'point_matrix';
