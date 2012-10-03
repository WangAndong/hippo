function [allX,samplePos,W,t] = runChunks(X,v,pos,act)

ratio = round(size(X,2)/size(pos,1));
dec = 32/ratio;

%%Processing of position information
thresh = .05;bounds = [.1 .9];win = [-1 1]*ceil(1250/dec/8/2);
pos(pos == -1) = nan;
reject = 0;
for i = 1:4
    reject = reject | min([0; diff(pos(:,i))],flipud([0; diff(flipud(pos(:,i)))])) < -20;
end
pos(reject,:) = nan;
for i = 1:4
    nanInds = find(~isnan(pos(:,i)));
    pos(:,i) = interp1(nanInds,pos(nanInds,i),1:size(pos,1));
end
nanInds = isnan(pos(:,1)) | isnan(pos(:,3));
vel = angVel(pos);vel = vel(:,1);
vel = [0; vel(:,1)];
pos = bsxfun(@minus,pos,nanmean(pos));
[~,~,c] = svd(pos(~nanInds,1:2),'econ');pos = (c\pos(:,1:2)')';%pos = a;pos(nanInds) = nan;
pos = pos(:,1);
for i = 1:size(pos,2)   
    pos(:,i) = pos(:,i) - min(pos(:,i));
    pos(:,i) = pos(:,i)/(max(pos(:,i)));
    pos(:,i) = min(pos(:,i),.9999);
end
pos(nanInds) = 0;
%%THE filtLow function requires some functions from the signal processing
%%toolbox, but is not particularly necessary.
vel = filtLow(vel,1250/32,1);
vel = vel/max(vel);
vel = resample(vel,ratio,1);pos = resample(pos,ratio,1);
act = resample(act',ratio,1)';act = [zeros(size(act,1),size(X,2)-size(act,2)) act];
pos = pos(1:size(X,2),:); vel = vel(1:size(X,2));
inds = vel > thresh;
b = nan*ones(size(pos,1),1);
b(pos(:,1) < bounds(1)) = -1;b(pos(:,1) > bounds(2)) = 1;
nanInds = find(~isnan(b));
b = interp1(nanInds,b(nanInds),1:size(pos,1));
b = [0 diff(b)];
runs = bwlabel(b > 0);
w = watershed(b==0);
w = w-1; %w(w== max(w)) = 0;
allX = zeros(size(X,1)*(range(win)+1),ceil(size(X,2)/range(win)/2));counter = 1;
samplePos = [];ys = zeros(size(act,1),size(allX,2));
for k = 1:2
%    runs1 = b*(-1^k)>0;runs1 = bwlabel(runs1);
    runs1 = bwlabel(w>0 & mod(w,2) == k-1 & w <=2*max(runs));%b*((-1)^k)>0);
%     for i = 1:max(runs1)
%         sPlot([X(:,runs1 == i);angle(v(runs1 == i)/50000); inds(runs1 == i)'],[],0);pause(1);
%     end
    for i = 1:max(runs1)
        runInds = find(runs1 == i);
        %aV = -angle(v(runInds));
        %[h,pk] = findpeaks(aV,'minpeakheight',pi*.8);
        aV = angle(-v(runInds)*exp(1i*5*pi/6));%*-pi/6)
        [~,pk] = findpeaks(-abs(aV),'minpeakheight',-.3);
        %h(~inds(runInds(pk))) = [];
        pk(~inds(runInds(pk))) = [];
        %plot(aV);hold all;
        %scatter(pk,h,'filled');
        %plot(vel (runInds));hold off;pause(.5);drawnow;
        pk = runInds(1)+pk-1;
        for j = 1:numel(pk)
            temp = X(:,pk(j)+(win(1):win(2)))';
            allX(:,counter) = temp(:);
            ys(:,counter) = mean(act(:,pk(j)+(win(1):win(2))),2);
            counter = counter + 1;
        end
        samplePos = [samplePos; [pos(pk) i*ones(numel(pk),1) pk']];
        %subplot(121);plot(-abs(aV));hold all;scatter(pk-runInds(1)+1,zeros(1,numel(pk)),'filled');hold off;title(i*10000+counter);drawnow;
        %subplot(122);plot(allX(:,max(1,counter-5):counter-1));drawnow;pause(.05);
    end
end
%[~,sortPos] = sort(samplePos,'ascend');
allX(:,counter:end) = [];ys(:,counter:end) = [];
figure;scatter(samplePos(:,1),samplePos(:,2),max(.1,ys(1,:)*50),'filled');
[ys ym] = remmean(ys);
[allX allXm] = remmean(allX);
[cc,~,W] = pipeLine(ys,allX',3,1);
mean(cc)
W = mean(W)';
%W = (allX*allX' + eye(size(allX,1))*lambda*1)\allX*ys';
yHat = W'*allX;
Wp = (yHat'\allX')';
figure;plot(ys(1,:));hold all;plot(yHat(1,:))
figure;
for i = 1:size(W,2)
    temp = reshape(Wp(:,i),[size(allX,1)/size(X,1) size(X,1)]);
    subplot(2,2,i);plot(temp);
    subplot(2,2,2+i);
    for j = 1:inf
    for k = 1:size(temp,1)
        imagesc(reshape(temp(k,:),[8 8]),[min(temp(:)) max(temp(:))]);pause(.05);drawnow;
    end
    end
end
return
imagesc(reshape(W',[size(W,2) size(allX,1)/size(X,1) size(X,1) ]));
figure;imagesc(allX);
figure;plot(reshape(mean(allX,2),[size(allX,1)/size(X,1) size(X,1)]));

figure;scatter(samplePos(:,1),samplePos(:,2),max(.1,ys*50),'filled');
drawnow;
if nargout > 2
[A,W] = gfastica(allX,'lastEig',size(allX,1),'g','tanh','approach','symm','stabilization','on');
t = W*remmean(allX);
%[u,s,v] = svds(allX,10);
%figure;imagesc(allX(:,sortPos));
end
Xm = reshape(mean(allX,2),[size(allX,1)/size(X,1) size(X,1)]);
figure;imagesc(Xm');
% figure;plot(Xm');