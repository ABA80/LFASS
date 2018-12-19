function noise = isnoise( ExcelData, maxnoise, left_interval_max, right_interval_max )

% isnoise determines if a row vector within the excel data file
% will be interpreted as noise or not, and then excluded or not from future
% analysis within the main program fitfolder)


if numel(ExcelData) < 2
    timepassage = NaN;
    return
end
% smoothening the data to remove spikes due to measurement inaccuracies
ExcelData_s = transpose(smooth(smooth(ExcelData)));

% finding the relevant time of maximum fluorescence
if length(ExcelData) > right_interval_max
    absmax = find(ExcelData == max(ExcelData(left_interval_max:right_interval_max)));% 20 210 sur 20140926_BF_6autoph_HS42C_d1-14
else
    absmax = find(ExcelData == max(ExcelData(left_interval_max:length(ExcelData))));
end

if ExcelData_s(absmax(1)) < maxnoise 
    % maxnoise is the maximum value expected in data rows that correspond to
    % empty wells. For instance 1750 for 42C heat-shock data. The maximum
    % fluorescence value wuithin each data row is compared to this number.
    % if it is lower, then the data row is considered as noise, does not
    % need to be fitted, and is excluded from future analysis.
    noise=true;
else
    noise=false;
end


end

