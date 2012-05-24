function runSim(spikes,asigs)%len)

p = 4;

numIter = 16;
figure;
angles = angle(asigs);
spikes = logical(spikes);
a = angles(spikes);
%for i = 1:numIter
%test = randn(len,1) + 1i*randn(len,1)*i;
%a = angle(test); a = mod(2*(a+pi),2*pi)-pi;
i = 1;%
[theta k(i)] = circ_vmpar(a);
g(i) = real(circ_gamma(a));
%subplot(4,4,i);
plot(-pi:.1:pi,log(hist(a,-pi:.1:pi)),'Linewidth',5);hold on;
plot(-pi:.1:pi,log(numel(a)*circ_vmpdf1(-pi:.1:pi,theta,k(i))),'--','Linewidth',2);
plot(-pi:.1:pi,log(numel(a)*circ_wcpdf(-pi:.1:pi,theta,g(i))),'r--','Linewidth',2);
axis tight;drawnow;legend({'angles','best von mises', 'best cauchy'});legend boxoff
hAll = hist(abs(asigs(:)),0:.1:1.1);
hSpk = hist(abs(asigs(spikes)),0:.1:1.1);
histZ = zeros(p,sum(spikes(:)));
%asigs = asigs(:);spikes = spikes(:);
for i =1:p
    histZ(i,:) = asigs(find(spikes)-i+1);
end
figure;plot(histZ);
figure;hold all;plot(hAll/sum(hAll));plot(hSpk/sum(hSpk));
plot(hSpk./hAll*10);
%end
bounds{1} = -1:.05:1;
bounds{2} = -1:.05:1;
hAll = hist3([real(asigs(:)) imag(asigs(:))],bounds);
figure;plot(hAll);axis tight;
hSpk = hist3([real(asigs(spikes)),imag(asigs(spikes))],bounds);
figure;imagesc(log(hAll));axis image;
figure;imagesc(log(hSpk));axis image;
figure;imagesc(hSpk);axis image;
figure;imagesc(log(hSpk./hAll));axis image;
figure;surfc(log(hSpk./hAll));
bounds{1} = 0:.02:1;%.02
bounds{2} = -pi:.1:pi;%.1
hAll = hist3([abs(asigs(:)) angle(asigs(:))],bounds);
hSpk = hist3([abs(asigs(spikes)) angle(asigs(spikes))],bounds);
%figure;imagesc(log(hAll));axis image;
figure;imagesc(log(hSpk));axis image;
figure;imagesc(log(hSpk./hAll));axis image;

%figure;plot((hSpk./hAll)');
%figure;plot((hSpk)');
absSpk = abs(asigs(spikes));
angSpk = angle(asigs(spikes));
xs = -pi:.1:pi;
figure;
for i = 1:10
subplot(3,4,i);
temp = angSpk(absSpk > (i-1)/10 & absSpk < i/10);
[t(i) k(i)] = circ_vmpar(temp);
plot(xs,log(hist(temp,xs)));hold all;
plot(xs,log(numel(temp)*circ_vmpdf1(xs,t(i),k(i))));
end
figure;plot(t);hold all;plot(k);

% figure;plot(1./g,'Linewidth',5);hold all;
% plot(k,'Linewidth',5);
% plot((1:numIter)/2,'--','Linewidth',5);
% set(gca,'fontsize',16);
% legend({'1/gamma (cauchy)','kappa (von mises)','.5*sigma(imag)/sigma(real)'},...
%     'Location','NorthWest');
% legend boxoff
% axis tight;
% title 'best fit parameters for different sigma'
% xlabel('sigma(imag)/sigma(real)');