function D = LBCN_epoch_bc(fname,evt,indc,fieldons,twepoch,bc,fieldbc,twbc)

% Function to epoch the data, either raw signal or TF.
% Inputs:
% fname   : name of the file to epoch
% evt     : name of the file containing the event information
% indc    : index of the categories to look at (default: all)
% fieldons: name of the field in events.mat to epoch from
% twepoch : time window for the epoch (e.g. [0 1000], in ms)
% bc      : apply baseline correction (1) or not (0, default)
% fieldbc : which field of events.mat to use for baseline correction
% twbc    : time window for baseline correction (e.g. [-200, 0], in ms)
% Outputs:
% D       : epoched (and baseline corrected) SPM object contraining the
%           signal
%--------------------------------------------------------------------------
% Written by J. Schrouff, Laboratory of Behavioral and Cognitive
% Neuroscience, Stanford University, 07/29/2015

% Step 1: get inputs and default values
% -------------------------------------------------------------------------
def = get_defaults_Parvizi;

if nargin <1 || isempty(fname)
    fname = spm_select(1,'.mat','Select file to epoch',[],pwd,'.mat');
end
D = spm_eeg_load(fname);

if nargin<2 || isempty(evt)
    evt = spm_select(1,'.mat','Select event file',[],pwd,'.mat');
end
load(evt,'events');
evt = events;
if ~isfield(evt,'categories')
    disp('Event file should be in Parvizi format, exiting.')
    return
end

if nargin<3 || isempty(indc)
    indc = 1:length(evt.categories); % default: look at all categories
end

if nargin<3 || isempty(fieldons)
    fieldons = def.fieldons;         % default: epoch on onsets
else
    if ~isfield(evt.categories(indc(1)),fieldons)
        disp('The field chosen to define onsets does not exist in event file')
        disp('Exiting.')
        return
    end
end

if nargin<4 || isempty(twepoch)     
    twepoch(1) = 0;                 % default: mean of the RTs
    twepoch(2) = mean([evt.categories(indc).RT]);
end

if nargin<5 || isempty(bc)
    bc = 0;                         % default: no baseline correction
elseif bc == 1
    if nargin<6 || isempty(fieldbc)
        fieldbc = def.fieldbc;      % default: baseline correction on onset
    else
        if ~isfield(evt.categories(indc(1)),fieldbc)
            disp('The field chosen to define the baseline does not exist in event file')
            disp('Exiting.')
            return
        end
    end
    if nargin<7 || isempty(twbc)
        twbc = def.twbc;            % default: [-200 0]ms baseline
    end
end

% Step 2: Compute the events onsets and baseline correction windows
% -------------------------------------------------------------------------

trl = [];
bctrl = [];
evtspm = [];
conditionlabels = [];
for i = 1:length(indc)
    eval('nevc = events.categories(indc(i)).fieldons;')
    if isempty(nevc) % No information for this category
        continue
    end
    if bc
        eval('nebc = events.categories(indc(i)).fieldbc;')
        if length(nevc) ~= length(nebc)
            disp('Not the same number of values for event onset and baseline correction')
            disp('Exiting')
            return
        end
    end
    for j = 1:length(nevc)
        ons = indsample(D,nevc(j) + (twepoch(1)/1000));
        off = indsample(D,nevc(j) + (twepoch(2)/1000));
        trl = [trl; [ons, off]];
        if bc
            bc1 = indsample(D,nebc(j)+(twbc(1)/1000));
            bc2 = indsample(D,nebc(j)+(twbc(2)/1000));
            bctrl = [bctrl; [bc1, bc2]];
        end
    end
    aa = events.categories(indc(i));
    tempevt = struct('type',repmat({aa.name},1,aa.numEvents),...
            'value',num2cell(aa.stimNum),...
            'time',num2cell(aa.start),...
            'duration',num2cell(aa.duration),...
            'offset',repmat({0},1,aa.numEvents));
    evtspm = [evtspm , tempevt];
    conditionlabels = [conditionslabels; repmat({aa.name}, 1, length(nevc))];
end

inbounds = (trl(:,1)>=1 & trl(:, 2)<=D.nsamples);

rejected = find(~inbounds);
rejected = rejected(:)';

if ~isempty(rejected)
    trl = trl(inbounds, :);
    conditionlabels = conditionlabels(inbounds);
    warning([D.fname ': Events ' num2str(rejected) ' not extracted - out of bounds']);
end

ntrial = size(trl, 1);
nsampl = unique(round(diff(trl, [], 2)))+1;
D = events(D,1,evtspm);

% Generate new MEEG object with new filenames
% -------------------------------------------------------------------------
if isTF
    Dnew = clone(D, ['e' fname(D)], [D.nchannels, D.nfrequencies, nsampl, ntrial]);
else
    Dnew = clone(D, ['e' fname(D)], [D.nchannels, nsampl, ntrial]);
end

Dnew = timeonset(Dnew, timeOnset);
Dnew = type(Dnew, 'single');

% Step 3: epoch and baseline correct signal
% -------------------------------------------------------------------------

for i = 1:ntrial
    if isTF
        d = D(:, :, trl(i, 1):trl(i, 2), 1);
        Dnew(:, :, :, i) = d;
    else
        d = D(:, trl(i, 1):trl(i, 2), 1);
        
        if bc
            mbaseline = mean(D(:, bctrl(i, 1):bctrl(i, 2)), 2);
            d = d - repmat(mbaseline, 1, size(d, 2));
        end
        
        Dnew(:, :, i) = d;
    end
    
    Dnew = events(Dnew, i, select_events(D.events, ...
        [trl(i, 1)/D.fsample  trl(i, 2)/D.fsample]));
    
    if ismember(i, Ibar), spm_progress_bar('Set', i); end
end

Dnew = conditions(Dnew, ':', conditionlabels);
Dnew = trialonset(Dnew, ':', trl(:, 1)./D.fsample+D.trialonset);


%-Save new evoked M/EEG dataset
%--------------------------------------------------------------------------
D = Dnew;
save(D);




%==========================================================================
function event = select_events(event, timeseg)
% Utility function to select events according to time segment

if ~isempty(event)
    [time,ind] = sort([event(:).time]);

    selectind  = ind(time >= timeseg(1) & time <= timeseg(2));

    event      = event(selectind);
end


