function lsmTif(inFile,outFile)

chunkSize = 200; %number of frames to retrieve at once, if too high memory problems, if too low slow
s = tiffread302(inFile,11); %file that retrieves image data from .lsm
numFrames = s(1).lsm.DimensionTime;
useInds{2} = sum(s(1).data{1}) > 0;
useInds{1} = sum(s(1).data{1},2) > 0;
tempIm = zeros(sum(useInds{1}),sum(useInds{2}),3); %get rid of black regions
%im = s(1).data{2}(useInds{1},useInds{2});
for i = 1:ceil(numFrames/chunkSize)
    s = getChunk(inFile,i,chunkSize);
    for j = 1:numel(s)
        for k = 2
            temp = s(j).data{k}(useInds{1},useInds{2});
            if 0
                temp = uint8(temp/(2^8));
            end
            imwrite(temp,[outFile num2str(3-k) num2str((i-1)*chunkSize + j,'%04d') '.tif']);
        end
    end
end

function s = getChunk(file,start,len)
s = tiffread302(file,(((start-1)*len+1):start*len)*2-1);