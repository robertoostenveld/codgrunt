%%

cfg = [];
cfg.ylim = [-0.2 0.2];
cfg.blocksize = 0.1;
cfg.dataset = 'untitled.wav';
ft_databrowser(cfg);

%%

cfg = [];
cfg.dataset = 'untitled.wav';
data = ft_preprocessing(cfg);

%%

cfg = [];
cfg.method = 'mtmfft';
cfg.taper = 'boxcar';
cfg.output = 'powandcsd';
freq = ft_freqanalysis(cfg, data);

% cfg = [];
% cfg.parameter = 'powspctrm';
% cfg.operation = '-log10(x1)'
% freq_db = ft_math(cfg, freq);

cfg = [];
cfg.layout = 'horizontal';
cfg.skipcomnt = 'no';
cfg.skipscale = 'yes';
cfg.ylim = 'zeromax';
ft_multiplotER(cfg, freq);

%%

freq = ft_checkdata(freq, 'cmbstyle', 'full');

for i=1:4
  for j=1:4
    freq.angle(i,j,:) = unwrap(angle(freq.crsspctrm(i,j,:)));
  end
end


%%

cfg = [];
cfg.parameter = 'angle';
cfg.zlim = 'maxabs';
ft_connectivityplot(cfg, freq);

%%

k = 1;
for i=1:4
  for j=1:4
    subplot(4, 4, k);
    plot(freq.freq, squeeze(freq.angle(i,j,:)));
    axis([0, max(freq.freq), -400, 400]);
    k = k+1;
  end
end