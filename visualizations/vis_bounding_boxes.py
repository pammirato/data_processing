import init as init #has file paths
import os
import json
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from scipy import misc



def vis_bounding_boxes(scene_name):
  """ Visualizes bounding boxes and images in the scene.
  Allows user to navigate the scene via the movement pointers using the keyboard"""


  #set up scene specfic paths
  scene_path = os.path.join(init.ROHIT_BASE_PATH,scene_name)
  images_path = os.path.join(scene_path,'jpg_rgb')
  annotations_path = os.path.join(scene_path,'annotations.json')

  #load data
  image_names = os.listdir(images_path)
  image_names.sort()
  ann_file = open(annotations_path)
  annotations = json.load(ann_file)


  #set up for first image
  cur_image_name = image_names[0]
  next_image_name = ''
  move_command = ''

  fig,ax = plt.subplots(1)
  while (move_command != 'q'):

    #load the current image and annotations 
    rgb_image = misc.imread(os.path.join(images_path,cur_image_name))
    boxes = annotations[cur_image_name]['bounding_boxes']

    #plot the image and draw the boxes
    plt.cla()
    ax.imshow(rgb_image)
    plt.title(cur_image_name)


    for box in boxes:
      # Create a Rectangle patch
      rect = patches.Rectangle((box[0],box[1]),box[2]-box[0],box[3]-box[1],
                                linewidth=2,edgecolor='r',facecolor='none')

      # Add the patch to the Axes
      ax.add_patch(rect)
    #for boxes

    #draw the plot on the figure
    plt.draw()
    plt.pause(.001)

    #get input from user 
    move_command = raw_input('Enter command: ')


    #get the next image name to display based on the 
    #user input, and the annotation.
    if move_command == 'w':
      next_image_name = annotations[cur_image_name]['forward']
    elif move_command == 'a':
      next_image_name = annotations[cur_image_name]['rotate_ccw']
    elif move_command == 's':
      next_image_name = annotations[cur_image_name]['backward']
    elif move_command == 'd':
      next_image_name = annotations[cur_image_name]['rotate_cw']
    elif move_command == 'e':
      next_image_name = annotations[cur_image_name]['left']
    elif move_command == 'r':
      next_image_name = annotations[cur_image_name]['right']

    #if the user inputted move is valid (there is an image there) 
    #then update the image to display. If the move was not valid, 
    #the current image will be displayed again
    if next_image_name != '':
      cur_image_name = next_image_name

  #end while not 'q'





