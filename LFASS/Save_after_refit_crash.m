cd results_folder
fid = fopen('Refitted.txt','w');
fprintf(fid,'condition\t Raw\t Batch-fitted\t Re-fitted\n');
for ifile=1:nfiles
    filename = filelist(ifile).name;
    fprintf(fid,'\n\n\n %s\n', filename);
    for i=1:length(CHECK_NOISE(ifile,:))
        fprintf(fid,'%s\t', tab_txt{ifile,i});
        fprintf(fid,'%i\t', OUT_MATRIX(3*ifile-2,i));
        fprintf(fid,'%i\t', OUT_MATRIX(3*ifile-1,i));
        fprintf(fid,'%i\n', OUT_MATRIX(3*ifile,i));
    end
end
fclose(fid);
cd ..