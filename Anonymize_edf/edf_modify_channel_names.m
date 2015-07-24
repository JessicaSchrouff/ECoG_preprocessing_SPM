filename='C:\Users\Pierre Megevand\Documents\postdoc NSLIJ\lij048 StNy\CCEP\StNy_CCEP.edf';
hdr=edf_hdr_reader(filename);
lbl=StNy_chans_modPM; % electrode names in single-column text file imported with MATLAB Import Data Wizard
for k=1:numel(lbl)
    lbl{k}={lbl{k}};
end
hdr.Labels=lbl;
edf_hdr_writer(filename,hdr,'mods');
