%   This is the main program provided. To execute, press in your console :
% fitfolder.

% BRIEF DESCRIPTION
% This program analyses all the files in a given folder
% The program fitfolder and the folder containing all the data have to 
% remain in the same directory. It returns three .txt files, in the folder 
% called results_folder. 

% DATA FILE FORMATTING
% The excel table files have to be formatted as follow. The times series
% are organised in rows. The fluorescence data have to come first in 
% chronological order. The last cell of each row is the sample identifier 
% or tag. There can be other information between the tag and the data, 
% such as method name, other sample identifiers... 
% Depending on the configuration of the automated data output (in the case 
%of a plate-reader for instance), each row may start with up to five 
% identifiers or text entries. Hence each row must have the following format:
% txt cells (0-5) - numerical values (no limit) - txt cells (no limit, the
% last txt cell is the main sample identifier or tag)

% EXECUTION
% In a first step, the program finds the beginning of the data. 
% Then, it uses functions fitc and basicfunc to fit each data row in every file
% in the data folder. fitc and basicfunc differ from user_fitc and user_basicfunc,
% they were designed to be quicker (no multiple reads of the .xlsx file for
% a single analyse). All the results are stored in a matrix OUT_MATRIX, and
% the fact that data rows are recognised as different from noise or not, are
% successfully fitted or not, is stored in a matrix CHECK_NOISE (0 if fit
% converges, 1 if data is seen as noise, 2 if fit fails).
% At the end of the bulk analysis, the matrix OUT_MATRIX is written in a first
% .txt file called: batch fit.txt.
% Next, a routine calls CHECK_NOISE to ask (following visula inspection) 
% whether the user wish to add the data identified as noise to the batch 
% analysis. If so, these data rows are fitted and the update diteration of 
% OUT_MATRIX is written into a second .txt file.
% Finally, teh user is asked whether they wish to attempt refitting of 
% poorly-fitted data by setting adjusted analysis parameters.
% After refitting poorly-fitted curves, a third .txt file is generated that
% includes the refitted data. This final file contain the updated data that
% should be used for subsequent work (the two other files are simply 
% intermediate backup files).

clear all

folder = input('Name of input data folder :\n','s');
filelist = dir(strcat(folder,'/*.xls*'));
nfiles = length(filelist);
mkdir('results_folder');

% Ask user initial parameters for the fit
period = input('Time interval in min between measurements (It should be identical for all files within the data folder): ');
while isempty(period)
    disp('You need an integer')
    period = input('Time interval in min between measurements (It should be identical for all files within the data folder): ');
end
maxnoise = input('Noise threshold (1750 works well for HS42C example file): ');
while isempty(maxnoise)
    disp('You need an integer')
    maxnoise = input('Noise threshold (1750 works well for HS42C example file): ');
end
amp_limit_up = input('Threshold for fitting estimated maximum? (for instance: 0.94): ');
while isempty(amp_limit_up)
    disp('It needs to be between 0 and 1')
    amp_limit_up = input('Threshold for fitting estimated maximum? (for instance: 0.94): ');
end
amp_limit_down = input('Threshold for fitting estimated mininmum (for instance: 0.06): ');
while isempty(amp_limit_down)
    disp('It needs to be between 0 and 1')
    amp_limit_down = input('Threshold for fitting estimated mininmum (for instance: 0.06): ');
end
left_interval_max = input('Timepoint from which the search for a maximum should proceed: ');
while isempty(left_interval_max) || left_interval_max / period ~= floor(left_interval_max / period)
    disp('You need an integer that is a multiple of the period')
    left_interval_max = input('Timepoint from which the search for a maximum should proceed: ');
end
left_interval_max = left_interval_max / period;
right_interval_max = input('timepoint at which the search for a maximum should end: ');
while isempty(right_interval_max) || floor(right_interval_max / period) < left_interval_max || right_interval_max / period ~= floor(right_interval_max / period)
    disp('You need a integer that is a multiple of the period and that is later than the earlier time point selected')
    right_interval_max = input('Timepoint at which the search for a maximum should end: ');
end
right_interval_max = right_interval_max / period;
left_interval_min = input('Timepoint from which the search for a minimum should proceed: ');
while isempty(left_interval_min) || left_interval_min / period ~= floor(left_interval_min / period)
    disp('You need an integer that is a multiple of the period')
    left_interval_min = input('Timepoint from which the search for a minimum should proceed: ');
end
left_interval_min = left_interval_min / period;
right_interval_min = input('timepoint at which the search for a minimum should end: ');
while isempty(right_interval_min) || floor(right_interval_min / period) < left_interval_min || right_interval_min / period ~= floor(right_interval_min / period)
    disp('You need an integer that is a multiple of the period and that is later than the earlier time point selected')
    right_interval_min = input('timepoint at which the search for a minimum should end: ');
end
right_interval_min = right_interval_min / period;

% Ask user if they wish to check plots
disp('(Beware: displaying too many plots can crash Matlab)')
plotting = input('Plotting all batch-fitted curves? ','s');
plot_original = input('Plotting smoothed curves used for batch-fitting? ', 's');

% Fitting routine
for ifile = 1:nfiles

disp(['FILE n° ',sprintf('%d',ifile)])
filename = filelist(ifile).name;

% Finding headings and data rows
num_line = 1;
xlRange = strcat(int2str(num_line),strcat(':', int2str(num_line)));
[find_first,txt] = xlsread (strcat(folder,strcat('/',filename)), 1, xlRange);
while numel(find_first) < 6
    if ~isempty(txt)
        tab_txt{ifile,num_line} = txt{length(txt)};
    end
    num_line = num_line + 1;
    xlRange = strcat(int2str(num_line),strcat(':', int2str(num_line)));
    [find_first,txt] = xlsread (strcat(folder,strcat('/',filename)), 1, xlRange);
end
ExcelData = find_first;

% Fitting data rows
while numel(ExcelData) > 1
    
    if ~isnoise(ExcelData, maxnoise, left_interval_max, right_interval_max)
        OUT_MATRIX (3*ifile,num_line) = fitc(ExcelData, txt, num_line, amp_limit_down, amp_limit_up, period, plotting, plot_original, left_interval_min, right_interval_min, left_interval_max, right_interval_max);
        OUT_MATRIX (3*ifile-2,num_line) = basicfunc(ExcelData, txt, period,'n', left_interval_min, right_interval_min, left_interval_max, right_interval_max);
        OUT_MATRIX (3*ifile-1,num_line) = OUT_MATRIX (3*ifile,num_line);
        if ~isempty(txt)
            tab_txt{ifile,num_line} = txt{length(txt)};
        end
        CHECK_NOISE(ifile,num_line) = 0;
        if isnan(OUT_MATRIX (3*ifile,num_line))
            CHECK_NOISE(ifile,num_line) = 2;
            OUT_MATRIX (3*ifile-1,num_line) = 1;
            OUT_MATRIX (3*ifile,num_line) = 1;
        end
        num_line = num_line + 1;
        xlRange = strcat(int2str(num_line),strcat(':', int2str(num_line)));
        [ExcelData,txt] = xlsread (strcat(folder,strcat('/',filename)), 1, xlRange);        
    else
        OUT_MATRIX (3*ifile-2,num_line) = 1;
        OUT_MATRIX (3*ifile-1,num_line) = 1;
        OUT_MATRIX (3*ifile,num_line) = 1;
        if ~isempty(txt)
            tab_txt{ifile,num_line} = txt{length(txt)};
        end
        CHECK_NOISE(ifile,num_line) = 1;
        num_line = num_line + 1;
        xlRange = strcat(int2str(num_line),strcat(':', int2str(num_line)));
        [ExcelData,txt] = xlsread (strcat(folder,strcat('/',filename)), 1, xlRange);       
    end   
    
end

% saving the raw results in a :-separated .txt
cd results_folder
fid = fopen('Batch analysis only.txt','w');
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

% a procedure to ask the user if some of the data that were considered as
% noise (the maximum value fell below the noise threshold) are to be
% fitted.

% first, determining how many data rows were identified as noisy and excluded from the bulk fitting.
number_noise = 0;
for ifile = 1:nfiles
    for num_line = 1:length(CHECK_NOISE(ifile,:))
        if CHECK_NOISE (ifile,num_line) == 1
            number_noise = number_noise + 1;
        end
    end
end
fprintf('There were %d excluded curves\n', number_noise);

check = input('Do you want to check excluded curves (noise)? :[y/n]\n','s');
while ~strcmp(check,'y') && ~strcmp(check,'n')
    disp('You have to answer y or n')
    check = input('Do you want to check excluded curves (noise)? :[y/n]\n','s');
end
if strcmp(check,'y')
    current_noise = 0;
    close all
    for ifile = 1:nfiles
        for num_line = 1:length(CHECK_NOISE(ifile,:))
            if CHECK_NOISE (ifile,num_line) == 1
                current_noise = current_noise + 1;
                filename = filelist(ifile).name;
                xlRange = strcat(int2str(num_line),strcat(':', int2str(num_line)));
                [ExcelData,txt] = xlsread (strcat(folder,strcat('/',filename)), 1, xlRange);
                if ~isempty(txt)
                    tab_txt{ifile,num_line} = txt{length(txt)};
                end
                ExcelData = transpose(smooth(smooth(ExcelData)));
                time_length = (1:length(ExcelData)) .* period;

                figure
                plot(time_length, ExcelData)
                if ~isempty(txt)
                    title(strcat('Death fluoroscence curve for ', txt{length(txt)}));
                else
                    title(strcat('Death fluoroscence curve ', int2str(num_line)));
                end
                xlabel('Time (minutes)')
                ylabel('Smoothed death fluorescence intensity')
                
                fprintf('noise data n° %d / %d\n', current_noise, number_noise);
                add = input('Do you want to add this file to the analyze ? (q to quit) :[y/n]\n','s');
                while ~strcmp(add,'y') && ~strcmp(add,'n') && ~strcmp(add,'q')
                    disp('You have to answer with a character')
                    add = input('Do you want to add this file to the analyze ? (q to quit) :[y/n]\n','s');
                end
                
                if strcmp(add,'q')
                    break
                end
                
                if strcmp(add,'y')
                    OUT_MATRIX (3*ifile,num_line) = fitc(ExcelData, txt, num_line, amp_limit_down, amp_limit_up, period, 'y', plot_original, left_interval_min, right_interval_min, left_interval_max, right_interval_max);
                    OUT_MATRIX (3*ifile-2,num_line) = basicfunc(ExcelData, txt, period,'n', left_interval_min, right_interval_min, left_interval_max, right_interval_max);
                    CHECK_NOISE(ifile,num_line) = 0;
                end                    
            end
            % saving the noise fitted results in a :-separated .txt
                cd results_folder
                fid = fopen('Batch analysis noise fitted.txt','w');
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
        end
        if exist('add')
            if strcmp(add,'q')
                clear add
                break
            end
        end
    end
end    


% a procedure to ask if the user wants to provide new parameters to refit
% data rows for which the fit did not converge within the fitting interval
% given or calculated.

% first, determining how many data rows could not be fitted.
number_badfit = 0;
for ifile = 1:nfiles
    for num_line = 1:length(CHECK_NOISE(ifile,:))
        if CHECK_NOISE (ifile,num_line) == 2
            number_badfit = number_badfit + 1;
        end
    end
end
fprintf('There were %d poorly fitted curves\n', number_badfit);

manual = input('Do you want to try to re-fit them individually? :[y/n]\n','s');
while isempty(manual)
    disp('reply by y if yes or by any character if no')
    manual = input('Do you want to try to re-fit them individually? :[y/n]\n','s');
end
if strcmp(manual,'y')
    current_badfit = 0;
    close all
    for ifile = 1:nfiles
        for num_line = 1:length(CHECK_NOISE(ifile,:))
            if CHECK_NOISE (ifile,num_line) == 2
                current_badfit = current_badfit + 1;
                filename = filelist(ifile).name;  
                user_fitc(strcat(folder,strcat('/',filename)), num_line, amp_limit_down, amp_limit_up, period, 'y', 'y', left_interval_min, right_interval_min, left_interval_max, right_interval_max);
                fprintf('bad-fitted data n° %d / %d\n', current_badfit,number_badfit);
                fit = input('Do you want to fit this one bad-fitted curves manually ? :[y/n]\n','s');
                while isempty(fit)
                    disp('reply by y if yes or by any character if no')
                    fit = input('Do you want to fit this one bad-fitted curves manually ? :[y/n]\n','s');
                end
                if strcmp(fit,'y')
                    while CHECK_NOISE(ifile,num_line) == 2
                        int1 = input('Enter the left boundary :\n');
                        while isempty(int1)
                           disp('reply with a integer')
                           int1 = input('Enter the left boundary :\n');
                        end
                        int2 = input('Enter the rigth boudary :\n');
                        while isempty(int2)
                            disp('reply with a integer')
                            int2 = input('Enter the right boundary :\n');
                        end
                        OUT_MATRIX (3*ifile,num_line) = user_fitc(strcat(folder,strcat('/',filename)), num_line, amp_limit_down, amp_limit_up, period, 'y', 'y', left_interval_min, right_interval_min, left_interval_max, right_interval_max,int1,int2);
                        OUT_MATRIX (3*ifile-2,num_line) = user_basicfunc(strcat(folder,strcat('/',filename)), num_line, period, 'n', left_interval_min, right_interval_min, left_interval_max, right_interval_max);
                        CHECK_NOISE(ifile,num_line) = input('if the problem is resolved for this fit push 0, \nif you want to stop this one press 1,\nif you want to try again press 2,\nif you want to leave the manual fitting press 4 :\n');
                        if CHECK_NOISE(ifile,num_line) == 1
                           CHECK_NOISE(ifile,num_line) = 0;
                        end
                    end
                    if CHECK_NOISE(ifile,num_line) == 4
                       CHECK_NOISE(ifile,num_line) = 0;
                       break
                    end
                end
            end
        end
        if CHECK_NOISE(ifile,num_line) == 4
           CHECK_NOISE(ifile,num_line) = 0;
           break
        end
    end
end

if strcmp(check,'y') || strcmp(manual,'y')

% saving the results in a .txt
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
end

disp('END OF PROGRAM')        

end           