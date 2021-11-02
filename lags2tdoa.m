function b = lags2tdoa(y)

% LAGS2TDOA computes the N time-difference-of-arrivals from the NxN matrix
% with all pairwise lags
%
% Use as
%   lags2tdoa(lags)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% First the specific solution for 4 channels is derived
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% The lags matrix is composed of the pairwise differences
% 
% lags = [
%     0   l2-l1 l3-l1 l4-l1
%   l1-l2   0   l3-l2 l4-l2
%   l1-l3 l2-l3   0   l4-l3
%   l1-l4 l2-l4 l3-l4   0
%  ];
%
% There are 4 unknowns (l1, l2, l3, l4) and 6 unique equations.
%
% The idea is to solve
%   y = x*b + n
% where y represents a vector with the pair-wise lags that were estimated 
% and b represents the absolute lags that we are interested in.

% x1 = [
%    0 -1 -1 -1
%   +1  0  0  0
%   +1  0  0  0
%   +1  0  0  0
%   ];
% 
% x2 = [
%    0 +1  0  0
%   -1  0 -1 -1
%    0 +1  0  0
%    0 +1  0  0
%   ];
% 
% x3 = [
%    0  0 +1  0
%    0  0 +1  0
%   -1 -1  0 -1
%    0  0 +1  0
%   ];
% 
% x4 = [
%    0  0  0 +1
%    0  0  0 +1
%    0  0  0 +1
%   -1 -1 -1  0
%   ];
% 
% % construct the design matrix for the GLM
% x = [x1(:) x2(:) x3(:) x4(:)];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The following works for any number of channels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

nchan = size(y,1);
x = zeros(nchan*nchan, nchan);
for i=1:nchan
  xx = zeros(nchan,nchan);
  xx(i,:) = -1;
  xx(:,i) = +1;
  xx(i,i) =  0;

  x(:,i) = xx(:);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% solve the linear system of equations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

y = y(:);
b = pinv(x)*y;
