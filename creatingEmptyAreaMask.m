function output = creatingEmptyAreaMask(im , Input, UserInfo)

    disp('         Normalizing the Image')
    im = normalizing(im);

    disp('         Removing Land Area')
    im = removingLandArea(im , Input.Land);

    disp('         Detecting Clouds')
    [output.cloudMask, output.cloudMaskGray] = CloudMaskDetecter(im, UserInfo);

    disp('         Creating Empty Area Mask')
    output.EmptyAreaMask = emptyAreas(output.cloudMaskGray,Input.Land, UserInfo);
    
    if UserInfo.Overlay.ApplyROI_To_CloudOrFinalObjects == 1
        output.EmptyAreaMask(Input.ROI == 0) = 0;
    end

end

function im = removingLandArea(im , Land)
    for i = 1:3
        imm = im(:,:,i);
        imm(Land == 1) = 0;
        im(:,:,i) = imm;
    end
end

function im = normalizing(im)
    im = im2double(im);
    im = (im - min(im(:))) / (max(im(:)) - min(im(:)));
end

function [cloudMask,cloudMaskGray] = CloudMaskDetecter(im, UserInfo)
    cloudMask = im*0;
    for i = 1:3 
        [counts,x] = imhist(im(:,:,i),256);
        th = otsuthresh(counts);

        % th2 = graythresh(im(:,:,i));
        cloudMask(:,:,i) = im(:,:,i) > th;
    end
    cloudMaskGray = [sum(cloudMask,3) == 3];
    
    if UserInfo.WriteImage.CloudMask.Flag
        imwrite(cloudMaskGray, [UserInfo.Directory.Output , UserInfo.name, UserInfo.WriteImage.CloudMask.Tag , '.jpg'])
    end
        
end

function EmptyAreaMask = emptyAreas(cloudMask,land, UserInfo)

    EmptyAreaMask = 1 - cloudMask;
    EmptyAreaMask(land == 1) = 0;
    
    EmptyAreaMask = EmptyAreaMask > 0;
    
    if UserInfo.WriteImage.EmptyAreaMask.Flag
        imwrite(EmptyAreaMask, [UserInfo.Directory.Output , UserInfo.name, UserInfo.WriteImage.EmptyAreaMask.Tag, '.jpg'])
    end

end