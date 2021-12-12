function b = compute_transfer(soundpos, microphone)

% COMPUTE_TRANSFER computes the filter transfer from a given sound source to an array
% of microphones. The transfer is represented as an array of digital FIR filters.
%
% Use as
%   b = compute_transfer(soundpos, microphone)
% where
%   soundpos is the position of the sound source (1*3)
%   microphone is a structure that describes the microphone array
%   b is the transfer matrix (Nmic*Order)
%
% See also APPLY_TRANSFER

assert(isequal(size(soundpos), [1, 3]));
assert(isstruct(microphone));

fsample = 44100; % Hz
speed = 343; % m/s

nmic = size(microphone.pos,1);

toa = nan(nmic,1);
for i=1:nmic
  toa(i) = norm(microphone.pos(i,:) - soundpos)/speed;
end

% express the time-of-arrival in samples
toa = toa / (1/fsample);

%% interpolate between the two nearest samples

b = zeros(nmic, max(ceil(toa)));
for i=1:nmic
  s1 = floor(toa(i));
  s2 = ceil(toa(i));
  
  f1 = s2-toa(i);
  f2 = toa(i)-s1;
  
  b(i,s1) = f1;
  b(i,s2) = f2;
end

%% quantize to the nearest sample
%
% b = zeros(nmic, max(round(toa)));
% for i=1:nmic
%   s = round(toa(1));
%   f = 1;
%   b(i,s) = f;
% end
