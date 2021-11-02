function signal = tdbf(dat, lags, varargin)

% TDBF implements a very simple time-delay beamformer that shifts each of the channels
% with the specified lag and then averages over channels
%
% Use as
%   signal = tdbf(dat, lags, ...)
% where
%   dat  = Nchan*Ntime
%   lags = Nchan*1
%
% Each of the channels in the data matrix is assumed to be zero mean.

[nchan, ntime] = size(dat);

% do a sanity check on the input
assert(numel(lags)==nchan);

for i=1:nchan
  if lags(i)>0
    % shift the channel to the left
    dat(i,:) = [dat(i,(lags(i)+1):end) zeros(1,lags(i))];
  elseif lags(i)<0
    % shift the channel to the right
    dat(i,:) = [zeros(1,-lags(i)) dat(i,1:(end+lags(i)))];
  end
end % for

% compute the mean over the time-delayed channels
signal = mean(dat,1);
