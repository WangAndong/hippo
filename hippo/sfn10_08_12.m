%% panel 3 - Demodulation demo
nSteps = 1000;
x = linspace(0,20*pi,nSteps);
y = exp(1i*x);
A = [zeros(200,1); ones(300,1); zeros(500,1)]/2+1;
win = 20;
A = filtfilt(gausswin(win),sum(gausswin(win)),A);
dP = [zeros(600,1); ones(300,1); zeros(100,1)]*-pi/2;
dP = filtfilt(gausswin(win),sum(gausswin(win)),dP);
z = A'.*exp(1i*(x+dP'));zd = -conj((z.*conj(y))*1i);
angCol = colormap('hsv');
c = ceil((angle(z)+pi)/(2*pi)*64);
figure;plot3(1:nSteps,real(y),imag(y),'k');
hold all;scatter3(1:nSteps,real(z),imag(z),[],bsxfun(@times,angCol(c,:),(A/max(A))),'filled');
sh = 4;
plot3(1:nSteps,real(y),imag(y)-sh,'k');
c = max(1,ceil((angle(zd)+pi)/(2*pi)*64));
hold all;scatter3(1:nSteps,real(zd),imag(zd)-sh,[],bsxfun(@times,angCol(c,:),(A/max(A))),'filled');
set(gca,'xtick',[],'ytick',[],'ztick',[],'linewidth',2);
%% panel 4/5
inds = 52965:53140;angCol = colormap('hsv');
%temp = filtLow(angVel(pos)',1250/32,2);
[posa,s,u] = svds(pos(:,1:2),1);
posa = s*posa;
temp = filtLow(diff(posa(inds)),1250/32,2);
indsa = inds(1)*4:inds(end)*4;
X1 = morFilter(X(:,indsa(1)-1000:indsa(end)+1000),8,1250/8);X1 = X1(:,1001:end-1000);
[u,s,v1] = svds(X1,1);
um = mean(abs(u)).*exp(1i*circ_mean(angle(u)));
v2 = um*s*v1';
%% panel 4
sub = 100:285;mA = max(max(abs(X1(:,sub))));
v1c = mean(abs(v2(sub)))*exp(1i*angle(v2(sub)));
figure;plot3((sub-min(sub))/1250*8,real(v1c),imag(v1c),'k');hold all;
sh = s/50;
plot3((sub-min(sub))/1250*8,real(v1c),imag(v1c)-sh,'k');hold all;
%X1d = bsxfun(@times,X1(:,sub),exp(1i*(-angle(v1c))));
X1d = exp(1i*angle(conj(u*s*v1(sub)'))).*X1(:,sub);
X1d = abs(X1d).*exp(1i*(angle(X1d) + pi/2));
for i = 1:size(X1,1)
    c = ceil((angle(X1(i,sub))+pi)/(2*pi)*64);
    scatter3((sub-min(sub))/1250*8,real(X1(i,sub)),imag(X1(i,sub)),[],bsxfun(@times,angCol(c,:),abs(X1(i,sub)')/mA),'filled');
    c = min(64,max(1,ceil((angle(X1d(i,:))+pi)/(2*pi)*64)));
    scatter3((sub-min(sub))/1250*8,real(X1d(i,:)),imag(X1d(i,:))-sh,[],bsxfun(@times,angCol(c,:),abs(X1(i,sub)')/mA),'filled');
end
%% panel 5
figure;subplot(411);plot(temp*1250/32,'k','linewidth',2);axis tight;
colorbar;set(gca,'xtick',[],'fontsize',16);title('Velocity');ylabel('cm/s');
subplot(412);imagesc(X(:,indsa));set(gca,'ytick',[1 64],'xtick',[],'fontsize',16);colormap jet;colorbar;freezeColors;title('Raw LFP');
subplot(413);imagesc(complexIm(X1,0,1));colorbar;set(gca,'ytick',[1 64],'xtick',[],'fontsize',16);ylabel('Channel #');title('Filtered Theta');
subplot(414);imagesc(linspace(0,size(X1,2)/1250*8,size(X1,2)),1:64,...bsxfun(@times,X1,exp(1i*angle(v1)'))
    complexIm(X1.*exp(1i*-angle(u*v1')),0,2,16));colorbar;set(gca,'ytick',[1 64],'xtick',1:4,'fontsize',16);...
    colormap hsv; freezeColors;title('Demodulated Theta');xlabel('Time (s)');

figure;subplot(4,1,2);imagesc(complexIm(v2,0,1));colorbar;axis off;
c = ceil(mod(angle(v2),2*pi)/(2*pi)*64);%(angle(v2*1i)+pi)
subplot(4,1,3);scatter(1:numel(v2),real(v2),[],angCol(c,:),'filled');
set(gca,'color','w','xtick',[],'ytick',[]);axis tight; colorbar;
%% panel 6
offSet = 1;
Xf1 = [bsxfun(@times,Xf,exp(1i*angle(v(:,1))).');...
[zeros(offSet,1); v(1+offSet:end,1).*conj(v(1:end-offSet,1))./abs(v(1:end-offSet,1))].'];
Xf1 = [real(Xf1);imag(Xf1)];
Xf1 = zscore(Xf1,0,2);
t = conj(complex(W(p2,1:end/2),W(p2,end/2+1:end)))*complex(Xf1(1:65,:),Xf1(66:end,:));
%%
t = W(p2,:)*zscore(Xf1,0,2);
Wp = pinv(W);Wp = Wp(:,p2);
%%
[sp cellInfo] = hipSpikes('ec014.468',32/1.25);
spf = morFilter(sp,8,1250/32);clear sp;
s1 =  [35    17    19     7    26    27    60     6    33    39    50    54    18    67    21    31 14    36    46    44    40     1    56    59  24];
runTriggerViewSp(pos,v,spf(cellInfo == 1,:),[50 1],.05,s1(r(1:25)));
%% correlate high freq ICA and spiking
[sp cellInfo] = hipSpikes('ec014.468',32/1.25);
[A,tes,td] = allHighFreq('ec014.468.h5',1:8,pos,1);
tdf = morFilter(td,8,1250/32);
spf = morFilter(sp,8,1250/32);clear sp;
[~,~,teSp] = runTriggerViewSp(pos,v,spf(cellInfo >= 1,:),[50 1],.05);
[~,~,tes1] = runTriggerViewC(pos,v,tdf,[50 1],.05,eye(size(tdf,1)));
for i = 1:size(tes1,1)
    tes1f(i,:,:) = imfilter(squeeze(tes1(i,:,:)),fspecial('gaussian',5,1));
end
for i = 1:85
    teSpf(i,:,:) = imfilter(squeeze(teSp(i,:,:)),fspecial('gaussian',5,1));
end
ccf = abs(corr(tes1f(:,:)',teSpf(:,:)'));
figure;ccfa = ccf1;
for i = 1:18
[fx(i),fy(i)] = find(ccfa == max(ccfa(:)));
ccfa(fx(i),:) = 0;
ccfa(:,fy(i)) = 0;
subplot(6,6,2*i-1);imagesc(complexIm(imfilter(squeeze(tes1(fx(i),:,:)),fspecial('gaussian',5,1)),0,1));axis off;
subplot(6,6,2*i);imagesc(complexIm(imfilter(squeeze(teSp(fy(i),:,:)),fspecial('gaussian',5,1)),0,1));axis off;
end
%% compare different layers in 512-electrode data
ss = [];
for i =1:32
x = getData('AB3-58.h5',(i-1)*16+(1:16),1000000);
x = filtHigh(x,1250,100,8);
s = std(x,0,2);
ss = [ss s];
end
ss1 = ss(:);
probes1= probes(:,[1:12 14 13 16 15]);
for i = 1:size(probes,1)
for j = 1:size(probes,2)
ssa(i,j) = ss1(probes1(i,j)+1);
end
end
r = roipoly;
f = probes1(ssa < .11 & r)+1;
[A,W] = runTriggerICA(pos,v,Xf(f,:),.05);
r1 = roipoly;
f1 = probes1(ssa > .12 & r1)+1;
[A1,W1] = runTriggerICA(pos,v,Xf(f1,:),.05);
[A2,W2] = runTriggerICA(pos,v,Xf([f; f1],:),.05);
%% ica on anterior, posterior, and both shanks (AB3-58AP.mat)
[A2,W2,Z2] = runTriggerICA(pos,v,Xf(:,:),.05);
[A,W,Z] = runTriggerICA(pos,v,Xf(probes1(:) > 255,:),.05);
[A1,W1,Z1] = runTriggerICA(pos,v,Xf(probes1(:) <= 255,:),.05);
runTriggerViewC(pos,v,Xf(probes1(:) <= 255,:),[50 1],.05,W1);
runTriggerViewC(pos,v,Xf(probes1(:) > 255,:),[50 1],.05,W);