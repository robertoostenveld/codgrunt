%%

cube = [];
cube.elecpos = [
  0 0 0
  1 0 0
  1 1 0
  0 1 0
  0 0 1
  1 0 1
  1 1 1
  0 1 1
  ];
cube.label = {'1', '2', '3', '4', '5', '6', '7', '8'};
cube.unit = 'm';

ft_plot_sens(cube, 'elecshape', 'sphere', 'elecsize', 0.05, 'label', 'number')
ft_plot_axes(cube, 'fontsize', eps) % the axes are approx "head-sized" and 15cm long

%%

tetraheder = [];
tetraheder.elecpos = [
  0 0 0
  1 1 0
  1 0 1
  0 1 1
  ];
tetraheder.label = {'1', '2', '3', '4'};
tetraheder.unit = 'm';

ft_plot_sens(tetraheder, 'elecshape', 'sphere', 'elecsize', 0.05, 'label', 'number')
ft_plot_axes(tetraheder, 'fontsize', eps) % the axes are approx "head-sized" and 15cm long

%%

hydrophone = tetraheder;
hydrophone.elecpos(:,1) = hydrophone.elecpos(:,1) - mean(hydrophone.elecpos(:,1));
hydrophone.elecpos(:,2) = hydrophone.elecpos(:,2) - mean(hydrophone.elecpos(:,2));
hydrophone.elecpos(:,3) = hydrophone.elecpos(:,3) - mean(hydrophone.elecpos(:,3));

% the radius of the sphere connecting the centres of the hydrophones was approximately 173 mm
hydrophone.elecpos = 2*0.173 * hydrophone.elecpos/sqrt(3/4);

ft_plot_sens(hydrophone, 'elecshape', 'sphere', 'elecsize', 0.03, 'label', 'number')
ft_plot_axes(hydrophone, 'fontsize', eps) % the axes are approx "head-sized" and 15cm long

%%

clear toa tdoa

% speed = 343; % m/s
speed = 1500; % m/s

noiselevel = 1e-6; % in seconds, note that 2e-5 corresponds to one sample at 48000

source = [1 0 0];
for i=1:length(hydrophone.label)
  toa(i,1) = norm(hydrophone.elecpos(i,:)-source)/speed; % in seconds
end

ft_plot_sens(hydrophone, 'elecshape', 'sphere', 'elecsize', 0.03, 'label', 'number')
ft_plot_axes(hydrophone, 'fontsize', eps) % the axes are approx "head-sized" and 15cm long
ft_plot_dipole(source, [0 0 +1], 'diameter', 0.03, 'length', 0.03, 'color', 'k');

for i=1:10
  tdoa = toa-min(toa); % in seconds
  tdoa = tdoa + noiselevel * randn(size(tdoa));
  
  [eX,eb] = algebraicGPSequations(hydrophone.elecpos, tdoa*speed);
  
  ft_plot_dipole(eX, [0 0 -1], 'diameter', 0.03, 'length', 0.03, 'color', 'm');
end

axis on
axis equal
grid on 
axis vis3d
view(30, 30)

