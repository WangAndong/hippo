function [filts acts] = findPlacesNon(fields,thresh)
%fit place fields nonparametrically
warning off;
fields(:) = zscore(fields(:));
buffer = 24;%floor(size(fields,3)/2/10);
for i = 1:size(fields,1)
        filts{i} = [];acts{i} = [];
        tempFull = squeeze(fields(i,:,:));
        tempFull = [zeros(size(tempFull,1),buffer/2) tempFull zeros(size(tempFull,1),buffer/2)];
        tempFullF = filtfilt(gausswin(buffer/2),sum(gausswin(buffer/2)),tempFull')';
        tempF = mean(abs(tempFullF));
        [~,locs] = findpeaks(tempF,'minpeakheight',thresh,'minpeakdistance',buffer/2);
        subplot(221);hold off;imagesc(complexIm(tempFull));hold all;scatter(locs,ones(numel(locs),1)*size(tempFull,2)/2,'w','filled');drawnow;
        if numel(locs)
            wein = zeros(numel(locs),buffer+1);
            tempM = mean(tempFull);
            for k = 1:numel(locs)
                wein(k,:) = tempM(locs(k)+(-buffer/2:buffer/2));
            end
            for m = 1:3
                if min(size(wein)) == 1
                    wein = reshape(wein,[ buffer+1 numel(locs)]).';
                    for k = 1:size(wein,1)
                        mx = round(sum((1:size(wein,2)).*abs(wein(k,:)))/sum(abs(wein(k,:))));%max(abs(wein(k,:)));
                        wein(k,:) = circshift(wein(k,:),[0 buffer/2+1-mx]);
                    end
                end
                wein = bsxfun(@rdivide,wein,sqrt(sum(abs(wein).^2,2)));
                weinOld = wein;
                toepReg = zeros(numel(locs)*(buffer+1),numel(tempFull));
                for k = 1:numel(locs)
                    multReg = zeros(size(tempFull,1),size(tempFull,2));
                    inds = locs(k)+(-buffer/4:buffer/4);
                    mxInds = zeros(size(tempFull,1),1);absInds = mxInds;compInds = mxInds;
                    for l = 1:size(tempFull,1)
                        tmp = circshift(conv(conj(fliplr(wein(k,:))),tempFull(l,:),'full'),[0 -buffer/2]);
                        tmp(~ismember(1:numel(tmp),inds)) = 0;
                        [absInds(l),mxInds(l)] = max(abs(tmp));
                        if absInds(l) > thresh && mxInds(l) ~= min(inds) && mxInds(l) ~= max(inds)
                            multReg(l,max(1,mxInds(l))) = tmp(mxInds(l));
                            compInds(l) = tmp(mxInds(l));
                        else
                            mxInds(l) = nan;
                        end
                    end
                    acts{i}(k,:,:) = [mxInds-buffer/2 compInds];
                    subplot(221);hold all;scatter(mxInds,1:size(tempFull,1),m*5,'g','filled');
                    multReg = circshift(multReg,[0 -buffer/2]).';
                    toepReg((k-1)*(buffer+1) + (1:buffer+1),:) = toeplitz(multReg(:),zeros(1,buffer+1)).';
                end
                tempFull1 = tempFull.';
                %wein = (toepReg*toepReg' + lambda*eye((buffer+1)*numel(locs)))\conj(toepReg)*tempFull1(:);
                [wein,weinInt] = regress(tempFull1(:),toepReg.');%
                weinInt = diff(weinInt.').'/2;
                sig = (abs(wein).^2)./(abs(weinInt).^2);
                wein(sig < 1) = 0;
                weinOld = weinOld.';
                oldIm = reshape(weinOld(:).'*toepReg,size(tempFull1));
                newIm = reshape(wein.'*toepReg,size(tempFull1));
                [norm(tempFull1(:)-oldIm(:)) norm(tempFull1(:)-newIm(:))]
            end
            filts{i} = reshape(wein,[buffer+1 numel(locs)]);
            subplot(224);sPlot(filts{i}.',[],0);%[t complex(abs(t),angle(t)/6)],[],0);
            subplot(223);imagesc(complexIm(newIm.'));
            subplot(222);imagesc(complexIm((tempFull1-newIm).'));drawnow;pause(1);
        else
            pause(1);
        end
end