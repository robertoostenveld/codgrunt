function browse_sonify(cfg, data)

% BROWSE_SONIFY

cfg.channel = ft_channelselection(cfg.channel, data.label);
chanindx = match_str(data.label, cfg.channel);

if data.fsample==88200 || data.fsample==96000
  dat = decimate(data.trial{1}(chanindx,:), 2);
  Fs = data.fsample/2;
else
  dat = data.trial{1}(chanindx,:);
  Fs = data.fsample;
end

soundview(dat, Fs);
