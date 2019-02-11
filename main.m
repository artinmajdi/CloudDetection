clear
clc
close all


%% User Parameteres
% IMPROTANT NOTE FOR THE USER: please always leave the _PP_ in your output tag name as its
% a clue to distinguish between original images and outputs produced in
% older simulations 

UserInfo.Directory.Code = '/media/data1/artin/CloudData/code';
UserInfo.Directory.Images = '/media/data1/artin/CloudData/images/';
UserInfo.Directory.GeoArea = '/media/data1/artin/CloudData/code/referenceImages/areaMatrix.mat';
UserInfo.Directory.LandMask = '/media/data1/artin/CloudData/code/referenceImages/LandMask_from_LatLong.jpg';
UserInfo.Directory.Output = UserInfo.Directory.Images;

% User Info
% WhichArea:    1. pixel Area
%               2. Geo Area
UserInfo.Overlay.Mode = 2;

% this number should be chosen based on the mode on UserInfo.Overlay.Mode
% for example an object in pixel domain might be between 100 and 200 pixels
% but in the Geo space it could be 200 and 400
UserInfo.ObjectSize.min = 800;
UserInfo.ObjectSize.max = 1e6;


% if this flag is set to false , only the objects within the range
% specified by the user (above) will be shown
UserInfo.Overlay.ShowAllObjects = false;
UserInfo.Overlay.Color.ObjectsOfInterest = 'yellow';
UserInfo.Overlay.Color.ObjectsOfNoInterest = 'red';

UserInfo.WriteImage.InfoOverlayedImage.Flag = true;
UserInfo.WriteImage.InfoOverlayedImage.Tag = '_PP_Final2';


UserInfo.WriteImage.CloudMask.Flag = true;
UserInfo.WriteImage.CloudMask.Tag = '_PP_cloudMask';

UserInfo.WriteImage.EmptyAreaMask.Flag = false;
UserInfo.WriteImage.EmptyAreaMask.Tag = '_PP_EmptyAreaMask';

UserInfo.WriteImage.EmptyArea.ObjectsOfInterest.Flag = false;
UserInfo.WriteImage.EmptyArea.ObjectsOfInterest.Tag = '_PP_Objects';

UserInfo.WriteImage.EmptyArea.ObjectsOfNoInterest.Flag = false;
UserInfo.WriteImage.EmptyArea.ObjectsOfNoInterest.Tag = '_PP_removedObjects';


%% 
addpath('UserInfo.Directory.Code')
extractObjects(UserInfo)
