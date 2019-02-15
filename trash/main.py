import os
import matplotlib.pyplot as plt
from skimage.filters import threshold_otsu as otsu
import numpy as np
from imageio import imread, imwrite
from tqdm import tqdm
from scipy.ndimage import morphology
import cv2
import warnings
warnings.simplefilter("once",category=Warning)

Dir = '/media/data1/artin/CloudData/images/'

Land = imread(Dir + 'Land.jpg')
Land2 = Land[...,0] > 100

RegionOfInterest = imread(Dir + 'RegionOfInterest.jpg')
RegionOfInterest = RegionOfInterest[...,0] > 100

def creatinMask(Dir, Land2):

    List = [i for i in os.listdir(Dir) if '.jpg' in i and 'mask' not in i]
    LandIx = np.where(Land2)

    for _, lst in tqdm(enumerate(List),desc='looping through images'):
        im = imread(Dir + lst)
        # print('ind',ind)
        for i in range(3):

            im2 = im[...,i]
            im2[LandIx] = 0
            im[...,i] = im2

            msk2 = im[...,i] > otsu(im[...,i])

            ms = np.expand_dims(msk2,axis=2)
            msk = ms if i == 0  else np.concatenate((msk,ms),axis=2)

        msk = (256*np.float32(msk))
        imwrite(Dir + lst.split('.jpg')[0] + '_mask.jpg' , msk)

def creatingThePatternMask(Dir, Land2, RegionOfInterest):
    List = [i for i in os.listdir(Dir) if 'mask.jpg' in i]
    LandIx = np.where(Land2 == 1)
    nROI_Ix = np.where(RegionOfInterest == 0)
    ROI_Ix = np.where(RegionOfInterest == 1)

    Area = 0.9*RegionOfInterest.sum()
    for ix, lst in enumerate(List): # ,desc='looping through images'):
        
        print(ix,'/',len(List))
        msk = imread(Dir + lst)[...,0] > 100        
        msk2 = 1 - msk
        msk2[nROI_Ix] = 0
        if msk2[ROI_Ix].sum() > Area: msk2 *= 0

        msk2[LandIx] = 0
        msk2 = (256*np.float32(msk2))
        
        imwrite(Dir + lst.split('.jpg')[0] + '_Pattern.jpg' , msk2)

def creatingTheVideo(Dir):
        # image_folder = 'images'
        video_name = 'video.avi'
        Dir2 = Dir
        List = [i for i in os.listdir(Dir2) if 'goes' in i and '_Pattern.jpg' not in i and 'mask.jpg' not in i]
        List.sort()
        frame = cv2.imread(os.path.join(Dir2, List[0].split('.jpg')[0] + '_mask_Pattern.jpg' ))
        height, width, layers = frame.shape

        video = cv2.VideoWriter(Dir2 + 'pattern.avi', 0, 3, (width,height))
        video2 = cv2.VideoWriter(Dir2 + 'original.avi', 0, 3, (width,height))

        for image in tqdm(List):

                im = cv2.imread(os.path.join(Dir2, image))
                pattern = cv2.imread(os.path.join(Dir2, image.split('.jpg')[0] + '_mask_Pattern.jpg'))
                # A = np.concatenate((im,pattern),axis=1)
                video.write(pattern)
                video2.write(im)

        cv2.destroyAllWindows()
        video.release()


creatinMask(Dir, Land2)

creatingThePatternMask(Dir, Land2, RegionOfInterest)

# creatingTheVideo(Dir)
