infile = {
  '01-220214_0154.wav'
  '01-220221_0316.wav'
  '01-220222_0010.wav'
  };

blocksize = 96000 * 10;

for i=1:length(infile)

  disp(infile{i})
  info = audioinfo(infile{i});

  len = floor(info.TotalSamples/info.SampleRate)*info.SampleRate/4;
  buf = zeros(len, 4, 'single');

  begsample = 1;
  endsample = blocksize;

  while endsample < info.TotalSamples
    disp(round(100*endsample/info.TotalSamples, 2));
    dat = audioread(infile{i}, [begsample endsample], 'double');

    beginsert = round((begsample-1)/4+1);
    endinsert = round((endsample  )/4  );

    for j=1:info.NumChannels
      buf(beginsert:endinsert,j) = decimate(dat(:,j), 4);
    end

    begsample = begsample + blocksize;
    endsample = endsample + blocksize;
  end % while

  buf = buf ./ max(abs(buf(:)));

  [p, f, x] = fileparts(infile{i});
  outfile = fullfile(p, [f '_24kHz' x]);
  audiowrite(outfile, buf, info.SampleRate/4, 'BitsPerSample', 32);

end % for
