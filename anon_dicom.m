d = dir('*.dcm');
for p = 1:numel(d)
    dicomanon(d(p).name, sprintf('../10-t1_mpr_sag_p2_iso_0.9_anon/anon%d.dcm', p))
end