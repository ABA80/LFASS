function timepassage = fitctag( filename, tag, amp_limit_down, amp_limit_up, period, plotting, plot_original, left_interval_min, right_interval_min, left_interval_max, right_interval_max, fita_abcx_first, fita_abcx_last )

% This function is particularly useful to return to data that were not
% fitted optimally during the bulk analysis, or to work out by trial and
% error a set of initial parameters that optimizes the bulk analysis.
% Given a file name and a known tag from an excel data table and few 
% other parameters, fitc will fit only the data corresponding 
% to the tag in the .xlsx file with modelfunc.m (sigmoidal fit), and within
% a specified time interval
% It will also plot the fitted curve over the data curve if wanted.

% To execute, press in the console : user_fitc( filename, num_line,
% amp_limit_down, amp_limit_up, period, plotting, plot_original, 
% left_interval_min, right_interval_min, left_interval_max, 
% right_interval_max, fita_abcx_first, fita_abcx_last ).

% where : 
%    * filename is the name of the file including the path from the folder 
% where you are located. Exemple, if you have a file called "file.xlsx" in 
% the folder "filefolder", which is in the folder "fitfolder", and you are 
% located in "fitfolder", then you have to press in the console:
% filename = 'filefolder/file.xlsx'

%    * tag is your sample identifier, which is to be entered in the excel 
% table in the last cell at the end of the time-lapse data row.

%    * period is the time period between two successive measurements of the
% same sample. It shoudl be the same for all data analysed in one go.

%    * amp_limit_down is the normalised tolerance for setting the lower
% plateau of the sigmoidal fit. If taken typically at 0.06 (6%), it will allow 
% for all points around the minimum and comprised between 0 and 0.06 to be used
% to fit the lower plateau. Consequently, it also gives the first time point 
% that defines the time interval in which data are fitted.
% Together with amp_limit_up they allow for the sigmoidal fit to be constraint
% within reasonable values. 

%    * amp_limit_up is the normalised tolerance for setting the upper
% plateau of the sigmoidal fit. If taken typically at 0.94 (6% from 100%),
% it will allow for all points around the minimum and comprised between 1
% and 0.94 to be used to fit the upper plateau. Consequently, it also gives
% the last time point that defines the time interval in which data are fitted.

%    * press plotting = 'y'; if you want to plot the fitted data, 
% else press plotting = 'n';

%    * press plotting = 'y'; if you want to plot the original data, 
% else press plotting = 'n';

%    * left_interval_min is the first time point at which to start the search
% for a minimum. Example: 1*period.

%    * right_interval_min is the last time point at which to stop the search
% for a minimum. Example: 77*period.

%    * left_interval_max is the first time point at which to start the search
% for a maximum. Example: 42*period.

%    * right_interval_min is the last time point at which to stop the search
% for a maximum. Example: 210*period.

%    * optionally, you can specify fixed start/stop time point 
% fita_abcx_first/fita_abcx_last between which you want the fit to be done
% This is typically used after teh bulk analysis failed for <5% of the data 
% rows and the user is queried for specifying new fitting intervals.


if nargin < 11 || nargin == 12
   
    disp(['bad argument number : user_fitc( filename, tag, amp_limit_down, amp_limit_up, period, plotting, plot_original, left_interval_min,right_interval_min, left_interval_max, right_interval_max, fita_abcx_first, fita_abcx_last )']);
    timepassage=0;
    return
    
end



% to find the beginning of the excel file
num_line = 1;
xlRange = strcat(int2str(num_line),strcat(':', int2str(num_line)));
[find_first,txt] = xlsread (filename, 1, xlRange);
while numel(find_first) < 6
    num_line = num_line + 1;
    xlRange = strcat(int2str(num_line),strcat(':', int2str(num_line)));
    [find_first,txt] = xlsread (filename, 1, xlRange);
end
ExcelData = find_first;

while ~strcmp(txt{length(txt)},tag)
    num_line = num_line + 1;
    xlRange = strcat(int2str(num_line),strcat(':', int2str(num_line)));
    [ExcelData,txt] = xlsread (filename, 1, xlRange);
    if numel(ExcelData) < 5
        disp(['tag not found'])
        return
    end
end
num_line 
xlRange = strcat(int2str(num_line),strcat(':', int2str(num_line)));
ExcelData = xlsread (filename, 1, xlRange);
if numel(ExcelData) < 2
    timepassage = NaN;
    return
end
% smoothening the curve to reduce noise effects on the search for min and Max
ExcelData = transpose(smooth(smooth(ExcelData)));
ExcelData_smoothed = ExcelData;

% finding the relevant maximum and minimum
if length(ExcelData) > right_interval_max
    absmax = find(ExcelData == max(ExcelData(left_interval_max:right_interval_max)));% 20 210 sur 20140926_BF_6autoph_HS42C_d1-14
else
    absmax = find(ExcelData == max(ExcelData(left_interval_max:length(ExcelData))));
end
if length(ExcelData) > right_interval_min
    absmin = find(ExcelData == min(ExcelData(left_interval_min:right_interval_min)));%min avant= 77 sur 20140926_BF_6autoph_HS42C_d1-14
else
    absmin = find(ExcelData == min(ExcelData(left_interval_min:length(ExcelData))));
end

% bringing values thata are beyond the minimum and teh maximum to either the maximum value or the minimum value (whichever one is closer).
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
time_length = (1:length(ExcelData));
time_length_plot = time_length .* period;

% plotting the smoothened data
if plot_original == 'y'
    figure
    plot(time_length_plot, ExcelData_smoothed)
    title(strcat('the 2x smoothed evolution of the fluoroscence for tag ', tag ))
    xlabel('time in minuts')
    ylabel('2x smoothed intensity of the fluorescence')
end

% defining the fitting interval
if nargin == 13
    
    fita_abcx_first = fita_abcx_first / period;
    while fita_abcx_first ~= floor(fita_abcx_first)
        fita_abcx_first = input('the first abcisse for the fit should be a multiple of the time_interval :');
    end
    fita_abcx_last = fita_abcx_last / period;
    while fita_abcx_last ~= floor(fita_abcx_last)
        fita_abcx_last = input('the last abcisse for the fit should be a multiple of the time_interval :');
    end
    
else
    
% determining the lower boundery of the fitting time interval
fita_abcx_first = absmin;
fita_abcx_first = fita_abcx_first(1);
while ExcelData(fita_abcx_first) < amp_limit_down
    fita_abcx_first = fita_abcx_first - 1;
    if fita_abcx_first == 0
        fita_abcx_first = fita_abcx_first + 1;
        break
    end
end
fita_abcx_first*period;

% determining the upper boundery of the fitting time interval
fita_abcx_last = absmax;% 20 210 for 20140926_BF_6autoph_HS42C_d1-14
fita_abcx_last = fita_abcx_last(1); % in case there are several maxima
while ExcelData(fita_abcx_last) > amp_limit_up
    fita_abcx_last = fita_abcx_last + 1;
    if fita_abcx_last > length(ExcelData)
        fita_abcx_last = fita_abcx_last -1;
        break
    end
end
fita_abcx_last*period;

end


% restricting fit to data comprised within the fitting time interval
time_length_bis = fita_abcx_first:fita_abcx_last;
ExcelData_bis = ExcelData(fita_abcx_first:fita_abcx_last);

% fitting process
opts = statset('nlinfit');
opts.RobustWgtFun = 'bisquare';
%modelfunc = @(b,x)((b(1)./(1.+exp(-b(2).*(x-b(3))))) + (b(4)^2));
% test if an error (the fit does not converge) occurs during the fit; gives 'true' if no error
% testfit is a function that only executes the beginning of the original function nlinfit
if strcmp(testfit(time_length_bis, ExcelData_bis, @(b,x)modelfunc( b(1),b(2),b(3),b(4),b(5),x ), [1;0.5;50;0.05;0.3], opts),'true') == 1
    
    fitparameters = nlinfit(time_length_bis, ExcelData_bis, @(b,x)modelfunc( b(1),b(2),b(3),b(4),b(5),x ), [1;0.5;50;0.05;0.3], opts);
    fit_func = @(x)modelfunc(fitparameters(1),fitparameters(2),fitparameters(3),fitparameters(4),fitparameters(5),x);
    half_life = fit_func(-1000) + ( (fit_func(1000) - fit_func(-1000)) / 2 );
    fit_search = @(x)modelfunc(fitparameters(1),fitparameters(2),fitparameters(3),fitparameters(4),fitparameters(5),x)-half_life;
    timepassage = fzero(fit_search,300) * period;
    if fitparameters(2) > 1 || fit_func(fita_abcx_last) - fit_func(fita_abcx_first) < 0.01
        timepassage = NaN;
        return
    end
   
    if plotting == 'y'
          
        figure
        plot(time_length_plot, ExcelData)
        title(strcat('the fitted evolution of the fluoroscence at the line', int2str(num_line)))
        xlabel('time in minuts')
        ylabel('normalized and smoothed intensity of the fluorescence')
        hold on

        plot([fita_abcx_first*period fita_abcx_first*period],[min(ExcelData) max(ExcelData)],'-k') 
        plot([fita_abcx_last*period fita_abcx_last*period],[min(ExcelData) max(ExcelData)],'-b') 

        plot(time_length_plot, fit_func(time_length),'r')

        hold off 
        
    end
    
else
    disp(['no fitting possible'])
    timepassage = NaN;
    
    if plotting == 'y'
        
        figure
        plot(time_length_plot, ExcelData) 
        title(strcat('the non fitted evolution of the fluoroscence at the line', int2str(num_line)))
        xlabel('time in minuts')
        ylabel('normalized and smoothed intensity of the fluorescence')
        
        hold on

        plot([fita_abcx_first*period fita_abcx_first*period],[min(ExcelData) max(ExcelData)],'-k') 
        plot([fita_abcx_last*period fita_abcx_last*period],[min(ExcelData) max(ExcelData)],'-b')
        
        hold off 
        
    end
end

end

