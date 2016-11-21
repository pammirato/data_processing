%this files defines file paths, names, and string literals that are used in
%multiple files, and may need to be changed for different machines.

%TODO -  clean

%CLEANED - no
%TESTED - no

addpath(genpath('./'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%              DIRECTORIES             %%%%%%%%%%%%%%%

%directory that holds one directory per scene
ROHIT_BASE_PATH = '/playpen/ammirato/Data/RohitData';

ROHIT_META_BASE_PATH = '/playpen/ammirato/Data/RohitMetaData';
ROHIT_METAMETA_BASE_PATH = '/playpen/ammirato/Data/RohitMetaMetaData';

BIGBIRD_BASE_PATH = '/playpen/ammirato/Data/BigBIRD';


%image directories
RGB = 'rgb';
JPG_RGB = 'jpg_rgb';
RAW_DEPTH = 'raw_depth';
HIGH_RES_DEPTH = 'high_res_depth';
IMPROVED_DEPTH = 'improved_depths';

%holds outputs from reconstruction, and other data structures that relate 
RECONSTRUCTION_SETUP = 'reconstruction_setup/';
RECONSTRUCTION_RESULTS = 'reconstruction_results/';

%hold outputs from recongition systems(detectors, classifers, parsers, etc)
RECOGNITION_RESULTS = 'recognition_results/';

    FAST_RCNN_DIR = 'fast_rcnn/';

%holds miscellanueous files
MISC_DIR = 'misc/';

%holds labels and data used for labeling
LABELING_DIR = 'labels';

  HAND_LABEL_NAMES = 'images_to_hand_label.txt';
  MISSING_BOXES_NAMES = 'images_to_hand_check_for_missing_boxes.txt';
  RAW_LABELS = 'raw_labels';
  VERIFIED_LABELS = 'verified_labels';
  LOOSE_LABELS = 'loose_labels';


  

    BBOXES_BY_INSTANCE = 'bounding_boxes_by_instance';
    BBOXES_BY_IMAGE_INSTANCE = 'bounding_boxes_by_image_instance';
    BBOXES_BY_IMAGE_CLASS = 'bounding_boxes_by_image_class';
    BBOXES_BY_CLASS = 'bounding_boxes_by_class';

    %data_for_labeling
    DATA_FOR_LABELING_DIR = 'data_for_labeling';
    
    IMAGES_FOR_LABELING_DIR = 'images_for_labeling';

    %
    GROUND_TRUTH_BBOXES_DIR = 'ground_truth_bboxes';
    
    PREPARED_IMAGES_DIR = 'prepared_images';
        DATA_DIR = 'data';
        IMAGES_DIR = 'images';


      OBJECT_POINT_CLOUDS = 'object_point_clouds';
      ORIGINAL_POINT_CLOUDS = 'original';
      SCALED_POINT_CLOUDS = 'scaled';
      



   LABELED_BBOXES_DIR = 'labeled_bboxes';

   REFERENCE_IMAGES_DIR = 'reference_images';





  DENSITY_EXPERIMENTS_DIR = 'density_experiments';
    SCORE_IMAGES_DIR = 'score_images';
    SCORE_ARRAYS_BY_INSTANCE_DIR = 'score_arrays_by_instance';
    DIFF_IMAGES_DIR = 'score_diff_images';
  DENSITY_EXPERIMENT_STRUCTS_DIR = 'density_experiment_structs';










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







%% density experiment struct fields

%these are all maps based on iou threshold (0-1)
NUM_IOU_WITH_GT_BOXES = 'num_iou_gt';
NUM_GT_BOXES = 'num_gt';
PERCENT_IOU_WITH_GT_BOXES = 'percent_iou_gt';









%set intrinsic matrices for each kinect
intrinsic1 = [ 1.0700016292741097e+03, 0., 9.2726881773877119e+02; 0.,1.0691225545678490e+03, 5.4576099988165549e+02; 0., 0., 1. ];
intrinsic2 = [  1.0582854982177009e+03, 0., 9.5857576622458146e+0; 0., 1.0593799583771420e+03, 5.3110874137837084e+02; 0., 0., 1. ];
intrinsic3 = [ 1.0630462958838500e+03, 0., 9.6260473585485727e+02; 0., 1.0636103172708376e+03, 5.3489949221354482e+02; 0., 0., 1.];



