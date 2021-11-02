cfg.dataset = 'buffer://localhost:1972';
cfg.overlap = 0;
cfg.blocksize = 0.5;
cfg.olfilter = 'yes';
cfg.olfreq = [100 20000];


% construct a tetrahedral array corresponding to a 1-meter cube
hydrophone.label = {'1'  '2'  '3'  '4'};
hydrophone.unit = 'm';
hydrophone.elecpos = 0.94*[
  -0.5  -sqrt(0.5)  0         % back, left
  -0.5  +sqrt(0.5)  0         % back, right
  0.5   0         +sqrt(0.5)  % front, top
  0.5   0         -sqrt(0.5)  % front, bottom
  ]/sqrt(2);

% show the distances in cm
for i=1:4
  for j=1:4
    d = sqrt(sum((hydrophone.elecpos(i,:)-hydrophone.elecpos(j,:)).^2));
    fprintf('%d %d: %3.0f cm\n', i, j, 100*d);
  end
end

speed = 340;

%%

% set the default configuration options
cfg.dataformat   = ft_getopt(cfg, 'dataformat',   []);      % default is detected automatically
cfg.headerformat = ft_getopt(cfg, 'headerformat', []);      % default is detected automatically
cfg.eventformat  = ft_getopt(cfg, 'eventformat',  []);      % default is detected automatically
cfg.blocksize    = ft_getopt(cfg, 'blocksize',    1);       % in seconds
cfg.channel      = ft_getopt(cfg, 'channel',      'all');
cfg.overlap      = ft_getopt(cfg, 'overlap',      0);       % in seconds
cfg.bufferdata   = ft_getopt(cfg, 'bufferdata',   'first'); % first or last
cfg.jumptoeof    = ft_getopt(cfg, 'jumptoeof',    'yes');   % jump to end of file at initialization
cfg.olfilter     = ft_getopt(cfg, 'olfilter',     'no');    % continuous online filter
cfg.olfiltord    = ft_getopt(cfg, 'olfiltord',    4);
cfg.olfreq       = ft_getopt(cfg, 'olfreq',       [2 45]);

if ~isfield(cfg, 'dataset') && ~isfield(cfg, 'header') && ~isfield(cfg, 'datafile')
  cfg.dataset = 'buffer://localhost:1972';
end

% translate dataset into datafile+headerfile
cfg = ft_checkconfig(cfg, 'dataset2files', 'yes');
cfg = ft_checkconfig(cfg, 'required', {'datafile' 'headerfile'});

% ensure that the persistent variables related to caching are cleared
clear ft_read_header

% start by reading the header from the realtime buffer
hdr = ft_read_header(cfg.headerfile, 'headerformat', cfg.headerformat, 'cache', true, 'retry', true);

% define a subset of channels for reading
cfg.channel = ft_channelselection(cfg.channel, hdr.label);
chanindx    = match_str(hdr.label, cfg.channel);
nchan       = length(chanindx);
if nchan==0
  ft_error('no channels were selected');
end

% determine the size of blocks to process
blocksize = round(cfg.blocksize * hdr.Fs);
overlap   = round(cfg.overlap*hdr.Fs);

if strcmp(cfg.jumptoeof, 'yes')
  prevSample = hdr.nSamples * hdr.nTrials;
else
  prevSample = 0;
end
count = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is the general realtime loop where incoming data is handled
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
while true
  
  % determine the samples to process
  if strcmp(cfg.bufferdata, 'last')
    % determine number of samples available in buffer
    hdr = ft_read_header(cfg.headerfile, 'headerformat', cfg.headerformat, 'cache', true);
    begsample  = hdr.nSamples*hdr.nTrials - blocksize + 1;
    endsample  = hdr.nSamples*hdr.nTrials;
  elseif strcmp(cfg.bufferdata, 'first')
    begsample  = prevSample+1;
    endsample  = prevSample+blocksize;
  else
    ft_error('unsupported value for cfg.bufferdata');
  end
  
  % this allows overlapping data segments
  if overlap && (begsample>overlap)
    begsample = begsample - overlap;
    endsample = endsample - overlap;
  end
  
  % remember up to where the data was read
  prevSample  = endsample;
  count       = count + 1;
  % fprintf('processing segment %d from sample %d to %d\n', count, begsample, endsample);
  fprintf('.\n');
  
  % read the data segment from buffer
  dat = ft_read_data(cfg.datafile, 'header', hdr, 'dataformat', cfg.dataformat, 'begsample', begsample, 'endsample', endsample, 'chanindx', chanindx, 'checkboundary', false, 'blocking', true);
  dat = double(dat)*5000;
  
  % make a matching time axis
  time = ((begsample:endsample)-1)/hdr.Fs;
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % do some signal processing and filtering
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  if strcmp(cfg.olfilter, 'yes')
    if count==1
      % initialize the filter on the first call
      if cfg.olfreq(1)==0
        fprintf('using online low-pass filter\n');
        [B, A] = butter(cfg.olfiltord, cfg.olfreq(2)/hdr.Fs);
      elseif cfg.olfreq(2)>=hdr.Fs/2
        fprintf('using online high-pass filter\n');
        [B, A] = butter(cfg.olfiltord, cfg.olfreq(1)/hdr.Fs, 'high');
      else
        fprintf('using online band-pass filter\n');
        [B, A] = butter(cfg.olfiltord, cfg.olfreq/hdr.Fs);
      end      % use one sample to initialize
      FM = ft_preproc_online_filter_init(B, A, dat(:,1));
    end
    [FM, dat] = ft_preproc_online_filter_apply(FM, dat);
  end
  
  dat = ft_preproc_baselinecorrect(dat, 1, 1);
  
  [nchan, nsample] = size(dat);
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % do threshold detection, only continue upon a strong signal
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  flt = ft_preproc_smooth(sqrt(sum(dat.^2,1)), hdr.Fs/100);
  amplitude = max(flt)
  if amplitude<800
    continue
  end
  
  % determine where the strong signal starts
  
  threshold = amplitude/5;
  
  begsample = find(flt>threshold, 1)  - round(0.05*hdr.Fs)
  endsample = begsample               + round(0.1*hdr.Fs)
  
  if begsample<1 || endsample>nsample
    warning('too close to the edge')
    continue
  end
  
  % estimate the lags
  [c, l] = xcorr(dat(:,begsample:endsample)', 1000, 'normalized');
  [m, i] = max(c, [], 1);
  lags = reshape(l(i), 4, 4);
  tdoa = lags2tdoa(lags);
  tdoa = round(tdoa - min(tdoa));
  disp(tdoa')
  
  % reconstruct the signal
  signal = tdbf(dat, tdoa);
  
  % estimate the position
  [eX,eb] = algebraicGPSequations(hydrophone.elecpos, tdoa*speed);
  % eX = [2 0 0];
  
  % construct the offsets
  offset = (0:nchan-1) .* 2*mean(max(abs(dat),[],2));
  
  % shift each of the channels vertically for plotting
  for i=1:nchan
    dat(i,:) = dat(i,:) + offset(i);
  end
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % plot the data
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  subplot(2, 2, 1)
  plot(time, dat);
  xlim([time(1) time(end)]);
  ylim([offset(1)-2000 offset(end)+2000])
  try
    height = offset(2)-offset(1);
    line([time(begsample) time(begsample)], [offset(1)-height/3 offset(end)+height/3], 'Color', 'r', 'LineWidth', 0.5);
    line([time(endsample) time(endsample)], [offset(1)-height/3 offset(end)+height/3], 'Color', 'r', 'LineWidth', 0.5);
    for i=1:nchan
      line([time(begsample+tdoa(i)) time(begsample+tdoa(i))], [offset(i)-height/3 offset(i)+height/3], 'Color', 'k', 'LineWidth', 1);
    end
  catch
    % don't draw them if they fall outside the plotted range
  end
  
  subplot(2, 2, 3)
  plot(time, signal);
  xlim([time(1) time(end)]);
  
  subplot(1, 2, 2)
  cla
  ft_plot_sens(hydrophone, 'elecshape', 'sphere', 'elecsize', 0.2, 'label', 'number')
  ft_plot_axes(hydrophone, 'fontsize', eps) % the axes are approx "head-sized" and 15cm long
  
  if isreal(eX)
    ft_plot_dipole(eX, [-1 0 0], 'diameter', 0.2, 'length', 0.2, 'color', 'm');
  else
    warning('failed to reconstruct real position');
  end
  
  axis on
  axis([-2 4 -3 3 -2 4])
  axis vis3d
  grid on
  view(30, 30);
  
  % force an update of the figure
  drawnow
  
  input('press enter to get another one')
  
end % while true

