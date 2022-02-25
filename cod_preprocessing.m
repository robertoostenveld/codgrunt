% fsample = 96000;
% nseconds = 60*10;
% 
% data = [];
% data.label = {'1', '2', '3', '4'};
% data.time{1} = (1:(nseconds*fsample))/fsample;
% data.trial{1} = randn(length(data.label), nseconds*fsample);


cfg = [];
cfg.selfun{1} = 'browse_sonify_ch1';
cfg.selfun{2} = 'browse_sonify_ch2';
cfg.selfun{3} = 'browse_sonify_ch3';
cfg.selfun{4} = 'browse_sonify_ch4';
cfg.selfun{4} = 'browse_export';

cfg.selcfg{1} = [];
cfg.selcfg{2} = [];
cfg.selcfg{3} = [];
cfg.selcfg{4} = [];
cfg.selcfg{5} = [];

cfg.ylim = [-1 1];
cfg.channel = 1:4;
cfg.chanscale = ones(1,4)*1e3;

cfg.dataset = '01-220214_0154_24kHz.wav';

cfg.blocksize = 60;
ft_databrowser(cfg);

%%

cfg = [];
cfg.dataset = '01-220214_0154_24kHz.wav';
data = ft_preprocessing(cfg);

%%

cfg = [];
cfg.blocksize = 1;
cfgout = ft_databrowser(cfg, data);

% keep the first visually selected segment
cfg = [];
cfg.trl = cfgout.artfctdef.visual.artifact(1,:); 
cfg.trl(:,3) = 0;
data_seg = ft_redefinetrial(cfg, data);

%%

cfg = [];
cfg.toi = data_seg.time{1}(1:1000:end);
cfg.foi = [10 100 1000];
cfg.width = cfg.foi/10;
cfg.bpfilttype = 'but';
cfg.bpfiltord = 2;
cfg.bpfiltdir = 'onepass';
cfg.method = 'hilbert';

freq = ft_freqanalysis(cfg, data_seg);

%%

data_freq = ft_checkdata(freq, 'datatype', 'raw');

%%

cfg = [];
cfg.blocksize = 30;
ft_databrowser(cfg, data_freq)


