%% driver script for learning a model
%%%   
%%%   m - struct containing the basis function variables
%%%     m.patch_sz - image domain patch size (side length of square patch)
%%%     m.M - whitened domain dimensions
%%%     m.N - firstlayer basis function dimensions
%%%     m.L - phase transformation basis functions dimensions
%%%     m.K - amplitude basis function dimensions
%%%     m.t - number of learning iterations
%%%     
%%%     m.A - first layer complex basis functions (m.M x m.N)
%%%     m.D - second layer transformation components (m.N x m.L)
%%%     m.B - second layer amplitude components (m.N x m.K)
%%%     
%%%   p - struct containing the learning, inference, and other parameters
%%%     p.firstlayer - first layer complex basis function parameters
%%%     p.ampmodel - second layer amplitude component parameters
%%%     p.phasetrans - second layer phase transformation parameters
%%%     
%%%   Summary of learning proceedure:
%%%       1. Initialize parameters
%%%       2. Estimate whitening transform
%%%       3. Learn first layer complex basis functions
%%%       4. Infer large batch of first layer coefficients
%%%       5. Learn second layer phase tranformation components
%%%       6. Learn second layer amplitude components
%%%       7. Display the results

%% Initialize parameters
for i = 1:8
    for j = 1:8
clear m;clear p;

reset(RandStream.getDefaultStream);

warning('off','MATLAB:divideByZero')
warning('off','MATLAB:nearlySingularMatrix')

run_name = '1';

% data
p.data_type = 'lfp';% 'vid075-chunks';'sim';%

% specify model dimensions
m.patch_sz =  96; % num elecs size
%m.M =        64; % this parameter is determined by the whitening proceedure
m.N =        20;  % firstlayer basis functions
%m.L =        25;  % phasetrans basis functions
%m.K =        25;  % ampmodel basis functions

if strcmp(p.data_type,'sim')
    m.N = 2;
end

% specify priors
p.firstlayer.prior = 'laplace_Z';%'l1l2';%'slow_cauchy';% changed per jascha's suggestion %slow_
%p.ampmodel.prior = 'slow_laplace';
%p.phasetrans.prior = 'slow_laplace';%'slow_cauchy';

% specify outerloop learning method
p.firstlayer.basis_method = 'steepest_adapt';%'steepest';%
%p.ampmodel.basis_method = 'steepest_adapt';
%p.phasetrans.basis_method = 'steepest_adapt';

% specifiy inference methods
p.firstlayer.inference_method='minFunc_ind';%'steepest';%
%p.ampmodel.inference_method='minFunc_ind';%'minFunc_ind';%
%p.phasetrans.inference_method='minFunc_ind';%'minFunc_ind';%

% misc
p.use_gpu = 0;
p.renorm_length=1;%1;
%p.normalize_crop=0;
p.whiten_patches=0;
p.p_every = 0;
p.show_p = 0;
p.quiet = 0;

%% Init
[m, p] = init(m,p,[i j]);
%display_A(m);

% save path
%fname=[sprintf('patchsz%d_A%dx%d_D%d_B%d_%s',m.patch_sz,m.M,m.N,m.L,m.K,run_name) '_%s.mat'];

fname=[strrep(datestr(now),' ','_') sprintf('patchsz%d_A%dx%d',m.patch_sz,m.M) '_%s.mat'];

% display parameters
display_every= 1000;


%% learn firstlayer A

epochs = 5;
num_trials = 1000;
save_every= epochs*num_trials;
for epoch = 1:epochs
    learn_firstlayer
end
    end
end
% epochs = 35;
% p.firstlayer.eta_dA_target = 2*p.firstlayer.eta_dA_target;
% 
% for epoch = 1:epochs
%     learn_firstlayer
% end
% 
% % anneal
% epochs = 5;
% p.firstlayer.eta_dA_target = .25*p.firstlayer.eta_dA_target;
% 
% for epoch = 1:epochs
%     learn_firstlayer
% end
% 
% if p.use_gpu
%     m.A = double(m.A);
% end
% 
% save_model(sprintf(fname,sprintf('learn_firstlayer_t=%d',m.t)),m,p);
% 
%% Collect data for second layer learning
% 
% p.firstlayer.prior = 'slow_gauss';
% p.firstlayer.a_gauss_beta = 8.;
% 
% p.load_segments = 100; % p.patches_load*p.load_segments*p.segment_szt ~= total_time_slices
% collect_firstlayer_responses
% 
% eval(['save data/' sprintf(fname,'Z_responses') ' m p Z_store']);
% 
% %% learn phasetrans D
% if ~exist('Z_store','var')
%     eval(['load data/' sprintf(fname,'Z_responses') ' Z_store']);
%     p.segment_szt = p.imszt*p.cons_chunks;
%     p.load_segments = size(Z_store,2)/p.segment_szt;
% end
% 
% epochs = 5;
% num_trials = 500;
% 
% for epoch = 1:epochs
%     learn_phasetrans
% end
% 
% epochs = 35;
% p.phasetrans.eta_dD_target = 2*p.phasetrans.eta_dD_target;
% 
% for epoch = 1:epochs
%     learn_phasetrans
% end
% 
% % anneal
% epochs = 5;
% p.phasetrans.eta_dD_target = .25*p.phasetrans.eta_dD_target;
% 
% for epoch = 1:epochs
%     learn_phasetrans
% end
% 
% if p.use_gpu
%     m.D = double(m.D);
% end
% 
% save_model(sprintf(fname,sprintf('learn_phasetrans_t=%d',m.t)),m,p);
% 
% 
% %% learn ampmodel B
% 
% if ~exist('Z_store','var')
%     eval(['load data/' sprintf(fname,'Z_responses') ' Z_store']);
%     p.segment_szt = p.imszt*p.cons_chunks;
%     p.load_segments = size(Z_store,2)/p.segment_szt;
% end
% 
% [m, p] = init_ampmodel(Z_store,m,p);
% 
% p.batch_size = 100;
% 
% epochs = 5;
% num_trials = 500;
% 
% for epoch = 1:epochs
%     learn_ampmodel
% end
% 
% epochs = 35;
% p.ampmodel.eta_dB_target = 2*p.ampmodel.eta_dB_target;
% 
% for epoch = 1:epochs
%     learn_ampmodel
% end
% 
% % anneal
% epochs = 5;
% p.ampmodel.eta_dB_target = .25*p.ampmodel.eta_dB_target;
% 
% for epoch = 1:epochs
%     learn_ampmodel
% end
% 
% if p.use_gpu
%     m.B = double(m.B);
% end
% 
% save_model(sprintf(fname,sprintf('learn_ampmodel_t=%d',m.t)),m,p);
% 
% %% save final results and display
% save_model(sprintf(fname,'final'),m,p);
% 
% close all
% display_A(m,[],1);
% display_B(m,3);
% display_D(m,5);