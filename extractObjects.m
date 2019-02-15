function [output1, ObjectsInfo] = extractObjects(UserInfo)
    
    Input = readingInputData(UserInfo);
    UserInfo = setUnit(UserInfo);       
    
    for ind = 1 % :length(ListImages)                
        [output1, ObjectsInfo] = func_ObjectExtracter(Input, UserInfo, ind);                                    
    end
        
    function UserInfo = setUnit(UserInfo)
        if UserInfo.Overlay.Mode == 2
            UserInfo.unit = 'Km2';
        else
            UserInfo.unit = 'Pixel';
        end
    end

    function Input = readingInputData(UserInfo)

        Ar = load(UserInfo.Directory.AreaGeo);
        Input.GeoAreaValues = Ar.area;
        Input.GeoAreaValues(isnan(Input.GeoAreaValues)) = 0;
        Input.Land = imread(UserInfo.Directory.LandMask) > 100;
        Input.ROI = imread(UserInfo.Directory.ROI);
        Input.ROI = Input.ROI(:,:,1) > 100;
        a = load(UserInfo.Directory.lat);
        b = load(UserInfo.Directory.lon);
        Input.lat = a.lat;
        Input.lon = b.lon;
        Input.ListImages = func_listImages();
        
        
        function ListImages = func_listImages()
            List = dir(UserInfo.Directory.Images);
            ListImages = [];
            for ls = 1:length(List)
                if ~contains(List(ls).name, '_PP_') && contains(List(ls).name, 'jpg') && contains(List(ls).name, 'goes') 
                   ListImages = [ListImages,List(ls)];
                end
            end
        end    
    end
end

%%
function [output1, ObjectsInfo] = func_ObjectExtracter(Input, UserInfo, ind)

    UserInfo.name = strsplit(Input.ListImages(ind).name,'.jpg'); UserInfo.name = UserInfo.name{1};

    disp(['ind: (',num2str(ind),'/',num2str(length(Input.ListImages)), ')   ', UserInfo.name])

    imm = imread([UserInfo.Directory.Images , UserInfo.name, '.jpg']);

    imm = EnhanceImage(imm);

    output1 = creatingInitialMask(imm , Input, UserInfo);

    ObjectsInfo = Apply_Detection(imm, output1.EmptyAreaMask, Input, UserInfo);  

    
    function imm = EnhanceImage(imm)        
        for i = 1:length(size(imm))
            imm(:,:,i) = adapthisteq(imm(:,:,i));
        end      
        
        disp('         Normalizing the Image')
        imm = normalizing(imm);

        function im = normalizing(im)
            im = im2double(im);
            im = (im - min(im(:))) / (max(im(:)) - min(im(:)));
        end
    end

end

function Dataout = Apply_Detection(imm, EmptyAreaMask, Input, UserInfo)
    
    mask = preprocessingMask(EmptyAreaMask);
    
    obj = regionprops(mask,'PixelIdxList','PixelList','Area','Centroid','BoundingBox');    
    
    %% Filtering object of interest based on size 
    
    disp('         Filtering object of interest based on size')
    Dataout = FilteringObjects(obj, Input, UserInfo, size(mask));
     
    %% overlaying borders & Info on image
    
    disp('         overlaying borders & Info on image')
    Overlaying_Info_On_Image(Dataout, imm);
        
    %% overlay info on object mask
    
    if UserInfo.WriteImage.EmptyArea.ObjectsOfInterest.Flag
        Overlay_Info_On_Mask_of_Objects(Dataout);        
    end

    %% sub functions 
    
    function Overlaying_Info_On_Image(Dataout, imm)
                
        Image = Draw_Edge_On_Image(imm, Dataout.Interested.Mask_of_Objects, 'Interested');        
        Image = overlay_Centroid_Area_On_Image(Image, Dataout.Interested, UserInfo.Overlay.Color.ObjectsOfInterest);

        if UserInfo.Overlay.ShowAllObjects
            Image = Draw_Edge_On_Image(Image, Dataout.NotInterested.Mask_of_Objects , 'NotInterested');            
            Image = overlay_Centroid_Area_On_Image(Image, Dataout.NotInterested.objects_Geo , UserInfo.Overlay.Color.ObjectsOfNoInterest);
        end

        if UserInfo.WriteImage.InfoOverlayedImage.Flag
            imwrite(Image, [UserInfo.Directory.Output , UserInfo.name, UserInfo.WriteImage.InfoOverlayedImage.Tag , '.jpg'])
        end 
        
        function imm = Draw_Edge_On_Image(imm, Mask_of_Objects, mode)
            edgeImage = im2double(edge(Mask_of_Objects));
            if strcmp(mode, 'Interested')
                imm(:,:,1) = imm(:,:,1) + edgeImage;
                imm(:,:,2) = imm(:,:,2) + (248/256)*edgeImage;
            else
                imm(:,:,3) = imm(:,:,3) + edgeImage;
            end
        end

        function imm = overlay_Centroid_Area_On_Image(imm, Data , color)

            if UserInfo.Overlay.Mode == 1
                Area = cat(1,Data.objects.Area); 
            else
                Area = cat(1,Data.objects.AreaGeo);                 
            end
            
            Centroid = cat(1,Data.objects.Centroid);
            if ~isempty(Centroid)       
                imm = insertMarker(imm, Centroid,'x','Color',color);
                imm = insertText(imm, Centroid, Area,'TextColor',color,'BoxOpacity',0,'FontSize',20);        
                imm = insertText(imm, [150,150], ['Unit: ' UserInfo.unit],'TextColor','red','BoxOpacity',0.5,'FontSize',40);       
                imm = insertText(imm, [150,230], ['name: ' UserInfo.name],'TextColor','red','BoxOpacity',0.5,'FontSize',40);       
                imm = insertText(imm, [150,310], ['object size: ' num2str([UserInfo.Method.ObjectSize.min, UserInfo.Method.ObjectSize.max])],'TextColor','red','BoxOpacity',0.5,'FontSize',40);       
            end
            
        end

    end

    function Overlay_Info_On_Mask_of_Objects(Dataout)
        disp('         overlaying borders & Info on Object Mask')        
      
        apply_Overlay_Info_On_Mask_of_Objects(Dataout.Interested.Mask_of_Objects, Dataout.Interested.Info, 'black', UserInfo.WriteImage.EmptyArea.ObjectsOfInterest.Tag);

        if UserInfo.WriteImage.EmptyArea.ObjectsOfNoInterest.Flag           
            apply_Overlay_Info_On_Mask_of_Objects(Dataout.NotInterested.Mask_of_Objects, Dataout.NotInterested.Info, 'black', UserInfo.WriteImage.EmptyArea.ObjectsOfNoInterest.Tag);
        end
        
        function apply_Overlay_Info_On_Mask_of_Objects(Mask_of_Objects, Info, color, Tag)
            
            maskOut = bwlabel(Mask_of_Objects);
            maskOut = label2rgb(maskOut);  
            if ~isempty(Info.Centroid)       
                maskOut = insertMarker(maskOut, Info.Centroid,'x','Color',color);
                maskOut = insertText(maskOut, Info.Centroid, Info.Area,'TextColor',color,'BoxOpacity',0);
            end
            imwrite(maskOut, [UserInfo.Directory.Output , UserInfo.name, Tag, '.jpg'])  
            
        end

    end
     
    function mask = preprocessingMask(mask)
        if UserInfo.Method.Disc_Close_size ~= 0
            mask = imclose(mask,strel('disk',UserInfo.Method.Disc_Close_size));
        end

        if UserInfo.Method.Disc_Open_size ~= 0
            mask = imopen(mask,strel('disk',UserInfo.Method.Disc_Open_size));
        end
    end

end

function Dataout = FilteringObjects(obj, Input, UserInfo, shapeMsk)

	Dataout.Interested = ApplyfilterObject(obj, shapeMsk , 'Interested');
          
    if UserInfo.Overlay.ShowAllObjects || UserInfo.WriteImage.EmptyArea.ObjectsOfNoInterest.Flag
        Dataout.NotInterested = ApplyfilterObject(obj, shapeMsk, 'NotInterested');
    end
    
    function output = ApplyfilterObject(obj, shapeMsk, mode)
        

        objects_Pixel = filterObjects_BasedOnArea(obj);   
        
        objects_Pixel = removeObjects_NotIn_ROI(objects_Pixel);
        
        output.Mask_of_Objects = creatingMaskFromPixelIdx(objects_Pixel, shapeMsk);   
        
        output.objects = Add_GeoCenter_GeoPixelList_GeoArea(output.Mask_of_Objects);
  
        function Mask_of_Objects = creatingMaskFromPixelIdx(objects, shapeMsk)
            Mask_of_Objects = zeros(shapeMsk);
            Mask_of_Objects(cat(1,objects.PixelIdxList)) = 1 ;
            Mask_of_Objects = Mask_of_Objects > 0;
        end
        
        function objects = filterObjects_BasedOnArea(obj2)
            
            Area = func_Area(obj2);
            
            if strcmp(mode, 'Interested')
                objects = obj2(Area >= UserInfo.Method.ObjectSize.min & Area <= UserInfo.Method.ObjectSize.max);
            else
                objects = obj2(Area < UserInfo.Method.ObjectSize.min | Area > UserInfo.Method.ObjectSize.max);
            end    
            
            function Area = func_Area(objects)        
                if UserInfo.Overlay.Mode == 1
                    Area = cat(1,objects.Area); 
                else
                    Area = ActualGeoArea(objects);
                end

                function AreaGeo = ActualGeoArea(obj)
                    AreaGeo = zeros(length(obj),1);
                    for Ix=1:length(obj)
                        AreaGeo(Ix) = round(sum(Input.GeoAreaValues(obj(Ix).PixelIdxList)));
                    end
                end
            end

        end

        function objects_Geo = Add_GeoCenter_GeoPixelList_GeoArea(mask2) 
                        
            [mask2, NumberOfObjects] = LabelingMask(mask2);
            
            objects_Orig = ModifiedRegionProps(mask2,NumberOfObjects);
            
            mask2 = detectingEdges(mask2);
            
            objects_EdgeMask = ModifiedRegionProps(mask2,NumberOfObjects);
            objects_Geo = addGeoInfo(objects_Orig, objects_EdgeMask);

            function [mask2, Inx] = LabelingMask(mask2)
                mask2 = bwlabel(mask2);            
                Inx = max(mask2(:)) + 1;
                mask2(mask2 ==1) = Inx;                
            end
            
            function mask = detectingEdges(mask2)
                mask2 = imfill(mask2,'holes');
                mask = imdilate(mask2,strel('disk',2)).*im2double(edge(mask2,'canny'));                
            end
            
            function objects_Geo = addGeoInfo(objects_Orig, objects_EdgeMask)
                objects_Geo = objects_EdgeMask;
                for objIx = 1:length(objects_Geo)
                    objects_Geo(objIx).CentroidGeo = [mean(Input.lat(objects_Orig(objIx).PixelIdxList)) , mean(Input.lon(objects_Orig(objIx).PixelIdxList))];
                    objects_Geo(objIx).PixelListBorderGeo = [ Input.lat(objects_EdgeMask(objIx).PixelIdxList)  ,  Input.lon(objects_EdgeMask(objIx).PixelIdxList)];                 
                    objects_Geo(objIx).PixelListGeo = [ Input.lat(objects_Orig(objIx).PixelIdxList)  ,  Input.lon(objects_Orig(objIx).PixelIdxList)];                 
                    objects_Geo(objIx).AreaGeo = round(sum(Input.GeoAreaValues( objects_Orig(objIx).PixelIdxList )));
                    objects_Geo(objIx).Centroid = objects_Orig(objIx).Centroid;
                    objects_Geo(objIx).Area = objects_Orig(objIx).Area;
                    objects_Geo(objIx).PixelListBorder = objects_EdgeMask(objIx).PixelList;
                    objects_Geo(objIx).PixelList       = objects_Orig(objIx).PixelList;
                end
            end
            
            function objects = ModifiedRegionProps(mask,Inx)
                objects = regionprops( mask, 'Centroid', 'PixelIdxList', 'PixelList', 'Area');     
                objects(1) = objects(Inx);
                objects(Inx) = [];                
            end
            
        end

        function objects = removeObjects_NotIn_ROI(objects)
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
    end
end

function output = creatingInitialMask(im , Input, UserInfo)

    disp('         Removing Land Area')
    im = removingLandArea(im , Input.Land);

    disp('         Detecting Clouds')
    [output.cloudMask, output.cloudMaskGray] = CloudMaskDetecter(im);

    disp('         Creating Empty Area Mask')
    output.EmptyAreaMask = emptyAreas(output.cloudMaskGray);    

    function im = removingLandArea(im , Land)
        for i = 1:3
            imm = im(:,:,i);
            imm(Land == 1) = 0;
            im(:,:,i) = imm;
        end
    end

    function [cloudMask,cloudMaskGray] = CloudMaskDetecter(im)
        cloudMask = im*0;
        for i = 1:3 
            
            if UserInfo.Method.Threshold == 1
                [counts,~] = imhist(im(:,:,i),256);
                th = otsuthresh(counts);
            elseif UserInfo.Method.Threshold == 2
                th2 = multithresh(im(:,:,i),3);
                th = th2(2);
            end

            % th2 = graythresh(im(:,:,i));
            cloudMask(:,:,i) = im(:,:,i) > th;
        end
        cloudMaskGray = [sum(cloudMask,3) == 3];

        if UserInfo.WriteImage.CloudMask.Flag
            imwrite(cloudMaskGray, [UserInfo.Directory.Output , UserInfo.name, UserInfo.WriteImage.CloudMask.Tag , '.jpg'])
        end

    end

    function EmptyAreaMask = emptyAreas(cloudMask)

        EmptyAreaMask = 1 - cloudMask;
        EmptyAreaMask(Input.Land == 1) = 0;

        EmptyAreaMask = EmptyAreaMask > 0;

        if UserInfo.WriteImage.EmptyAreaMask.Flag
            imwrite(EmptyAreaMask, [UserInfo.Directory.Output , UserInfo.name, UserInfo.WriteImage.EmptyAreaMask.Tag, '.jpg'])
        end
        
        if UserInfo.Overlay.ApplyROI_To_CloudOrFinalObjects == 1
            EmptyAreaMask(Input.ROI == 0) = 0;
        end        

    end

end
