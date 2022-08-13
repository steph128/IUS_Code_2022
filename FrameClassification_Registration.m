%% load in processed and unprocessed images 
first_frame = 1
length_original = last_frame-first_frame+1;
images = cell(length_original,1);
unprocessed_images = cell(length_original,1);

for i = 1:length_original
    images_original{i} = imread(sprintf(data_img,i)) %data_img -> where processed images are
    unprocessed_images_original{i} = imread(sprintf(data_unprocimg,i)) %data_unprogcimg -> where processed images are
end

images = images_original
images(interval)=[]
unprocessed_images = unprocessed_images_original
unprocessed_images(interval)=[]

%% phase designation
% plot average intensity vs frame number 
intensity = [];
for k = 1:length(frame_no)
    intensity(k) = mean(images{k},'all');
end

figure; plot(intensity,'DisplayName','Average Intensity'); hold on; xlabel('Frame Number');ylabel('Average Intensity');xlim([0 length(images)]);legend('location','southeast');
hold on; 

order = 3;
framelen = 9;
sgf = sgolayfilt(intensity,order,framelen);
plot(sgf,'.-')
hold on; xlabel('Frame Number');ylabel('Average Pixel Intensity');xlim([0 length(images)])

% find first frame of each heartbeat
[troughs,trlocs] = findpeaks(-sgf,'MinPeakHeight',mean(-sgf),'MinPeakProminence',0.05);
trlocs = [1,trlocs]
trlocs(end+1) = length(sgf)
plot(frame_no(trlocs),sgf(trlocs),'*g');

hb_length = diff(trlocs)
mean_hb_length = mean(hb_length)
change_pts = cell(length(trlocs)-1,1)

% find heart phase frames - 4 per heartbeat
for i = 1:length(change_pts)
    no_change_pt = 4
    if hb_length(i)<mean_hb_length-2
        no_change_pt = ceil(no_change_pt*(hb_length(i)/mean_hb_length))
    end
    change_pts_temp = findchangepts(sgf(trlocs(i):trlocs(i+1)),'MaxNumChanges',no_change_pt,'Statistic',"std")
    change_pts{i} = change_pts_temp+trlocs(i)-1
end
change_pts = change_pts(~cellfun('isempty',change_pts))

[~,after_destruction] = min(intensity)
intervals = [1]
for i = 1:length(change_pts)
    intervals(end+1:end+length(change_pts{i,:})) = [change_pts{i,:}]
end
intervals(end+1) = after_destruction
intervals(end+1) = length(images)
intervals = sort(intervals)


% upload 5 manually segmented masks 
mask_link = append(mask_link,'%d.mat') %mask link is where the 5 manually segmented masks are 

lengths = []
for i =1:length(change_pts)
    lengths(i) = length(change_pts{i})
end
full_index_search = find(lengths==4,2)
if full_index_search(1) ==1
    full_index = full_index_search(2)
else
    full_index = full_index_search(1) 
end

masks_eval_no = []
masks_eval_no(1:4)=change_pts{full_index} %include first four heat phase points belonging to first heartbeat 
masks_eval_no(end+1) = after_destruction %include frame right after destruction 
masks_eval_no = sort(masks_eval_no)
manual_masks = cell(5,1)
for i=1:length(masks_eval_no)
    manual_masks{i}=load(sprintf(mask_link,masks_eval_no(i))).bw
end

manual_image = cell(5,1)
manual_image{1} = images{masks_eval_no(1)}
manual_image{2} = images{masks_eval_no(2)}
manual_image{3} = images{masks_eval_no(3)}
manual_image{4} = images{masks_eval_no(4)}
manual_image{5} = images{masks_eval_no(5)}

% identify image in manually segmented set most similar to each heart phase
% point (change point) 
dice_scores = cell(4,length(intervals))
for i=1:length(dice_scores)
    for j = 1:4
        dice_scores{j,i} = dice(images{intervals(i)},manual_image{j})
    end
end
[M,I] = max(cell2mat(dice_scores))
I(find(intervals==after_destruction(1))) = 5
I(find(intervals==after_destruction(1)+1)) = 5
I(find(intervals==after_destruction(1)+2)) = 5

ref_mask_all = []
times = diff(intervals)
for i=1:length(I)-1
    for j=1:times(i)
        ref_mask_all(end+1) = I(i)
    end
end
ref_mask_all(end+1) = ref_mask_all(end)


% diffeomorphic demons registration
Cs = cell(length(images),1)
Cs_unprocessed = cell(length(images),1)
seg_masks = cell(length(images),1)

for i=1:length(images)
    index_ref = ref_mask_all(i)
    ref_mask = manual_masks{index_ref}
    ref_image = manual_image{index_ref}
    deforming = images{i}
    deforming_unprocessed = unprocessed_images{i}
    [D,movingReg] = imregdemons(ref_image,deforming,[100],'PyramidLevels',5,...
        'AccumulatedFieldSmoothing',1);
    deformedmask = imwarp(ref_mask,D,'nearest')
    C = imfuse(deforming,deformedmask,'blend') 
    C_unprocessed = imfuse(deforming_unprocessed,deformedmask,'blend')
    Cs{i}= C
    Cs_unprocessed{i} = C_unprocessed 
    seg_masks{i}= deformedmask
    %figure; imagesc(C);  colormap('gray'); title(i)
end

