%this files defines file paths, names, and string literals that are used in
%multiple files, and may need to be changed for different machines.



addpath(genpath('./'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%              DIRECTORIES             %%%%%%%%%%%%%%%

%directory that holds one directory per scene
ROHIT_BASE_PATH = '/playpen/ammirato/Data/RohitData';

ROHIT_META_BASE_PATH = '/playpen/ammirato/Data/RohitMetaData';

BIGBIRD_BASE_PATH = '/playpen/ammirato/Data/BigBIRD';



RGB = 'rgb';
JPG_RGB = 'jpg_rgb';
RAW_DEPTH = 'raw_depth';
HIGH_RES_DEPTH = 'high_res_depth/';

%holds outputs from reconstruction, and other data structures that relate
RECONSTRUCTION_DIR = 'reconstruction_results/';

%hold outputs from recongition systems(detectors, classifers, parsers, etc)
RECOGNITION_DIR = 'recognition_results/';

    FAST_RCNN_DIR = 'fast-rcnn/';

%holds miscellanueous files
MISC_DIR = 'misc/';

%holds labels and data used for labeling
LABELING_DIR = 'labels';

    BBOXES_BY_INSTANCE_DIR = 'bounding_boxes_by_instance';
    BBOXES_BY_IMAGE_INSTANCE_DIR = 'bounding_boxes_by_image_instance_level';
    BBOXES_BY_IMAGE_CLASS_DIR = 'bounding_boxes_by_image_class_level';
    BBOXES_BY_CATEGORY_DIR = 'bounding_boxes_by_category';

    %data_for_labeling
    DATA_FOR_LABELING_DIR = 'data_for_labeling';
    
    IMAGES_FOR_LABELING_DIR = 'images_for_labeling';

    %
    GROUND_TRUTH_BBOXES_DIR = 'ground_truth_bboxes';
    
    PREPARED_IMAGES_DIR = 'prepared_images';
        DATA_DIR = 'data';
        IMAGES_DIR = 'images';


   LABELED_BBOXES_DIR = 'labeled_bboxes';

   REFERENCE_IMAGES_DIR = 'reference_images';

%%%%%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%              FILE  NAMES             %%%%%%%%%%%%%%%

NAME_TO_POS_DIRS_MAT_FILE = 'name_to_pos_dirs_map.mat';

IMAGES_RECONSTRUCTION = 'images.txt';

POINTS_3D = 'points3D.txt';

POINTS_3D_MAT_FILE = 'points3D.mat';

IMAGE_STRUCTS_FILE = 'image_structs.mat';
NEW_CAMERA_STRUCTS_FILE = 'new_camera_structs.mat';
POINT_2D_STRUCTS_FILE = 'point_2d_structs.mat';
NEW_POINT_2D_STRUCTS_FILE = 'new_point_2d_structs.mat';

ALL_LABELED_POINTS_FILE = 'all_labeled_points.txt';

ALL_IMAGES_THAT_SEE_POINT_FILE = 'all_images_that_see_point_file.txt';

LABEL_TO_IMAGES_THAT_SEE_IT_MAP_FILE = 'label_to_images_that_see_it_map.mat';

NAME_MAP_FILE = 'name_map.mat';

CAMERA_POS_DIR_FIG = 'camera_pos_dir.fig';
CAMERA_POS_DIR_IMAGE = 'camera_pos_dir.jpg';



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%              VARIABLE  NAMES             %%%%%%%%%%%%%
NAME_TO_POS_DIRS_MAP = 'name_to_pos_dirs_map';
POINTS_3D_MATRIX = 'point_matrix';
IMAGE_STRUCTS = 'image_structs';
POINT_2D_STRUCTS = 'point_2d_structs';

SCALE = 'scale';

IMAGE_NAME = 'image_name';
TRANSLATION_VECTOR = 't';
ROTATION_MATRIX = 'R';
WORLD_POSITION = 'world_pos';
DIRECTION = 'direction';
QUATERNION = 'quat';
SCALED_WORLD_POSITION = 'scaled_world_pos';
IMAGE_ID = 'image_id';
CAMERA_ID = 'camera_id';
POINTS_2D = 'points_2d';

LABEL_TO_IMAGES_THAT_SEE_IT_MAP = 'label_to_images_that_see_it_map';
X = 'x';
Y = 'y';
DEPTH = 'depth';


DETECTIONS_STRUCT = 'dets';



RGB_INDEX_STRING = '01';
RGB_INDEX = 1;
UNREG_DEPTH_INDEX_STRING = '02';
UNREG_DEPTH_INDEX = 2;
RAW_DEPTH_INDEX_STRING = '03';
RAW_DEPTH_INDEX = 3;
FILLED_DEPTH_INDEX_STRING = '04';
FILLED_DEPTH_INDEX = 4;


NAME_MAP = 'name_map';





%set intrinsic matrices for each kinect
intrinsic1 = [ 1.0700016292741097e+03, 0., 9.2726881773877119e+02; 0.,1.0691225545678490e+03, 5.4576099988165549e+02; 0., 0., 1. ];
intrinsic2 = [  1.0582854982177009e+03, 0., 9.5857576622458146e+0; 0., 1.0593799583771420e+03, 5.3110874137837084e+02; 0., 0., 1. ];
intrinsic3 = [ 1.0630462958838500e+03, 0., 9.6260473585485727e+02; 0., 1.0636103172708376e+03, 5.3489949221354482e+02; 0., 0., 1.];



