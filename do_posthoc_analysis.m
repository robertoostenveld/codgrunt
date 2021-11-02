load dat_93cm
load dat_00cm

dat = ft_read_data('click with two reflections.wav');
dat = ft_read_data('click with tetrahedral arrangement.wav');

begsample = 1;
endsample = size(dat,2);

% 340 m/s
%  34 cm per ms (or per 44.1 samples)
% 7.7 mm per sample

%%

d1 = ft_preproc_baselinecorrect(dat(1,begsample:endsample));
d2 = ft_preproc_baselinecorrect(dat(2,begsample:endsample));
d3 = ft_preproc_baselinecorrect(dat(3,begsample:endsample));
d4 = ft_preproc_baselinecorrect(dat(4,begsample:endsample));

nsample = endsample-begsample+1;

figure
hold on

t1 = (1:nsample);
t3 = (1:nsample)+102;

plot(t1, d1, '.-')
plot(t3, d3, '.-')
hold off

%%

[c, l] = xcorr([d1' d3'], 500, 'normalized');
plot(l, c(:,[1 2 4]), '.-')

%%

figure
hold on
plot(ft_preproc_smooth(abs(hilbert(d1)), 100))
plot(ft_preproc_smooth(abs(hilbert(d1-d2)), 100))
hold off