function [XfposHat,XfvelHat] = decodePosVel(Xf,pos,v)%,dec)
%%compare velocity vs. position decoding of LFP activity

nbins = 100;
basis.n = 40;
basis.s = 70;
% Positions to use for decoding...
pvec = linspace(0,pi,nbins); % track length is mapped 0-2*pi for von-mises/fourier bases
[~,dbasis] = get1Dbasis('vonmises',basis.n,pvec,basis.s);
%Xf = Xf(inds,:);
pos = pos(1:size(Xf,2),:);%
%vel = angVel(pos);
%vel = filtLow(vel(:,1),1250/32,1);vel = vel/max(vel);
[~,pos,thresh,~] = fixPos(pos);
%vel = angVel(vel);
pos(pos > 1) = 3-pos(pos > 1);
pos = pos*pi;
vel = circ_diff(exp(1i*pos));
vel(abs(zscore(vel)) > 2) = 0;
vel = [0 vel];
vel = toeplitz(zeros(basis.n*2,1),vel);
vel = circshift(vel,[0 -size(vel,1)/2]);
if ~exist('v','var')
    [u,s] = eig(Xf(:,thresh)*Xf(:,thresh)');
    s = abs(s);
    u = bsxfun(@times,u,exp(-1i*angle(mean(u))));
    v = (u(:,1)\Xf)';
end
Xf = bsxfun(@times,Xf,exp(1i*angle(v.')));
% if dec > 1
%     for j = 1:size(Xf,1)
%         Xfd(j,:) = decimate(Xf(j,:),dec);
%     end
%     Xf = Xfd;clear Xfd;
%     vel = decimate(vel,dec);
%     pos = angle(-decimate(exp(1i*pos),dec))+pi;
%     thresh = logical(round(decimate(double(thresh),dec)));
% end
rn = randperm(sum(thresh));
f = find(thresh);
cut = floor(numel(f)/2);
trInds = f(rn(1:cut));
teInds = f(rn(cut+1:end));
%trInds = thresh;%(rn(1:floor(sum(thresh)/2)));
%teInds = thresh;%(rn(ceil(sum(thresh)/2):end));
[~,yRbf] = get1Dbasis('vonmises',basis.n,pos,basis.s);
yRbf = yRbf';
W = Xf/yRbf;
XfposHat = (Xf/yRbf)*yRbf;
XfvelHat = (Xf/vel)*vel;
%XfOr = (u*sqrt(s))\Xf;
%XfOr = bsxfun(@minus,XfOr,mean(XfOr,2));
%for i = 1:size(Xf,1)
%    r = 1:size(Xf,1);%randperm(size(XfOr,1));
%Xf = [real(XfOr(r(1:i),:));imag(XfOr(r(1:i),:))];
%Xf = Xf.';
%W = (Xf(trInds,:)'*Xf(trInds,:) + eye(size(Xf,2))/1000)\(Xf(trInds,:)'*yRbf(trInds,:));
%yhat = Xf*(W*dbasis');
%yhat = bsxfun(@rdivide,yhat,sqrt(mean(abs(yhat(teInds,:))).^2));
%[~,maxpost]=max(abs(yhat)');
%err = circ_dist(pos(teInds),maxpost(teInds)'/size(yhat,2)*2*pi);
%m(i) = median(abs(err));
%end