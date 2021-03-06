function [res] = LBCN_Univariate_Condition_Compare(fname,cond,twcond,cond2,twcond2,ichan, nperm,suffix,tail)

% Function to perform univariate paired of trial (de-)activation compared
% to baseline, in a specific condition.
% Inputs:
% - fname: File name
% - cond: condition name for category 1, in character or cell array
% - twcond: time window to select for the condition (in ms)
% - cond2: condition name for category 2, in character or cell array
% - twcond2: time window to select for the second condition (in ms)
% - ichan: channels (names in a cell, indexes or 'good') to perform the test on
% - nperm: number of permutations (default: 10,000)
% - suffix: to append to name of saved results file (default: [])
% - tail: if tail is one, testing for cond1>cond2, otherwise testing
% cond1~=cond2.
% -------------------------------------------------------------------------
% Written by J. Schrouff, LBCN, Stanford University, 12/10/2015


if nargin<1 || isempty(fname)
    fname = spm_select(1,'mat','Select MEEG object');
end

D = spm_eeg_load(fname);

icond = setdiff(indtrial(D,cond),badtrials(D));
icond2 = setdiff(indtrial(D,cond2),badtrials(D));

if isempty(icond)
    disp('Please provide valid condition name for condition 1')
    return
end

if isempty(icond2)
    disp('Please provide valid condition name for condition 2')
    return
end

itpcond = indsample(D,twcond/1000);
itpcond2 = indsample(D,twcond2/1000);

if isempty(itpcond)
    disp('Please provide valid time window for condition (in ms)')
    return
end

if isempty(itpcond2)
    disp('Please provide valid time window for baseline (in ms)')
    return
end

if nargin<5 || isempty(ichan)
    ichan = 1:D.nchannels;
elseif iscell(ichan)
    ichan = indchannel(D,ichan);
elseif strcmpi(ichan,'good')
    ichan = indchantype(D,'All','good');
end

if nargin<6 || isempty(nperm)
    nperm = 10000;
end

if nargin<7 || isempty(suffix)
    suffix = '';
end

if nargin<8 || isempty(tail)
    tail = 0;
end

permutation = zeros(numel(icond)+numel(icond2),nperm);
pchan_Cond = zeros(numel(ichan),1);
pchan_WSR = zeros(numel(ichan),1);
differences = zeros(numel(ichan),1);
% Compute permutations for each channel (same permutations)
fprintf(['Computing for channel (out of %d):',repmat(' ',1,ceil(log10(length(ichan)))),'%d'],numel(ichan), 1);

for i = 1:length(ichan)
    % Counter of channels to be updated
    if i>1
        for idisp = 1:ceil(log10(i)) % delete previous counter display
            fprintf('\b');
        end
        fprintf('%d',i);
    end
    conddata = mean(squeeze(D(ichan(i),itpcond,icond)));
    cond2data = mean(squeeze(D(ichan(i),itpcond2,icond2)));
    if tail
        truediff = median(conddata) - median(cond2data);
    else
        truediff = abs(median(conddata) - median(cond2data));
    end
    alldata = [conddata';cond2data'];
    pchan_WSR(i) = ranksum(conddata,cond2data);
    perm = zeros(numel(alldata),nperm);
    permdiff = zeros(nperm,1);
    differences(i) = truediff;
    for p = 1:nperm
        if i == 1
            % Need to set the permutation matrix
            indperm = randperm(numel(alldata));
            permutation(:,p) = indperm;
        end
        perm(:,p) =  permutation(:,p);       
        permconds = alldata(perm(1:numel(conddata),p));
        permcond2 = alldata(perm(numel(conddata)+1:numel(alldata),p));
        if tail
            permdiff(p) = median(permconds) - median(permcond2);
        else
            permdiff(p) = abs(median(permconds) - median(permcond2));
        end
    end
    permdiff = [permdiff;truediff];
    pchan_Cond(i) = length(find(permdiff>=truediff))/(nperm + 1);
end
fprintf('\n');

% Correct for multiple comparisons using FDR
[crit_pCond,hCond] = LBCN_FDRcorrect(pchan_Cond);

% Save results
sign_chans = chanlabels(D,ichan(find(hCond)));
path = spm_fileparts(fname);
res.sign_chans = sign_chans;
res.pchan_Cond = pchan_Cond;
res.pchan_WSR = pchan_WSR;
res.hCond = hCond;
res.crit_pCond = crit_pCond;
res.ichan = ichan;
res.values = differences;
save([path,filesep,'Results_Univariate_ResponsiveChannels_',char(cond{1}),'_',char(cond2{1}),suffix,'.mat'],'res')


