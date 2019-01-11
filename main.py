import os
import matplotlib.pyplot as plt
from skimage.filters import threshold_otsu as otsu
import numpy as np
from imageio import imread, imwrite
from tqdm import tqdm



Dir = '/media/data1/artin/Datasets/Clearing/Visible-(Jul29(211)-Aug10(223))/'
List = os.listdir(Dir)
List = [i for i in List if '.jpg' in i]
for ind, lst in tqdm(enumerate(List),desc='looping through images'):
    im = imread(Dir + List[ind])

    for i in range(3):
        ms = np.expand_dims(  im[...,i] > otsu(im[...,i])   ,axis=2)
        msk = ms if i == 0  else np.concatenate((msk,ms),axis=2)

    msk = (256*np.float32(msk))
    imwrite(Dir + List[ind].split('.jpg')[0] + '_mask.jpg' , msk)



# fig , axs = plt.subplots(2,2)
# axs[0,0].imshow(im)
# axs[0,1].imshow(msk[...,0],cmap='gray')
# axs[1,0].imshow(msk[...,1],cmap='gray')
# axs[1,1].imshow(msk[...,2],cmap='gray')
# plt.show()
print(im.shape)
