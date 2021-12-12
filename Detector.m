function Detector( record )
  % Summary of this function and detailed explanation goes here

  % First convert the record into matlab (creates recordm.mat):
  % wfdb2mat -r record

  fileName = sprintf('%sm.mat', record);

  t=cputime();
  M = 7;
  Fs = 250; % 360 on mitbihDB and 250 on ltstDB
  idx = QRSDetect(fileName,M, Fs);

  fprintf('Running time: %f\n', cputime() - t);
  asciName = sprintf('%s.asc',record);
  fid = fopen(asciName, 'wt');
  for i=1:size(idx,2)
      fprintf(fid,'0:00:00.00 %d N 0 0 0\n', idx(1,i) );
  end
  fclose(fid);

  % Now convert the .asc text output to binary WFDB format:
  % wrann -r record -a qrs <record.asc
  % And evaluate against reference annotations (atr) using bxb:
  % bxb -r record -a atr qrs
end
