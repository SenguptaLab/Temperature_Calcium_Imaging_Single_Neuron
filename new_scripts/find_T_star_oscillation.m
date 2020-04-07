clear; close all
dir_of_files = uigetdir;
D = dir(dir_of_files);
s = what(dir_of_files);
files = s.mat;
c = 1;
T_star_temps = [];
T_set_point = [];
mean_peak_diff = [];
for m = 1:numel(files)
    load([dir_of_files '/' char(files(m))]);
    filename = char(files(m));
    smooth_temperature = smooth(temp, 20, 'lowess');
    raw_temperature = temp;%%%%%%%% raw_temperature will be referenced to for T_star_temps(eye selection) 
    Image_Time = 1:length(temp);%%% and T_set_point(mathematical selection)
    
    del_F = BLC_clean_delta_F;
    delta_F = BLC_raw_delta_F;
    diff_del_F = diff(del_F);
    
    steep_points = [];             % This is the important part for finding the first 
    time_steep = [];               % sustained increase in the del_F signal.
    increasing = [];
    for j = 1:length(del_F)-20
        if del_F(j+1)>del_F(j)
            increasing(end+1) = 1;
        elseif del_F(j+1)<del_F(j)
            increasing(end+1) = 0;
        end
        if max(del_F(j:j+10))<2,
            increasing(j) = nan;
        end                        % finds points in del_F where nothing rises above 2 for 10
                                   % consective time points and changes the
                                   % just the first point to nan, not all ten
                                   % points.
    end
    inc_points = zeros(1, length(increasing)); 
    for k = 20:length(increasing)-10
        if increasing(k:k+7) == 1  % finds points in del_F where there is continuous
            inc_points(k) = 1;     % increase over at least 8 seconds. The first point
        end                        % will be the T_set_time. The lag will factor in later
        if mean(diff_del_F(k+2:k+7))<0.3  
            inc_points(k) = 0;     %This sets the slope threshold. It checks that the slope of the 
                                   %points 3-8 past the point of interest
                                   %average at least 0.3. This is a bit
                                   %conservative.
        end                        
    end
    
    response_times = find(inc_points==1);
    
    if length(response_times)>0
        T_set_time = Image_Time(response_times(1));
    elseif length(response_times)==0
        T_set_time = 1;
    end
    
    if exist('clean_YFP')==1
        CFPdivYFP = clean_CFP(1:20)./clean_YFP(1:20);%%%this is just for visualization....
        mean_factor = mean(CFPdivYFP);                 %%%Corrects the smaller signal to
        YFP_corrected = clean_YFP*mean_factor;        %%%be of equal beginnning amp as the larger one.
        diff_YFP = diff(YFP_corrected);% All of the YFP_corrected stuff won't generate numbers
        diff_CFP = diff(clean_CFP);   % in the end, its just for display.
        slope_diff = [];
        for i = 1:length(diff_CFP)
            slope_diff(end+1) = diff_CFP(i)-diff_YFP(i);
        end
        
        figure();
        set(0,'DefaultFigurePosition',[100 100 2000 2000]);
        subplot(2,2,1)
        plotyy(Image_Time, clean_CFP, Image_Time, YFP_corrected)
        yL = get(gca,'YLim');
        line([T_set_time T_set_time],yL,'Color','r'); %Red line is a reference for the first fret peak
        title('CFP and YFP traces')
        
        subplot(2,2,2)
        plotyy(Image_Time(1:end-1), diff_CFP, Image_Time(1:end-1), diff_YFP)
        yyL = get(gca,'YLim');
        line([T_set_time T_set_time],yyL,'Color','r');
        title('Slopes of CFP/YFP. Find the first reciprocal change, and double click. Red line indicates position of first fret peak.')
        hr = gca;
        
        subplot(2,2,3)
        plot(slope_diff)
        yyyL = get(gca,'YLim');
        line([T_set_time T_set_time],yyyL,'Color','r');
        title('Difference in slope between CFP and YFP')
        
        subplot(2,2,4)
        plotyy(Image_Time, del_F, Image_Time, raw_temperature)
        hold on
        plot(delta_F,'r')
        yyyyL = get(gca,'YLim');
        line([T_set_time T_set_time],yyyyL,'Color','r');
        title('Fret Signal')
        [recip_x, recip_y] = getpts(hr);
    else
        plotyy(Image_Time, del_F, Image_Time, raw_temperature)
        hold on
        plot(delta_F,'r')
        yyyyL = get(gca,'YLim');
        line([T_set_time T_set_time],yyyyL,'Color','r');
        title('Fret Signal')
        hr = gca;
        [recip_x, recip_y] = getpts(hr);
    end
    
    recip_x = round(recip_x);
    close
    [fret_pks, fret_locs] = findpeaks(del_F(recip_x:end),'minpeakheight', 0.5, 'minpeakdistance', 18);
    fret_locs = (fret_locs + recip_x)';
   
    fret(c).pks = fret_pks;
    fret(c).locs = fret_locs;
    first_fret = fret_locs(1);
    close
    
    [temp_pks, temp_locs] = findpeaks(smooth_temperature, 'minpeakdistance', 20);
    temp_pks = temp_pks(end-(length(fret_pks)-1):end);
    temp_locs = temp_locs(end-(length(fret_pks)-1):end);
    Temp(c).pks = temp_pks;
    Temp(c).locs = temp_locs;
    diffs = fret_locs - temp_locs;
    for i = 1:length(diffs)
        if diffs(i) < 0
            diffs(i) = nan;
        elseif diffs(i) > 10
            diffs(i) = nan;
        end
    end
    
    mean_peak_diff(end+1) = nanmean(diffs);
    
    if isnan(mean_peak_diff(c)) 
        mean_peak_diff(c) = 6;
    end
    
    T_star_time = round((recip_x) - mean_peak_diff(c) + 2.2);%2.2s phase lag between temp 
    T_star_temps(end+1) = raw_temperature(T_star_time);%and fret-from aravi's paper...
                                                      
    T_set_time = round(T_set_time - mean_peak_diff(c) + 2.2);                                                
    
    if T_set_time>0
        T_set_point(end+1) = raw_temperature(T_set_time);% correcting this once we have
    elseif T_set_time<=0                                 % mean_peak_diff
        T_set_point(end+1) =nan;
    end
                                                        
    T_star_temps(c)
    T_set_point(c)
    c = c + 1;
end
total_fret_amps = [];
for h = 1:length(fret)
    if length(fret(h).pks) > 4
        total_fret(h).amps = fret(h).pks(2:4)';
    elseif length(fret(h).pks) <= 4
        total_fret(h).amps = fret(h).pks(2:end)';
    end
end
if length(total_fret) > 1
    total_fret_amps = catpad(2, total_fret.amps); %catpad makes things easy here
else
    total_fret_amps = total_fret.amps(2:end);
end

k = strfind(dir_of_files, 'BLC');
%geno_name = dir_of_files(k-3:k-2);
new_file = ('T_star_numbers');
save([dir_of_files '/' new_file], 'fret', 'Temp', 'total_fret_amps', 'T_star_temps', 'mean_peak_diff');



