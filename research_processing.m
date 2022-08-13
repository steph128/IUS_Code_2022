images = cell(length_new,1); %length_new is number of images 
for i = 1:length(images)
    frame_nos =frames_import(i)
    images{i} = imread(sprintf(link,frame_nos)) % link is where images are 
end

for frame = 1:length(images)
    image = images{frame}
    smoothed_image = imadjust(image,[0.2 0.8],[0 1])
    smoothed_image2 = imguidedfilter(smoothed_image,'NeighborhoodSize',[40,40])
    [pixelCountsmooth, grayLevelssmooth] = imhist(smoothed_image2);
    thresholdValue = 80
    binaryImage = smoothed_image2>thresholdValue 
    se = strel('disk',2);
    disk = imerode(binaryImage,se)
    se = strel('disk',1);
    disk2 = imdilate(disk,se)
    filled = imfill(disk2,'holes')
    holes = filled & ~disk2
    bigholes = bwareaopen(holes,90);
    smallholes = holes & ~bigholes;
    final = disk2 | smallholes;
    imwrite(final,sprintf('Proc %d.png', frame))
end

figure; imshowpair(image,final,'montage');

