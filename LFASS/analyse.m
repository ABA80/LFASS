% This program gives the the time at which the DF values reach the half-
% maximum by two methods, the basic method gives the earliest timepoint 
% when the curve reaches it, and the second method gives the half-maximum 
% time after smoothening and fitting the data.
% It first asks which excel table should be given as an entry. This excel 
% file will have to be in the same folder as this matlab function.
% It will then plots both the DF data and the fitted curves.

% 1st NOTE: if you execute analyses.m, it will call this function analyse.m on
% all the relevant curves.
% To speed-up analysis, when using analyses.m, the plotting of the DF data
% and fit have been removed.
% Under analyses.m, if a fit does not converge, it may interrupt the 
% program and cancel the fitting of subsequent data. 
% To remede this, two variables 'debugvar' and 'existence' have been 
% created to enable analyse.m to go on and skip data that can not be fitted
% When a fit fails, the attributes of the relevant variables will not be
% changed for the relevant dataset.

% 2nd NOTE: due to worm movements during the first part of the time-lapse,
% the 15 first values are usually very noisy and are therefore excluded
% from the analysis by default. They are however taken into account in the
% time stamps.


if ~exist('debugvar','var')
    filename = input('\n the name of the excel table (which shall be in the same folder than the program) : \n ', 's');
    cell1 = input('\n analyses between the excel cell : \n ', 's');
    cell2 = input('\n and the excel cell : \n ', 's');
    time_interval = input('the time interval :\n');
    suppressed = input('number of values to suppress from the plot to realize the fit (usually 15) :\n');
end

% importing the excel data
% example of filename = 'Alex-20150513-TBOOH-autophagy-d1to8 treated.xlsx';
xlRange = strcat(cell1,':');
xlRange = strcat(xlRange,cell2);
ExcelData = xlsread (filename, 1, xlRange);
while numel(ExcelData) == 0 
    reply = 'n';
    clear debugvar;
    break 
end

% exclusion of the first (noisy) data points
ExcelData = ExcelData(suppressed:length(ExcelData));

% first normalization 
ExcelData = (ExcelData - min(ExcelData)) / max( (ExcelData - min(ExcelData) ));
time_length = (1:length(ExcelData)) .* time_interval;

% plotting fits
if ~exist('debugvar','var')
figure
plot(time_length, ExcelData)
title(strcat('the evolution of the fluoroscence (with suppression of initial values) between cell ',strcat(cell1, strcat(' and cell ', cell2))))
xlabel('time in minutes')
ylabel('normalized fluorescence intensity')
end




% changing the extrem values just to make the old method of passage over
% the half
ExcelData_firstmethod = ExcelData;
% for that we have to find the interval where shall be the extrem values
max_points = floor(9 * length(ExcelData_firstmethod) / 10);
for a = 1:40
    if ExcelData_firstmethod(a) > max(ExcelData_firstmethod(40:max_points))
        ExcelData_firstmethod(a) = max(ExcelData_firstmethod(40:max_points));
    end
end

for b = max_points:length(ExcelData_firstmethod)
    if ExcelData_firstmethod(b) < min(ExcelData_firstmethod(20:max_points))
        ExcelData_firstmethod(b) = min(ExcelData_firstmethod(20:max_points));
    end
end

% normalization
ExcelData_firstmethod = (ExcelData_firstmethod - min(ExcelData_firstmethod)) / max( (ExcelData_firstmethod - min(ExcelData_firstmethod) ));

% extracting the first time-passage over 50%, basic method
%time_passageof = time_interval + 27 * time_interval;
time_passageof = find(ExcelData_firstmethod == 0);
time_passageof = time_passageof(1);
while ExcelData_firstmethod(time_passageof / time_interval) < 0.5 %min(ExcelData) + 0.5 * (max(ExcelData) - min(ExcelData))
    time_passageof = time_passageof + time_interval;
    if time_passageof > numel(ExcelData_firstmethod) * time_interval
        time_passageof = NaN;
        break
    end
end
if ~isnan(time_passageof)
    time_passageof = ( time_passageof + (suppressed*time_interval) );
end





% smoothing the curve to avoid extrem values
ExcelData = transpose(smooth(ExcelData));
 
% changing the extrem values one again
for a = 1:40
    if ExcelData(a) > max(ExcelData(40:max_points))
        ExcelData(a) = max(ExcelData(40:max_points));
    end
end

for b = max_points:length(ExcelData)
    if ExcelData(b) < min(ExcelData(20:max_points))
        ExcelData(b) = min(ExcelData(20:max_points));
    end
end

% second normalization operation
ExcelData = (ExcelData - min(ExcelData)) / max( (ExcelData - min(ExcelData) ));
time_length = (1:length(ExcelData)) .* time_interval;

% figuring out
if ~exist('debugvar','var')
figure
plot(time_length, ExcelData)
title(strcat('the smoothed evolution of the fluoroscence (with suppression of initial values) between cell ',strcat(cell1, strcat(' and cell ', cell2))))
xlabel('time in minuts')
ylabel('normalized and smoothed intensity of the fluorescence')
end




% same purpose of extracting the time passage over 50%, using a sigmoid fitting
hold on

% a method to find the fine intervals to fit the curve
interval1 = time_interval;
while ExcelData(interval1 / time_interval) > 0.11 %1.11 * min(ExcelData(15:length(ExcelData)))
    interval1 = interval1 + time_interval;
end

abcisses_maximum = find(ExcelData(40:length(ExcelData)) - 1 == 0) + 39;
interval2 = abcisses_maximum(1) * time_interval;
while ExcelData(interval2 / time_interval) > 0.95 %0.94 * max(ExcelData)
    interval2 = interval2 + time_interval;
end

if ~exist('debugvar','var')
plot([interval1 interval1],[min(ExcelData) max(ExcelData)],'-k') 
plot([interval2 interval2],[min(ExcelData) max(ExcelData)],'-k') 
end



% working to fit on a fragment of the data
time_length_bis = interval1:time_interval:interval2;
ExcelData_bis = ExcelData(interval1/time_interval:interval2/time_interval);

% fitting process
% debugvar is cleared in order to remain the file usable in case of a bug exist with the fit
% process
clear existence
if exist('debugvar','var')
    clear debugvar;
    existence = 1;
end

opts = statset('nlinfit');
opts.RobustWgtFun = 'bisquare';
modelfunc = @(b,x)((b(1)./(1.+exp(-b(2).*(x-b(3))))) + (b(4)^2));
% test if an error will occur during the fit; 'true' means no error
% testfit is a function that only executes the beginning of the original function nlinfit
if strcmp(testfit(time_length_bis, ExcelData_bis, modelfunc, [1;0.5;50;0.05], opts),'true') == 1
    
    fitparameters = nlinfit(time_length_bis, ExcelData_bis, modelfunc, [1;0.5;50;0.05], opts);

    if exist('existence','var')
        debugvar = 1;
    end

    % plotting the fit upon the curve
    if ~exist('debugvar','var')
    plot(time_length, (fitparameters(1)./(1+exp(-fitparameters(2)*(time_length-fitparameters(3)))))+(fitparameters(4)^2),'r')
    end
    hold off

    % seeking the time passage to the 50%
    fit_func = @(x)((fitparameters(1)./(1+exp(-fitparameters(2)*(x-fitparameters(3)))))+(fitparameters(4)^2)-0.5);
    %fit_func_percent = @(x)(fit_func(x) - (fit_func(interval1) + 0.5 * (fit_func(interval2) - fit_func(interval1))));
    time_passage = fzero(fit_func, 300) + (suppressed * time_interval);

    % saving the results in a matrix
    if exist('debugvar','var')
        OUT_MATRIX (1, num_cell) = time_passageof;
        OUT_MATRIX (2, num_cell) = time_passage;
    end


else

    disp(['no sigmoid fit for this curve'])
    figure
    plot(time_length, ExcelData)
    title(strcat('the evolution of the fluoroscence cannot be fitted between cell ',strcat(cell1, strcat(' and cell ', cell2))))
    xlabel('time in minuts')
    ylabel('normalized intensity of the fluorescence')
    OUT_MATRIX (1, num_cell) = NaN;
    OUT_MATRIX (2, num_cell) = NaN;
end



clear debugvar;