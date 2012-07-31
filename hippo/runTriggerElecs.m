function [vInterp r t vVel velInterp] = runTriggerElecs(pos,v,Xf,thresh)
warning off all;
bounds = [.1 .9];
accumbins = 50;timeBins = [-100:400];
pos(pos == -1) = nan;
if size(v,1) < size(pos,1)
    pos = pos(1:size(v,1),:);
end
for i = 1:4
    nanInds = find(~isnan(pos(:,i)));
    pos(:,i) = interp1(nanInds,pos(nanInds,i),1:size(pos,1));
end
nanInds = isnan(pos(:,1));
pos = pos(~nanInds,:);v = v(~nanInds,:);Xf = Xf(:,~nanInds);%sp = sp(:,~nanInds);
vel = angVel(pos);
vel = filtLow(vel(:,1),1250/32,1);
nanInds = find(~isnan(vel));
vel = interp1(nanInds,vel(nanInds),1:numel(vel));
pos = bsxfun(@minus,pos,mean(pos));%pos = bsxfun(@rdivide,pos,std(pos));
[a,~,~] = svd(pos(:,1:2),'econ');pos = a;
pos(:,1) = pos(:,1)-min(pos(:,1));pos(:,1) = pos(:,1)/max(pos(:,1));
b = nan*ones(size(pos,1),1);
b(pos(:,1) < bounds(1)) = -1;b(pos(:,1) > bounds(2)) = 1;
nanInds = find(~isnan(b));
b = interp1(nanInds,b(nanInds),1:size(pos,1));
b = [0 diff(b)];
%v(:,2) = v(:,2).*conj(v(:,1))./abs(v(:,1));
offSet = 1;
%v(:,1) = [zeros(offSet,1); v(1+offSet:end,1).*conj(v(1:end-offSet,1))./abs(v(1:end-offSet,1))];
Xf = [bsxfun(@times,Xf,exp(1i*angle(v(:,1))).');
    [zeros(offSet,1); v(1+offSet:end,1).*conj(v(1:end-offSet,1))./abs(v(1:end-offSet,1))].'];
Xf = [real(Xf);imag(Xf)];%[abs(Xf); angle(Xf)];
Xf = zscore(Xf,0,2);
% r = runica(Xf(:,b~=0),'pca',50);
% Xf = r*Xf;
%%v = filtLow(v.',1250/32,1).';
%figure;plot(vel/max(vel));drawnow;
vel = [0 vel];
%Xf = filtLow(Xf,1250/32,2);
%Xf1 = zeros(50,size(Xf,2));theseCoords = b ~= 0 & vel/max(vel) > .1;
% [r,~,Xf2] = svds(zscore(Xf(:,theseCoords),0,2),50);
% Xf1(:,theseCoords) = Xf2.';
%[r,~,Xf1(:,theseCoords)] = runica(zscore(Xf(:,theseCoords),0,2),'pca',50);
%Xf = Xf1;
runs = bwlabel(b > 0);
vInterp = zeros(2,size(Xf,1),max(runs),accumbins);
velInterp = zeros(2,max(runs),accumbins);
%velTrace = zeros(2,max(runs),range(timeBins)+1);
%vVel = zeros(2,size(Xf,1),max(runs),range(timeBins)+1);
bins = (bounds(1))+((1:accumbins)-.5)/accumbins*(diff(bounds));
for k = 1:2
    runs = bwlabel(b*((-1)^k)>0);
for i = 1:max(runs)
    inds = find(runs == i);inds = min(inds):max(inds);
    indsa = min(inds)-100:max(inds);
    start = find(vel(indsa) > thresh,1);
    start = max(min(indsa)+start-1,-min(timeBins)+1);
%    velTrace(k,i,:) = vel(start+timeBins);
    inds(vel(inds) < .1) = [];
    for j = 1:size(Xf,1)
%        vVel(k,j,i,:) = Xf(j,start+timeBins);
        %vInterp(k,j,i,:) = csaps(pos(inds,1),Xf(j,inds),1-1e-7,bins);
        vInterp(k,j,i,:) = accumarray(max(1,min(accumbins,floor((pos(inds,1)-bounds(1))/(bounds(2)-bounds(1))*accumbins)+1))...
            ,Xf(j,inds),[accumbins 1],@mean);
    end
%    velInterp(k,i,:) = csaps(pos(inds,1),vel(inds),1-1e-7,bins);
end
end
% %b1 = [squeeze(b(1,:,:)) ];
b1 = [squeeze(vInterp(1,:,:)) squeeze(vInterp(2,:,:))]; %b(2,:,:) weird cuz of spline
%xdim = ceil(sqrt(size(b1,1)));ydim = ceil(size(b1,1)/xdim);
% figure;subplot(1,2,1);imagesc(complexIm(reshape(b1(1,:),[max(runs) 2*accumbins]),0,1));
% subplot(1,2,2);imagesc(complexIm(reshape(b1(1,:),[max(runs) 2*accumbins]),1,1));
% figure;for i = 1:size(b1,1)
%     subplot(xdim,ydim,i);imagesc(complexIm(reshape(b1(i,:),[max(runs) 2*accumbins]),0,1));axis off;
% end
%figure;for i = 1:size(b1,1)
%     subplot(xdim,ydim,i);imagesc(abs(reshape(b1(i,:),[max(runs) 2*accumbins])));axis off;
%end
[r,~,t] = runica(zscore(b1,0,2),'pca',49);%[r,~,~,~,~,~,t]
xdim = ceil(sqrt(size(t,1)));ydim = ceil(size(t,1)/xdim);
figure;for i = 1:size(t,1)
subplot(xdim,ydim,i);imagesc(real(reshape(t(i,:),[max(runs) 2*accumbins])));axis off;
end