%This script is meant to run on ONE GENOTYPE'S DATA at a time. 
clear; close all
dir_of_files = uigetdir;
D = dir(dir_of_files);
s = what(dir_of_files);
files = s.mat;
x = 1;
baseline_Ca_value = 5;%change this accordingly, in %F/F
sample_rate = 0.5;%change this accordingly, in seconds

for m = 1:numel(files)
    load([dir_of_files '/' char(files(m))]);
    filename = char(files(m));
    if exist('blc')==1
        BLC_raw_delta_F = blc;
        events(x).temp = resampletemp;
        Image_Time = 1:length(blc);
    else
        BLC_raw_delta_F = BLC_raw_delta_F;
        events(x).temp = temp;
        Image_Time = 1:length(BLC_raw_delta_F);
    end
    figure
    plot(BLC_raw_delta_F, 'b')
    title('Click on each peak, then double click on white space')
    h = gca
    [locs, pks] = getpts(h)
    close
    time_above_baseline = [];
    area_above_baseline = [];
    for p = 1:length(BLC_raw_delta_F)
        
        if BLC_raw_delta_F(p) > baseline_Ca_value
            time_above_baseline(p) = 0.5;
            area_above_baseline(p) = 0.5*(BLC_raw_delta_F(p)-baseline_Ca_value);
        else
            time_above_baseline(p) = nan;
            area_above_baseline(p) = nan;
        end
    end
    events(x).BLC_raw_delta_F = BLC_raw_delta_F;
    events(x).amp = pks(1:end-1)';
    events(x).time = locs(1:end-1)';
    events(x).number = length(events(x).time)';
    events(x).freq = events(x).number/(length(Image_Time)/2);
    events(x).time_above_baseline = nansum(time_above_baseline);
    events(x).area_above_baseline = nansum(area_above_baseline);
    x = x+1;
end

total.amps = catpad(1, events.amp)';     %each column ends up as one worm's data
                                   
total.times = catpad(1, events.time)';   %each column ends up as one worm's data
 
total.numbers = catpad(1, events.number)';%each column ends up as one worm's data
 
total.freqs = catpad(1, events.freq)';    %each column ends up as one worm's data            

total.time_above_baseline = catpad(1, events.time_above_baseline)';

total.area_above_baseline = catpad(1, events.area_above_baseline)';

k = strfind(dir_of_files, 'Tc20');
filename = (['Ca_Events_', dir_of_files(k:end)]);
filename = strrep(filename, '/', '_');%% the '/' would be a '\' in windows! annoying
save([dir_of_files '/' filename], 'events', 'total')
  