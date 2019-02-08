% clear
% clc
% close all


Dir = '/media/data1/artin/CloudData/images/';
imwrite(Land_MASK, [Dir , 'LandMask_from_LatLong.jpg'])
 
% load('Pixels_geographical information.mat')

% extractObjects(Dir,area)