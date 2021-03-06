
addpath(genpath('glm_dist'))
load('d002_b0500')

%% Show data...
figure(1)
plot(rpos(:,1),rpos(:,2))
axis equal
title('Rat Position')

%% Example of 2D decoding with various methods (Template Matching, OLE, Bayesian)...

% Define a basis over the 2D track...
basis.n = 8;   % number of basis functions along each dimension
[basis,Xrbf] = get2Dbasis('gaussian',[basis.n basis.n],rpos);

% Positions to use for decoding...
decode_gridn = 50;
[py,px]=meshgrid(linspace(0,1,decode_gridn),linspace(0,1,decode_gridn));
pvec = [px(:) py(:)];
[tmp,dbasis] = get2Dbasis('gaussian',[basis.n basis.n],pvec);

%% Fit place fields (basic linear-Gaussian model) to use with Template matching and Bayesian decoding...

nfoldcv = 10;

% Fit n-fold cross-validated, L2-regularized place-field models for each neuron/lfp-channel...
y = stdize(spk);
for chan=1:size(y,2)
    fprintf('Channel %03i/%03i...\n',chan,size(y,2))
    m(chan) = fitCVridge(Xrbf,y(:,chan),nfoldcv,[0 logspace(-3,1,10)]);
end

% Collect place fields for each cv-fold...
lam = cell(0);
for i=1:nfoldcv
    for chan=1:size(y,2)
        lam{i}(:,chan) = m(chan).breg(1,i)+dbasis*m(chan).breg(2:end,i);
    end
end

%% Plot model fits...

figure(1)
clf
c=1;
for chan=1:min(80,size(y,2))
    subplot(10,8,c)
    lamplot = mean(m(chan).breg(1,:),2)+dbasis*mean(m(chan).breg(2:end,:),2);
    imagesc(linspace(0,1,decode_gridn),linspace(0,1,decode_gridn),reshape(lamplot,[1 1]*decode_gridn)')
    hold on
    idx = find(spk(:,chan)>0);
    ridx = randperm(length(idx));
    idx = idx(ridx(1:min(length(idx),50)));
    plot(rpos(idx,1),rpos(idx,2),'k+')
    hold off
    axis tight
    title(num2str(chan))
    set(gca,'XTick',[])
    set(gca,'YTick',[])
    drawnow
    c=c+1;
end

%% %%%%%%% DECODING METHODS %%%%%%%

xl=[1000 1500];   % a plotting window

%% Template Matching...

f = [];
for i=1:nfoldcv
    f(m(1).cvidx_ts{i},:) = y(m(1).cvidx_ts{i},:)*lam{i}';  % read-out function (maximum is most likely pos)
end
decodePostProcess_2D
decoding_err(1,1) = mean(abs(err));
decoding_err(1,2) = median(abs(err));

%% OLE...

f = [];
for i=1:nfoldcv
    g = y(m(1).cvidx_tr{i},:)\Xrbf(m(1).cvidx_tr{i},:);
    f(m(1).cvidx_ts{i},:) = y(m(1).cvidx_ts{i},:)*(g*dbasis');
end
decodePostProcess_2D
decoding_err(2,1) = mean(abs(err));
decoding_err(2,2) = median(abs(err));

%% Bayesian...

f = [];
for i=1:nfoldcv
    % Estimate training set spike-prediction noise...
    sigma=[];
    for chan=1:size(y,2)
        sigma(chan) = std(y(m(1).cvidx_tr{i},chan)-(m(chan).breg(1,i)+Xrbf(m(1).cvidx_tr{i},:)*m(chan).breg(2:end,i)));
    end
    sigma(sigma<0.01)=mean(sigma);
    
    f(m(1).cvidx_ts{i},:) = decodeBayesian_gauss(y(m(1).cvidx_ts{i},:),lam{i},sigma');
end
decodePostProcess_2D
decoding_err(3,1) = mean(abs(err));
decoding_err(3,2) = median(abs(err));

%% Compare methods...

figure(4)
subplot(2,1,1)
bar(decoding_err(:,1))
title('Mean Err')
subplot(2,1,2)
bar(decoding_err(:,2))
title('Median Err')