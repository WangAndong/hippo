% KM_KRR_DEMO Kernel ridge regression (also known as kernel least-squares 
% (KLS) on data sampled from a sinc function.
%
% This program implements the example shown in Figure 2.1 of "Kernel
% Methods for Nonlinear Identification, Equalization and Separation of
% Signals", Ph.D. dissertation by S. Van Vaerenbergh.
%
% Author: Steven Van Vaerenbergh (steven *at* gtas.dicom.unican.es), 2010
% Id: km_krr_demo.m v1.0
% This file is part of the Kernel Methods Toolbox (KMBOX) for MATLAB.
% http://sourceforge.net/p/kmbox
%
% This program is free software: you can redistribute it and/or modify it 
% under the terms of the GNU General Public License as published by the 
% Free Software Foundation, version 3 (as included and available at
% http://www.gnu.org/licenses).

close all
clear all

%% PARAMETERS

N = 250;			% number of data points sampled from sinc
N2 = 100;		% number of data points for testing the regression
nvar = 0.05;	% noise variance factor

lambda = 1E-4;		% regularization constant
kernel = 'gauss';	% kernel type
sigma = 1;			% Gaussian kernel width

%% PROGRAM
tic

x = 6*(rand(N,1)-0.5);	% sampled data
n = nvar*randn(N,1);	% noise
y = sin(3*x)./x+n;		% noisy sinc data
x2 = linspace(-3,3,N2)';	% input data for testing the regression

[alpha,y2] = km_krr(x,y,kernel,sigma,lambda,x2);	% regression weights alpha, and output y2 of the regression test
figure;plot(alpha)
y2sinc = sin(3*x2)./x2;	% true sinc output data corresponding to x2

toc
%% OUTPUT

figure; hold on
plot(x,y,'o');
plot(x2,y2,'r');
plot(x2,y2sinc,':','Color',[.5 .5 .5])
legend('noisy data','regression','true sinc function')
title('Kernel ridge regression demo')