function ListImages = func_listImages(Dir)

    List = dir(Dir);
    ListImages = [];
    for ls = 1:length(List)
        if ~contains(List(ls).name, '_PP_') && contains(List(ls).name, 'jpg') && contains(List(ls).name, 'goes') 
           ListImages = [ListImages,List(ls)];
        end
    end

end