function time_passage = user_basicfunc( filename, num_line, period, plot_original, left_interval_min, right_interval_min, left_interval_max, right_interval_max )

% This function will find the time of half-maximum based on the basic 
% method: it gives the time of earliest data point that has a DF value 
% above the half-maximum.

%  Refer to the description of user_fitc.m to understand the different
%  parameters.
% DF stands for death fluorescence.

% preparing the data for the fitting
xlRange = strcat(int2str(num_line),strcat(':', int2str(num_line)))
[ExcelData,tag] = xlsread (filename, 1, xlRange);
if numel(ExcelData) < 2
    time_passage = NaN;
    return
end

% no smoothing

% applying time intervals to find time of min Df value and time of max DF value 
if length(ExcelData) > right_interval_max
    absmax = find(ExcelData == max(ExcelData(left_interval_max:right_interval_max)));% 20 210 sur 20140926_BF_6autoph_HS42C_d1-14
else
    absmax = find(ExcelData == max(ExcelData(left_interval_max:length(ExcelData))));
end
absmin = find(ExcelData == min(ExcelData(1:77)));% before 77 for 20140926_BF_6autoph_HS42C_d1-14

for a = 1:length(ExcelData)
    if ExcelData(a) > ExcelData(absmax(1))
        ExcelData(a) = ExcelData(absmax(1));
    end
end
for b = 1:length(ExcelData)
    if ExcelData(b) < ExcelData(absmin(1))
        ExcelData(b) = ExcelData(absmin(1));
    end
end

% normalization
ExcelData = (ExcelData - min(ExcelData)) / max( (ExcelData - min(ExcelData) ));
time_length = (1:length(ExcelData)) .* period;

% extracting the time of half-maximum DF
time_passage = absmin(1);
while ExcelData(time_passage) < 0.5
    time_passage = time_passage + 1;
    if time_passage > absmax(1)
        time_passage = time_passage -1;
        break
    end
end
if time_passage == ExcelData(absmax(1))
    time_passage = period; % consider as a noise
else
    time_passage = time_passage * period;
end

if plot_original == 'y'
    figure
    time_length_plot = time_length .* period;
    plot(time_length_plot, ExcelData)
    if ~isempty(tag)
        title(strcat('the fitted evolution of the fluoroscence for tag ', tag{length(tag)}));
    else
        title(strcat('the fitted evolution of the fluoroscence (no tag) line', int2str(num_line)));
    end
    xlabel('time in minuts')
    ylabel('intensity of the fluorescence')
end
end

