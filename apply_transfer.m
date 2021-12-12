function y = apply_transfer(b, x)

% APPLY_TRANSFER applies the filter transfer for an array of microphones to the sound
% that is emitted by the source.
%
% Use as
%   y = apply_transfer(b, x)
% where
%   b is the transfer matrix (Nmic*Order)
%   x is the original sound (1*Nsamples)
%   y is the filtered sound at each microphone (Nmic*Nsamples)
%
% Note that the number of output samples is larger than the number of input
% samples to account for the filter delays.
%
% See also COMPUTE_TRANSFER

[nmic, order] = size(b);

% pad the input signal
nsamples = length(x);
x(nsamples+order-1) = 0;

y = zeros(nmic, length(x));
a = 1;

for i=1:nmic
  y(i,:) = filter(b(i,:), a, x);
end
