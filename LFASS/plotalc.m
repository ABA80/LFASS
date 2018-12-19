% A small routine to plot all the raw data of an excel file.

filename = input('\n the name of the excel table (which shall be in the same folder than the program) : \n ', 's')
period = input('the time interval :\n');

num_line = 0;
find_first = [];
while numel(find_first) == 0
    num_line = num_line + 1;
    xlRange = strcat(int2str(num_line),strcat(':', int2str(num_line)));
    find_first = xlsread (filename, 1, xlRange);
end

xlRange = strcat(int2str(num_line),strcat(':', int2str(num_line)))
ExcelData = xlsread (filename, 1, xlRange);

while numel(ExcelData) > 1

xlRange = strcat(int2str(num_line),strcat(':', int2str(num_line)))
ExcelData = xlsread (filename, 1, xlRange);
% smoothening the data to remove spikes due to measurement inaccuracies
ExcelData = transpose(smooth(smooth(ExcelData)));
if 0
% normalization
ExcelData = (ExcelData - min(ExcelData)) / max( (ExcelData - min(ExcelData) ));
end
time_length = (1:length(ExcelData)) .* period;

figure
plot(time_length, ExcelData,'-')
title(strcat('the evolution of the fluoroscence of the line ', int2str(num_line)));
xlabel('time in minuts')
ylabel('normalized intensity of the fluorescence')

num_line = num_line + 1

end