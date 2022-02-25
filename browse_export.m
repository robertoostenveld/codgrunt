function browse_export(cfg, data)

% BROWSE_EXPORT

[f, p] = uiputfile('*.wav', 'Select an output file...');

if ~isempty(f)
  ft_write_data(fullfile(p, f), data.trial{1}, 'header', ft_fetch_header(data));
end