function D = LBCN_baseline_Timeseries(fname,prefix,method,time_win)

% Performs baseline correction on a whole time series based on its average
% or on a specific time window.
% Inputs:
% fname   :   Name of file to baseline correct
% prefix  :   Prefix for output file (default: 'b')
% method  :   Method for baseline correction (default: 'average')
% time_win:   Time window for baseline correction, in ms (default: whole file)
%--------------------------------------------------------------------------
% Written by J. Schrouff, LBCN, Stanford University, 08/22/2016

if isempty(fname)
    fname = spm_select();
end
if ischar(fname)
    D = spm_eeg_load(fname);
else
    D = fname;
end
sD = size(D);
if sD(end)~= 1 %Only one trial
    beep
    disp('Can only take whole time series')
    return
end

if isempty(prefix)
    prefix = 'b';
end

if isempty(method)
    method = 'average';
end

if isempty(time_win)
    t(1) = 1;
    t(2) = nsamples(D);
else
    t(1) = indsample(D,time_win(1)/1000);
    t(2) = indsample(D,time_win(2)/1000);
end

%-Create a copy of the dataset
%--------------------------------------------------------------------------
Dnew = copy(D, [prefix D.fname]);

%-For each channel, remove the specified baseline
%--------------------------------------------------------------------------

% Exclude artefacts
ev = D.events;
badsamp = [];
for iev = 1:length(ev)
    if ~isempty(strfind(ev(iev).type,'artefact'))
        t_art(1) = indsample(D,ev(iev).time-ev(iev).duration); % Getting excision window
        t_art(2) = indsample(D,ev(iev).time+ev(iev).duration);
        badsamp = [badsamp,t_art(1):t_art(2)];
    end
end
tw = t(1):t(2);
gs = ~ismember(tw,badsamp);
tw = tw(gs);

for j = 1:nfrequencies(D)
    for i = 1:nchannels(D)
        
        if strcmpi(method,'average')
            
            % Compute baseline without the artefacts
            if numel(sD) == 3
                baseline = mean(squeeze(D(i,tw,1)));
                % Remove baseline from signal
                Dnew(i,:,1) = D(i,:,1) - baseline;
            else
                baseline = mean(squeeze(D(i,j,tw,1)));
                % Remove baseline from signal
                Dnew(i,j,:,1) = D(i,j,:,1) - baseline;
            end
            
        elseif strcmpi(method,'logR')
            
            % Compute baseline without the artefacts
            if numel(sD) == 3
                signal = squeeze(D(i,tw,1));
                l10            = log10(signal);
                if ~isempty(find(l10==-Inf,1)) % one or more infinite values to take out
                    xbase = mean(squeeze(l10(l10~=-Inf)));
                else
                    xbase     = mean(l10);
                end
                % Remove baseline from signal
                Dnew(i,:,1) = 10*(log10(D(i,:,1)) - repmat(xbase,[1 1 Dnew.nsamples 1]));                
            else
                signal = squeeze(D(i,j,tw,1));
                l10            = log10(signal);
                if ~isempty(find(l10==-Inf,1)) % one or more infinite values to take out
                    xbase = mean(squeeze(l10(l10~=-Inf)));
                else
                    xbase     = mean(l10);
                end
                % Remove baseline from signal
                Dnew(i,j,:,1) = 10*(log10(D(i,j,:,1)) - repmat(xbase,[1 1 Dnew.nsamples 1]));
            end
            
        end
    end
end
Dnew = D;
save(Dnew);