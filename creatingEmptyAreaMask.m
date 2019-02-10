function [cloudMask, cloudMaskGray, EmptyAreaMask] = creatingEmptyAreaMask(im , Land)

% Land = imread([Dir , 'code/referenceImages/LandMask_from_LatLong.jpg']) > 100;
% List = func_listImages([Dir , '/images']);
% 
% for ind = 1:length(List)
%     disp(List(ind).name)
%     im = imread([List(ind).folder , '/' , List(ind).name]);

im = normalizing(im);
im = removingLandArea(im , Land);
[cloudMask,cloudMaskGray] = CloudMaskDetecter(im);
EmptyAreaMask = emptyAreas(cloudMaskGray,Land);


% end

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

function [cloudMask,cloudMaskGray] = CloudMaskDetecter(im)
    cloudMask = im*0;
    for i = 1:3 
        [counts,x] = imhist(im(:,:,i),256);
        th = otsuthresh(counts);

        % th2 = graythresh(im(:,:,i));
        cloudMask(:,:,i) = im(:,:,i) > th;
    end
    cloudMaskGray = [sum(cloudMask,3) == 3];
end

function msk = emptyAreas(cloudMask,land)
    msk = 1 - cloudMask;
    msk(land == 1) = 0;
end