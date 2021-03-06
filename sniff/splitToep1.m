function [ cc mse kern filtSig y] = splitToep1(y,x,lags,bin,numCross,subSet,offSet,ridge)

fs = 1000/bin;
warning off all;
if ~exist('offSet','var') || isempty(offSet)
    offSet = 0;
end
if ~exist('subSet','var') || isempty(subSet)
    subSet = max(size(y));
end
if offSet > 0
    y = y(:,(1:subSet));
    x = x(:,offSet+(1:subSet));
else
    y = y(:,-offSet+(1:subSet));
    x = x(:,1:subSet);
end
win = [.5 .2];params.tapers = [12 win(1) 1];
y = bsxfun(@rdivide,y,std(y,0,2));%max(.01,std(y,0,2)));
x = bsxfun(@rdivide,x,std(x,0,2));
%for i = 1:size(y,1)
%    y(i,:) = y(i,:)/max(.01,std(y(i,:)));
%end
%newIdx = sum(abs(y),1) > 0;

numX = size(x,1);
xx = zeros(size(x,2),lags*size(x,1));
warning off all;
for i = 1:size(x,1)
%    x(i,:) = x(i,:)/std(x(i,:));
    xx(:,(i-1)*lags+(1:lags)) = fliplr(toeplitz(x(i,:),zeros(lags,1)));
end
if ~exist('ridge','var')
    ridge = 1;
end

xx = xx(lags:end,:);
y = y(:,lags:end);
%newIdx= newIdx(lags:end);newIdx = logical(newIdx);
%xx = xx(newIdx,:);
%y = y(:,newIdx);
[cc mse kern] = pipeLine(y,xx,numCross,ridge,fs,numX);
if numCross > 1
    kern = squeeze(mean(kern));
else
    kern = squeeze(kern);
end
if size(xx,2) ~= size(kern,1) kern = kern.'; end
filtSig = xx*kern;%kern*xx';%
kern = reshape(kern,[lags numel(kern)/lags]);
return
kern = squeeze(mean(kern,1));if size(kern,1) == 1 kern = kern';end
params.Fs = 1000/bin;params.fpass = [0 20];
[S0 f0] = mtspectrumc(y(~newIdx),params);
xx = xx(newIdx,:);
y = y(:,newIdx);
[S1 f1]= mtspectrumc(y,params);
[S1 f1]= mtspectrumc(y,params);
figure;hold all;plot(f1,S1/max(S1));plot(f0,S0/max(S0));%plot(f,S/max(S));
%kTemp = sin(linspace(0,8*pi,size(xx,2)));
%y = xx * kTemp';y = (y+randn(size(y))/1)'; 
% [~,kern1,snr1] = pipeLine(y,xx,numCross,ridge,fs,numX);
% kern1 = squeeze(mean(kern1,1));if size(kern1,1) == 1 kern1 = kern1';end
% [~,~,snr2] = pipeLine(y,xx,numCross,ridge,fs,numX,kern');
% figure;plot(snr1);hold all;plot(snr2);
filtSig = kern.'*xx';