% this program analyses a whole excel table using the function analyse.m
% The results are stored in a new .xlsx (or .csv) and a .txt file.

clear all
close all

% finding the first line of data
filename = input('\n the name of the excel table (which shall be in the same folder than the program) : \n ', 's');
% example filename = 'Alex-20150513-TBOOH-autophagy-d1to8 treated.xlsx';
time_interval = input('the time interval of data points for the whole excel file entry (in minuts) : ');
reply = 'y';
suppressed = input('number of values to suppress from the plot to realize the fit (usually 15) :\n');

findline = [];
num_cell = -1;
while numel(findline) == 0
    num_cell = num_cell + 1;
    findline = xlsread(filename,strcat(int2str(num_cell+1),strcat(':',int2str(num_cell+1)))); 
end    



while reply == 'y'
    
    
    num_cell = num_cell + 1;
    % selecting the cell from the excel table
    cell1 = strcat('A',int2str(num_cell));
    cell2 = strcat('IG',int2str(num_cell));
    % the fit of a single curve
    debugvar = 1;
    analyse
    
    
    % ask if continue
    if 0
    reply = input('Another one ? y/n [y]:','s');
    if isempty(reply)
       reply = 'y';
    end
    end
    
end

% saving the results in a .xlsx and a .txt file
xlswrite('Out.xlsx', OUT_MATRIX)
fid = fopen('resultats.txt','w');
fprintf(fid,'%s\n','resultats');
fprintf(fid,'%s\t','basic method');fprintf(fid,'%s\n','fit method');
fprintf(fid,'%i\t\t\t\t %i\n',OUT_MATRIX);
fclose(fid);