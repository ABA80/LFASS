% A small routine to plot a given smoothened data row from a given excel file identified by file name and row number 

filename = input('\n the name of the excel table (which shall be in the same folder than the program) : \n ', 's')
num_line = input('\n which line : \n','s');
period = input('the time interval :\n');

xlRange = strcat(num_line,strcat(':', num_line))
ExcelDatas = xlsread (filename, 1, xlRange);

% smoothening the curve to remove spikes due to measurement inaccuracies
ExcelData = transpose(smooth(ExcelDatas));
ExcelData2 = transpose(smooth(ExcelDatas,'rlowess'));
ExcelData4 = transpose(smooth(smooth(ExcelDatas)));
if 0
% normalization
ExcelData = (ExcelData - min(ExcelData)) / max( (ExcelData - min(ExcelData) ));
end
time_length = (1:length(ExcelData)) .* time_interval;

figure
hold on
plot(time_length, ExcelDatas,'-r')
plot(time_length, ExcelData,'-k')
plot(time_length, ExcelData2,'-y')
plot(time_length, ExcelData4,'-b')
title(strcat('the evolution of the fluoroscence of the line  ', num_line));
xlabel('time in minuts')
ylabel('normalized intensity of the fluorescence')
hold off