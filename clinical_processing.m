% [V_2_rest,map] = dicomread('C:\Users\szest\iCloudDrive\Imperial 2021-2022\Individual Project\All Datasets\2022 HFR002\Clinical\Clinical_20220513_115109_HFR002_VERASONICS_CONTRAST_REALTIME_IM_0012.avi')
% V_2_rest_proc = squeeze(V_2_rest(150:500,200:600,1,:));
% figure;montage(V_2_rest_proc, map, 'Size', [10 15]);title('2 rest RT')%143 frames

V= VideoReader('C:\Users\szest\iCloudDrive\Imperial 2021-2022\Individual Project\All Datasets\2022 HFR002\Clinical\Clinical_20220513_115109_HFR002_VERASONICS_CONTRAST_REALTIME_IM_0012.avi')
no_frames = V.NumFrames
images = cell(1,no_frames)
k=1
while hasFrame(V)
   images{k} = readFrame(V);
   k=k+1
end
V_2_rest_proc = cell(1,no_frames)
for i=1:no_frames
    V_2_rest_proc{i} = squeeze(images{i}(150:500,200:600,1,:));
end

for frame = 1:no_frames
    image = V_2_rest_proc{frame}
    imwrite(image,sprintf('Frame %d.png', frame))
end

% upload images
first_frame = 1
last_frame = 284
length = last_frame-first_frame;
images = cell(length,1);
for k = first_frame: last_frame 
    images{k} = imread(sprintf('C:/Users/szest/iCloudDrive/Imperial 2021-2022/Individual Project/Final_Datasets/Clinical_Datasets/new/0012/Frame %d.png', k))
end

%Clinical Processing 
for frame = first_frame:last_frame
    image = images{frame}
    smoothed_image = imadjust(image,[0.8 0.95],[0 1])
    smoothed_image2 = imguidedfilter(smoothed_image,'NeighborhoodSize',[40,40])
    [pixelCountsmooth, grayLevelssmooth] = imhist(smoothed_image2);
    value =100
    index = find(pixelCountsmooth(value:end)>111,3)
    thresholdValue = grayLevelssmooth(median(index)+value)
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


