function extractObjects(Dir,ActualArea)

    ListImages = func_listImages(Dir);
    
%     f = figure; 
%     uip = uipanel ( 'parent', f, 'position', [0.2 0.2 0.4 0.4] ); 
%     h = cProgress ( 0, 'Embedded', 'parent', uip, 'outerColor', [0 0 1] ); 

%     % p = ProgressBar( length(ListImages),'verbose',1 ); % 
    for ind = 1:length(ListImages)
        
        disp(['ind: ',num2str(ind),'/',num2str(length(ListImages))])
        name = strsplit(ListImages(ind).name,'.jpg'); name = name{1};

        imm = imread([Dir , name, '.jpg']);
        mask = imread([Dir , name, '_mask_Pattern.jpg']) > 100;
        
        [imm2, imObjects_WithInfo, imObjects] = Apply_Detection(imm, mask,ActualArea);                       
        
        imwrite(imm2, [Dir , name, '_processed.jpg'])
        imwrite(imObjects, [Dir , name, '_Objects.jpg'])
        imwrite(imObjects_WithInfo, [Dir , name, '_Objects_wInfo.jpg'])
        
%         strg = ['ind: ',num2str(ind),'/',num2str(length(ListImages))];
%         cProgress ( ind, h , strg) 
%         % p.progress;
    end
%     % p.stop;
%     delete ( h ); 
end

function ListImages = func_listImages(Dir)

    List = dir(Dir);
    ListImages = [];
    for ls = 1:length(List)
        if ~contains(List(ls).name, '_processed') &&  ~contains(List(ls).name, 'mask') && contains(List(ls).name, 'jpg') && contains(List(ls).name, 'goes') && ~contains(List(ls).name,'Objects')
           ListImages = [ListImages,List(ls)];
        end
    end

end

function [imm2, imObjects_WithInfo, imObjects] = Apply_Detection(imm, mask,ActualArea)

    mask2 = imclose(mask,strel('disk',2));
    mask2 = imopen(mask2,strel('disk',4));
    %%
    obj = regionprops(mask2,'PixelIdxList','Area','Centroid','BoundingBox');
    Area1 = cat(1,obj.Area);
    obj2 = obj(Area1 > 200 & Area1 < 1e5);
    Centroid = cat(1,obj2.Centroid);
    Area = cat(1,obj2.Area);
    %%
%     N = 256/length(obj2);
%     maskColoredB = mask2*0;
%     for oIx = 1:length(obj2)
%         maskColoredB(cat(1,obj2(oIx).PixelIdxList)) = int8(N*oIx);
%     end
    
    maskColored = mask2*0;
    maskColored(cat(1,obj2.PixelIdxList)) = 1;

    %%
%     imFinal2 = label2rgb(maskColoredB,'spring','c');
%     background = backgroundDetector(maskColored);
%     imFinal2(background == 1) = 0;
    
%     CC = bwconncomp(mask2);
%     L = labelmatrix(CC);
    edgeImage = edge(maskColored);
    imm2 = imm;
    imm2(:,:,1) = imm(:,:,1) + 255*uint8(edgeImage);
    imm2(:,:,2) = imm(:,:,2) + 248*uint8(edgeImage);
    
    L = bwlabel(maskColored);
    imObjects = label2rgb(L);

    if ~isempty(Centroid)
        objectArea = Area*0;
        for oIx=1:length(obj2)
            objectArea(oIx) = round(sum(ActualArea(cat(1,obj2(oIx).PixelIdxList))));
        end
        imObjects_WithInfo = insertMarker(imObjects,Centroid,'x','Color','black');
        imObjects_WithInfo = insertText(imObjects_WithInfo,Centroid,objectArea,'TextColor','black','BoxOpacity',0);
        
        imm2 = insertMarker(imm2,Centroid,'x','Color','yellow');
        imm2 = insertText(imm2,Centroid,objectArea,'TextColor','yellow','BoxOpacity',0,'FontSize',20);        
    else
        imObjects_WithInfo = imObjects;
        imm2 = imm;
    end
    
end

function background = backgroundDetector(mask)

    background = mask*0;
    background(mask ==0) = 1;
    background = cat(3,background,background,background);
end