function timepassage = fitc(ExcelData, tag, num_line, amp_limit_down, amp_limit_up, period, plotting, plot_original, left_interval_min, right_interval_min, left_interval_max, right_interval_max, fita_abcx_first, fita_abcx_last)

% The function fitc will use modelfunc.m (which is a sigmoid fitting 
% function) to fit a part of data curves defined by a time interval. 
% If the display option is selected, it will plot the fitted curve.

% This function is called by a program that previously converted excel 
% data into matlab vectors and matrices. If you want to use a fitc for an 
% excel entry, refer to user_fitc.m or fitctag.m

if numel(ExcelData) < 2
    timepassage = NaN;
    return
end
% smoothening the curve to avoid extreme values
ExcelData = transpose(smooth(smooth(ExcelData)));
ExcelData_smoothed = ExcelData;


% finding the likely maximum and minimum (noisy data generate local maxima and minima that are not relevant and should be excluded)
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


% Flattening values that are beyond Max and min
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
    if ~isempty(tag)
         title(strcat('the evolution of the fluoroscence for tag ', tag{length(tag)}));
    else
         title(strcat('the evolution of the fluoroscence (no tag) line', int2str(num_line)));
    end
    xlabel('time in minuts')
    ylabel('2x smoothed intensity of the fluorescence')
end

% user-guided fit interval definition
if nargin == 14
    
    fita_abcx_first = fita_abcx_first / period;
    while fita_abcx_first ~= floor(fita_abcx_first)
        fita_abcx_first = input('the first abcisse for the fit should be a multiple of the period :');
    end
    fita_abcx_last = fita_abcx_last / period;
    while fita_abcx_last ~= floor(fita_abcx_last)
        fita_abcx_last = input('the last abcisse for the fit should be a multiple of the period :');
    end
    
else
    
% determine the time interval when the correct minimum DF value is expected
fita_abcx_first = absmin;
fita_abcx_first = fita_abcx_first(1);
while ExcelData(fita_abcx_first) < amp_limit_down
    fita_abcx_first = fita_abcx_first - 1;
    if fita_abcx_first == 0
        fita_abcx_first = fita_abcx_first + 1;
        break
    end
end
fita_abcx_first*period

% determine the time interval when the correct maximum value is expected
fita_abcx_last = absmax;% 20 210 for 20140926_BF_6autoph_HS42C_d1-14
fita_abcx_last = fita_abcx_last(1); % in case there are several maxima
while ExcelData(fita_abcx_last) > amp_limit_up
    fita_abcx_last = fita_abcx_last + 1;
    if fita_abcx_last > length(ExcelData)
        fita_abcx_last = fita_abcx_last -1;
        break
    end
end
fita_abcx_last*period
 
end



% scale the data to the region to apply fit on
time_length_bis = fita_abcx_first:fita_abcx_last;
ExcelData_bis = ExcelData(fita_abcx_first:fita_abcx_last);

% fitting process
opts = statset('nlinfit');
opts.RobustWgtFun = 'bisquare';
%modelfunc = @(b,x)((b(1)./(1.+exp(-b(2).*(x-b(3))))) + (b(4)^2));
% test if an error will occur during the fit; 'true' means no error
% testfit is a function that only executes the beginning the original function nlinfit
if strcmp(testfit(time_length_bis, ExcelData_bis, @(b,x)modelfunc( b(1),b(2),b(3),b(4),b(5),x ), [1;0.5;50;0.05;0.3], opts),'true') == 1
    
    fitparameters = nlinfit(time_length_bis, ExcelData_bis, @(b,x)modelfunc( b(1),b(2),b(3),b(4),b(5),x ), [1;0.5;50;0.05;0.3], opts);
    fit_func = @(x)modelfunc(fitparameters(1),fitparameters(2),fitparameters(3),fitparameters(4),fitparameters(5),x);
    half_life = fit_func(-10000) + ( (fit_func(10000) - fit_func(-10000)) / 2 );
    fit_search = @(x)modelfunc(fitparameters(1),fitparameters(2),fitparameters(3),fitparameters(4),fitparameters(5),x)-half_life;
    timepassage = fzero(fit_search,300) * period;
    % sorting fits along Z
    if fitparameters(2) > 1 || fit_func(fita_abcx_last) - fit_func(fita_abcx_first) < 0.01
        timepassage = NaN;
        return
    end
   
    if plotting == 'y'
          
        figure
        plot(time_length_plot, ExcelData)
        if ~isempty(tag)
            title(strcat('the fitted evolution of the fluoroscence for tag ', tag{length(tag)}));
        else
             title(strcat('the fitted evolution of the fluoroscence (no tag) line', int2str(num_line)));
        end
        xlabel('time in minuts')
        ylabel('normalized and smoothed intensity of the fluorescence')
        hold on

        plot([fita_abcx_first*period fita_abcx_first*period],[min(ExcelData) max(ExcelData)],'-k') 
        plot([fita_abcx_last*period fita_abcx_last*period],[min(ExcelData) max(ExcelData)],'-b') 

        plot(time_length_plot, fit_func(time_length),'r')

        hold off 
        
    end
    
else
    disp(['fitting is not possible'])
    timepassage = NaN;
    
    if plotting == 'y'
        
        figure
        plot(time_length_plot, ExcelData) 
        if ~isempty(tag)
            title(strcat('the non fitted evolution of the fluoroscence for tag ', tag{length(tag)}));
        else
             title(strcat('the non fitted evolution of the fluoroscence (no tag) line', int2str(num_line)));
        end
        xlabel('time in minuts')
        ylabel('normalized and smoothed intensity of the fluorescence')
        
        hold on

        plot([fita_abcx_first*period fita_abcx_first*period],[min(ExcelData) max(ExcelData)],'-k') 
        plot([fita_abcx_last*period fita_abcx_last*period],[min(ExcelData) max(ExcelData)],'-b')
        
        hold off 
        
    end
end

end

