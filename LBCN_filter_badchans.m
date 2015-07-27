function d = LBCN_filter_badchans(files,chanfile, bch, filter)

% This function first filters the channels for line noise + two harmonics
% using the batch 'Filter_NKnew_SPM_job.m'. It then takes the channel file
% to identify pathological channels and empty/flat electrodes. It is also
% possible manually specify which channels are bad, using their indexes 
%(typically for old NK or TDT systems). An automatic detection is then run
%for the provided sessions, based on the mean and std of the signal and on
%the detection of spikes. Important note: the resulting bad channels will
%be the union of the bad channels detected in the provided files!
% Inputs:
% files    : file names (optional)
% chanfile : name of the .mat containing channel information (can be empty)
% bch      : vector with indexes of bad channels
% filter   : flag to filter the data or not (default = 1)
% Output:
% D        : MEEG object, filtered with bad channels marked as 'bad'.
%--------------------------------------------------------------------------
% Written by J. Schrouff and S. Bickel, 07/27/2015, LBCN, Stanford

% Check inputs
% -------------------------------------------------------------------------
if nargin<1 || isempty(files)
    files = spm_select([1 Inf],'.mat', 'Select files to process',{},pwd,'.mat');
end

if nargin<2 || isempty(chanfile)
    bchfile = [];
else
    try
        load(chanfile);
        bchfile = [];
        for i  = 1:size(elecs,1) % To modify according to final .mat form and variables
            if elecs{i,3}
                bchfile = [bchfile; i];
            end
        end
    catch
        error('Could not load the channel information file, please correct')
    end
end

if nargin<3 || isempty(bch)
    bch = [];
end

if nargin <4 || isempty(filter)
    filter = 1;
end

bchfile = union(bchfile,bch);
def = get_defaults_Parvizi;

% Step 1: Filter the data using the batch
% -------------------------------------------------------------------------
d = cell(size(files,1),1);
for i = 1:size(files,1)
    if filter
        if i==1
            spm_jobman('initcfg')
            spm('defaults', 'EEG');
        end
        jobfile = {which('Filter_NKnew_SPM_job.m')};
        [out] = spm_jobman('run', jobfile,{deblank(files(i,:))});
        d{i} = out{end}.D;
    else
        d{i} = spm_eeg_load(deblank(files(i,:)));
    end
end


% Step 2: Bad channels
% -------------------------------------------------------------------------
varmult = def.varmult;
stdmult = def.stdmult;
ibadchans = [];

for i = 1:length(d)
    % Step 2.1: Set bad channels based on clinical recordings
    % ---------------------------------------------------------------------
    goodchans = setdiff(1:nchannels(d{i}), bchfile);
    
    % Step 2.2: Automatic detection of bad channels based on signal std
    % ---------------------------------------------------------------------
    vch = var(d{i}(goodchans,:),0,2); % only look at the non-pathological channels
    b = find(vch>(varmult*median(vch)));
    g = find(vch<median(vch)/varmult);
    addb = setdiff(b,g);
    if ~isempty(addb)
        disp(['Bad channels for file ', num2str(i),':', num2str(goodchans(addb))])
    else
        disp(['No bad channels for file ', num2str(i)])
    end
    ibadchans = union(ibadchans,goodchans(addb)); 
    
    % Step 2.3: Automatic detection of bad channels based on signal spikes
    % ---------------------------------------------------------------------
    std_chan = std(diff(d{i}(goodchans,:),1,2),0,2);
    std_dat = mean(std_chan);
    nr_jumps = zeros(length(goodchans),1);
    for j=1:length(goodchans)
        nr_jumps(j) = length(find(diff(d{i}(goodchans(j),:))>stdmult*std_dat)); 
    end
    jch = find(nr_jumps>mean(nr_jumps));
    if ~isempty(jch)
        addjch = goodchans(jch);
        disp(['Spiky channels for file ', num2str(i),':', num2str(addjch)])
        ibadchans = union(ibadchans,addjch); 
    else
        disp(['No spiky channels for file ', num2str(i)])
    end    
end

% Save the bad channels into the SPM header
for i= 1:length(d)
    totbad = union(bchfile,ibadchans);
    d{i} = badchannels(d{i},totbad,ones(length(totbad),1));
    save(d{i});
    if i==1
        disp(['Bad channels for all files: ', num2str(totbad')])
        chanlabels(d{i},badchannels(d{i}))
    end
end


