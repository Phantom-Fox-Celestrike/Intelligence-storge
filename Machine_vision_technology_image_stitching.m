%% 全景图拼接代码
% 选择图片文件夹
folderName = uigetdir('选择包含图片的文件夹');
imageFiles = dir(fullfile(folderName, '*.jpg')); % 支持JPG格式

% 读取并显示所有图片
images = cell(length(imageFiles), 1);
grayImages = cell(length(imageFiles), 1); % 用于存储灰度图像
for i = 1:length(imageFiles)
    images{i} = imread(fullfile(folderName, imageFiles(i).name));
    grayImages{i} = rgb2gray(images{i}); % 转换为灰度图像
    imshow(images{i});
    title(['图片 ', imageFiles(i).name]);
    pause(1);
end

% 特征匹配和图像拼接
if length(images) >= 2
    % 使用SIFT特征进行匹配和拼接
    points1 = detectSURFFeatures(grayImages{1}); % 使用灰度图像进行特征检测
    points2 = detectSURFFeatures(grayImages{2});
    [features1, valid_points1] = extractFeatures(grayImages{1}, points1); % 使用灰度图像进行特征提取
    [features2, valid_points2] = extractFeatures(grayImages{2}, points2);
    index_pairs = matchFeatures(features1, features2);
    matchedPoints1 = valid_points1(index_pairs(:,1), :);
    matchedPoints2 = valid_points2(index_pairs(:,2), :);
    
    % 估计几何变换
    tform = estimateGeometricTransform(matchedPoints2, matchedPoints1, 'affine');
    outputView = imref2d(size(images{1}));
    warpedImage = imwarp(images{2}, tform, 'OutputView', outputView);
    
    % 图像融合
    blendedImage = imfuse(images{1}, warpedImage, 'blend');
    imshow(blendedImage);
    title('全景图拼接结果');
else
    disp('文件夹中图片不足，无法进行拼接');
end


%% 目标识别代码
% 选择包含目标的图片文件夹
targetFolder = uigetdir('选择目标图片文件夹');
if targetFolder == 0
    error('未选择文件夹，程序终止');
end

% 获取文件夹中的所有图片
targetFiles = dir(fullfile(targetFolder, '*.jpg')); % 支持JPG格式
if isempty(targetFiles)
    error('文件夹中没有找到JPG格式的图片，程序终止');
end

% 目标识别示例（这里使用简单模板匹配）
if ~isempty(targetFiles)
    templateImage = imread('D1.jpg'); % 替换为你的目标模板
    templateImage = rgb2gray(templateImage); % 将模板图像转换为灰度图像
    [hT, wT] = size(templateImage);
    
    for i = 1:length(targetFiles)
        targetImg = imread(fullfile(targetFolder, targetFiles(i).name));
        grayTargetImg = rgb2gray(targetImg); % 将目标图像转换为灰度图像
        [h, w] = size(grayTargetImg);
        
        % 使用归一化互相关进行模板匹配
        correlation = normxcorr2(templateImage, grayTargetImg, 'same');
        [max_corr, ~] = max(correlation(:));
        [y, x] = find(correlation == max_corr);
        
        if ~isempty(x) && ~isempty(y)
            x = x(1); y = y(1);
            % 绘制边界框
            rectangle('Position', [x - wT/2, y - hT/2, wT, hT], 'EdgeColor', 'r', 'LineWidth', 2);
            text(x, y, '目标检测', 'Color', 'r', 'FontSize', 14);
        end
        imshow(targetImg);
        title(['目标识别结果: ', targetFiles(i).name]);
        pause(1);
    end
end