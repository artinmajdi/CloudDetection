function [output1, output2] = extractObjects(UserInfo)

    
    Input = readingInputData(UserInfo.Directory);
    if UserInfo.Overlay.Mode == 2
        UserInfo.unit = 'Km2';
    else
        UserInfo.unit = 'Pixel';
    end
    
    
    ListImages = func_listImages(UserInfo.Directory.Images);
    
    for ind = 1 % :length(ListImages)
                
        UserInfo.name = strsplit(ListImages(ind).name,'.jpg'); UserInfo.name = UserInfo.name{1};
        
        disp(['ind: (',num2str(ind),'/',num2str(length(ListImages)), ')   ', UserInfo.name])

        imm = imread([UserInfo.Directory.Images , UserInfo.name, '.jpg']);
        
%         immOg = imm;
        for i = 1:3
            imm(:,:,i) = adapthisteq(imm(:,:,i));
        end
%         output1  = creatingEmptyAreaMask(immOg , Input, UserInfo);
        output1  = creatingEmptyAreaMask(imm , Input, UserInfo);
        
        output2 = Apply_Detection(imm, output1.EmptyAreaMask, Input, UserInfo);                       
                
    end

end
%%

% imm2 = immOg;
% A2 = output1En.EmptyAreaMask;
% imm2(:,:,1) = imm2(:,:,1) + im2uint8(edge(A2));
% ax(1) = subplot(121); imshow(imm2)
% 
% 
% A2 = imopen(A2,strel('disk',4));
% % A2 = output1En.EmptyAreaMask;
% imm2 = imm;
% imm2(:,:,1) = imm2(:,:,1) + im2uint8(edge(A2));
% ax(2) = subplot(122); imshow(imm2) , title('enhanced')
% linkaxes(ax)

%%
function Input = readingInputData(Directory)

    Ar = load(Directory.GeoArea);
    Input.GeoAreaValues = Ar.area;
    Input.GeoAreaValues(isnan(Input.GeoAreaValues)) = 0;
    Input.Land = imread(Directory.LandMask) > 100;
    Input.ROI = imread(Directory.ROI);
    Input.ROI = Input.ROI(:,:,1) > 100;
    load(Directory.lat)
    load(Directory.lon)
    Input.lat = lat;
    Input.lon = lon;
    
end

function output = Apply_Detection(imm, EmptyAreaMask, Input, UserInfo)
    
%     mask = imclose(EmptyAreaMask,strel('disk',2));
    mask = EmptyAreaMask;
    mask = imopen(mask,strel('disk',4));

    obj = regionprops(mask,'PixelIdxList','PixelList','Area','Centroid','BoundingBox');    
    
    %% Filtering object of interest based on size 
    
    disp('         Filtering object of interest based on size')
    
	Interested = FilteringObjects(obj, Input, UserInfo, size(mask) , 'Interested');
          
    if UserInfo.Overlay.ShowAllObjects || UserInfo.WriteImage.EmptyArea.ObjectsOfNoInterest.Flag
        NotInterested = FilteringObjects(obj, Input, UserInfo, size(mask), 'NotInterested');
    end
     
    %% overlaying borders & Info on image
    
    disp('         overlaying borders & Info on image')
    
	output.Image = overlayObjectsOnImage(imm, Interested.edgeImage, 'Interested');
    output.Image = overlayInfoOnImage(output.Image, Interested.Info, UserInfo.Overlay.Color.ObjectsOfInterest, UserInfo);
          
    if UserInfo.Overlay.ShowAllObjects
        output.Image = overlayObjectsOnImage(output.Image, NotInterested.edgeImage, 'NotInterested');
        output.Image = overlayInfoOnImage(output.Image, NotInterested.Info, UserInfo.Overlay.Color.ObjectsOfNoInterest, UserInfo);
    end
        
    if UserInfo.WriteImage.InfoOverlayedImage.Flag
        imwrite(output.Image, [UserInfo.Directory.Output , UserInfo.name, UserInfo.WriteImage.InfoOverlayedImage.Tag , '.jpg'])
    end   
    
    
    %% overlay info on object mask
    
    if UserInfo.WriteImage.EmptyArea.ObjectsOfInterest.Flag
        
        disp('         overlaying borders & Info on Object Mask')        
        
        Interested.ColoredObjectsMask = overlayInfoOnColoredObjectsMask(Interested.ColoredObjectsMask, Interested.Info, 'black');
        output.ObjectsData = Interested;
        
        imwrite(Interested.ColoredObjectsMask, [UserInfo.Directory.Output , UserInfo.name, UserInfo.WriteImage.EmptyArea.ObjectsOfInterest.Tag, '.jpg'])
        
        if UserInfo.WriteImage.EmptyArea.ObjectsOfNoInterest.Flag
            
            NotInterested.ColoredObjectsMask = overlayInfoOnColoredObjectsMask(NotInterested.ColoredObjectsMask, NotInterested.Info, 'black');
            output.removedObjectsData = NotInterested;

            imwrite(NotInterested.ColoredObjectsMask, [UserInfo.Directory.Output , UserInfo.name, UserInfo.WriteImage.EmptyArea.ObjectsOfNoInterest.Tag, '.jpg'])

        end
        
    end
        


end

function ColoredObjectsMask = overlayInfoOnColoredObjectsMask(ColoredObjectsMask, Info, color)
    if ~isempty(Info.Centroid)       
        ColoredObjectsMask = insertMarker(ColoredObjectsMask, Info.Centroid,'x','Color',color);
        ColoredObjectsMask = insertText(ColoredObjectsMask, Info.Centroid, Info.Area,'TextColor',color,'BoxOpacity',0);
    end
end

function imm = overlayInfoOnImage(imm, Info, color, UserInfo)
    if ~isempty(Info.Centroid)       
        imm = insertMarker(imm, Info.Centroid,'x','Color',color);
        imm = insertText(imm, Info.Centroid, Info.Area,'TextColor',color,'BoxOpacity',0,'FontSize',20);        
        imm = insertText(imm, [150,150], ['Unit: ' UserInfo.unit],'TextColor','red','BoxOpacity',0.5,'FontSize',40);       
        imm = insertText(imm, [150,230], ['name: ' UserInfo.name],'TextColor','red','BoxOpacity',0.5,'FontSize',40);       
        imm = insertText(imm, [150,310], ['object size: ' num2str([UserInfo.ObjectSize.min, UserInfo.ObjectSize.max])],'TextColor','red','BoxOpacity',0.5,'FontSize',40);       
    end
end

function imm = overlayObjectsOnImage(imm, edgeImage, mode)
   
    if strcmp(mode, 'Interested')
        imm(:,:,1) = imm(:,:,1) + 255*uint8(edgeImage);
        imm(:,:,2) = imm(:,:,2) + 248*uint8(edgeImage);
    else
        imm(:,:,3) = imm(:,:,3) + 255*uint8(edgeImage);
    end
end

function output = FilteringObjects(obj, Input, UserInfo, shapeMsk, mode)

    if UserInfo.Overlay.Mode == 1
        Area = cat(1,obj.Area); 
    else
        Area = ActualGeoArea(obj,Input.GeoAreaValues);
    end

    if strcmp(mode, 'Interested')
        objects = obj(Area >= UserInfo.ObjectSize.min & Area <= UserInfo.ObjectSize.max);
    else
        objects = obj(Area < UserInfo.ObjectSize.min | Area > UserInfo.ObjectSize.max);
    end

    objects = removeObjects_NotIn_ROI(UserInfo, Input, objects);

    ObjectsMask = zeros(shapeMsk);
    ObjectsMask(cat(1,objects.PixelIdxList)) = 1 ;
    ObjectsMask = ObjectsMask > 0;
%     ObjectsMask = bwareaopen(ObjectsMask,50);
    
    output.edgeImage = edge(ObjectsMask);
%     X = objects(1).PixelList;
%     patch(X(:,1),X(:,2),'yellow')
    ObjectsMaskFilled = edge(imfill(ObjectsMask,'holes'));
    ObjectsMaskFilled = imclose(ObjectsMaskFilled,strel('disk',2));
%     ObjectsMask2E = edge(ObjectsMask2);
    
    objectsF = regionprops( ObjectsMaskFilled, 'PixelIdxList','PixelList');  
%     objectsF2 = regionprops( ObjectsMaskFilled, 'PixelList'); 
    stats = regionprops('table', ObjectsMaskFilled, 'PixelIdxList','PixelList');  

    for objIx = 1:length(objectsF)
        objectsF(objIx).CentroidGeo = [mean(Input.lat(objectsF(objIx).PixelIdxList)) , mean(Input.lon(objectsF(objIx).PixelIdxList))];
        objectsF(objIx).PixelListGeo = realPixelListANDCentroid(Input,objectsF(objIx).PixelList);
    end
    CentroidGeo = cat(1,objectsF.CentroidGeo);
    PixelListGeo = {objectsF.PixelListGeo}';
    output.Info.TableResults = [table(CentroidGeo) , stats , table(PixelListGeo)];
%     x = imageWidth * ( pointLon - ImageExtentLeft ) / (ImageExtentRight - ImageExtentLeft);
%     y = imageHeight * ( 1 - ( pointLat - ImageExtentBottom) / (ImageExtentTop - mImageExtentBottom));
    
    
    
    L = bwlabel(ObjectsMask);
    output.ColoredObjectsMask = label2rgb(L);    
    output.Info.Centroid = cat(1,objects.Centroid);
    
    if UserInfo.Overlay.Mode == 1
        output.Info.Area = cat(1,objects.Area); 
    else
        output.Info.Area = ActualGeoArea(objects,Input.GeoAreaValues);
    end
    
end

function PixelListGeo = realPixelListANDCentroid(Input,PixelList)
    PixelListGeo = PixelList*0;
    sz = size(PixelList);
    for i=1:sz(1)
       PixelListGeo(i,:) = [ Input.lat(PixelList(i,2),PixelList(i,1))  ,  Input.lon(PixelList(i,2),PixelList(i,1))];           
    end 
%     CentroidGeo1 = sum(PixelListGeo.*PixelList)./sum(PixelList);
end

function objects = removeObjects_NotIn_ROI(UserInfo, Input, objects)

    if (UserInfo.Overlay.ApplyROI_To_CloudOrFinalObjects == 2)   
        FinalObj = [];
        for i = 1:length(objects)
            if sum(sum(Input.ROI(cat(1,objects(i).PixelIdxList)))) ~= 0
                FinalObj = [FinalObj;objects(i)];
            end
        end
        objects = FinalObj;
    end
end

function background = backgroundDetector(mask)

    background = mask*0;
    background(mask ==0) = 1;
    background = cat(3,background,background,background);
end

function GeoArea = ActualGeoArea(obj,GeoAreaValues)
    GeoArea = zeros(length(obj),1);
    for Ix=1:length(obj)
        GeoArea(Ix) = round(sum(GeoAreaValues(cat(1,obj(Ix).PixelIdxList))));
    end
end