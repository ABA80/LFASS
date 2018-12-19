function time_passage = basicfunc(ExcelData, tag, period, plot_original, left_interval_min, right_interval_min, left_interval_max, right_interval_max )

% This function will find the time of half-maximum based on the basic 
% method: it gives the time of earliest data point that has a DF value 
% above teh half-maximum.

% This function is only called as part of a higher level program that 
% converts excel data into matlab vectors and matrices. 
% If you wish to use a basicfunc for an excel entry, refer to the 
% user_basicfunc.m

if numel(ExcelData) < 2
    time_passage = NaN;
    return
end

% no data smoothening

% setting time intervals relevant to finding Max and min
if length(ExcelData) > right_interval_max
    absmax = find(ExcelData == max(ExcelData(left_interval_max:right_interval_max)));% 20 210 for 20140926_BF_6autoph_HS42C_d1-14
else
    absmax = find(ExcelData == max(ExcelData(left_interval_max:length(ExcelData))));
end
if length(ExcelData) > right_interval_min
    absmin = find(ExcelData == min(ExcelData(left_interval_min:right_interval_min)));% before 77 in 20140926_BF_6autoph_HS42C_d1-14
else
    absmin = find(ExcelData == min(ExcelData(left_interval_min:length(ExcelData))));
end
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
    time_passage = 1; % consider as a noise
else
    time_passage = time_passage * period;
end

if plot_original == 'y'
    figure
    time_length_plot = time_length .* period;
    plot(time_length_plot, ExcelData)
    if ~isempty(tag)
        title(strcat('the fitted evolution of the fluorescence for tag ', tag{length(tag)}));
    else
        title(strcat('the fitted evolution of the fluoroscence (no tag) line', int2str(num_line)));
    end
    xlabel('time in min')
    ylabel('intensity of the fluorescence')
end
end

