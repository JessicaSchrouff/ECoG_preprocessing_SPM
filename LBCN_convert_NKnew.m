
function [D] = LBCN_convert_NKnew(fname, path_save)
% Function to convert NK data from edf to SPM format. It takes as inputs
% the name of the file (optional) and the path where to save the converted
% data (optional).
% It creates a downsampled version of the signal, in SPM
% .dat and .mat format. Additionally, it creates a separate file for the
% microphone and another for the diod, which are not downsampled or
% filtered.
% Multiple files can be selected, the code will generate sub-directories
% for each 'block'.
% All parameters can be modified by opening (GUI) the corresponding batches:
% conversion: 'Convert_NKnew_to_SPMfa_job.m'
% downsample: 'Downsample_NKnew_SPM_job.m'
%--------------------------------------------------------------------------
%Written by J. Schrouff, LBCN, Stanford, 07/21/2015


% Inputs
if nargin<1 || isempty(fname)
    fname = spm_select(inf,'any','Select file to convert');
end
if nargin<2 || isempty(path_save)
    path_save = spm_select(1,'dir','Select directory where to save the data');
end

% For each file
for id = 1:size(fname,1)
    % Step 1: Anonymize edf files
    %--------------------------------------------------------------------------
    
    edfhdr=edf_hdr_reader(fname(id,:));
    % PatientID
    try
        [patID_last,patID_first]=strtok(edfhdr.orig.PatientID',',');
        if ~isempty(patID_first)
            patID_first=strtrim(patID_first(2:end));
            edfhdr.orig.PatientID=[patID_first(1:2) patID_last(1:2) blanks(76)]';
        elseif strfind(patID_last, 'No_Name')
            edfhdr.orig.PatientID=['Patient' blanks(73)]';
        else
            edfhdr.orig.PatientID=[patID_last(1:2) blanks(78)]';
        end
    catch
        error('Something went wrong when attempting to anonymize Patient ID. Exiting here.');
    end
    % RecordID
    try
        edfhdr.orig.RecordID=blanks(80);
    catch
        error('Something went wrong when attempting to anonymize Record ID. Exiting here.');
    end
    edf_hdr_writer(fname(id,:),edfhdr,'orig');
    
    % Step 2: Convert data from edf to SPM format
    %--------------------------------------------------------------------------
    
    % Get which channels are ECoG/EEG, which is diod, which is mike
    list= edfhdr.Labels;
    eeglab = {};
    idc=[];
    ielec=[];
    label = {};
    labeldc = {};
    % Get the channel labels
    for i =1:length(list)
        nel = char(list{i});
        if strfind(nel,'DC') % All DC channels in one file
            idc=[idc,i];
            labeldc = [labeldc,list{i}];
        else
            poli = strfind(nel,'POL');
            itk = setdiff(1:length(nel),poli:poli+3);
            ref = strfind(nel,'-Ref');
            itr = setdiff(1:length(nel),ref:ref+3);
            elecnam = nel(intersect(itk,itr));
            eeglab = [eeglab,{elecnam}];
            ielec=[ielec;i];
            label = [label,list{i}];
        end
    end
    
    if size(fname,1)>1
        % Create subdirectory for each file
        mkdir(path_save,['Block_', num2str(id)])
        path_block = [path_save,filesep,['Block_', num2str(id)]];
    else
        path_block = path_save;
    end
    save(fullfile(path_block,'Channel_Labels.mat'),'label');
    labelsdc = labeldc;
    label = labeldc;
    save(fullfile(path_block,'DCchannel_Labels.mat'),'label');
    
    % Create ECoG file
    jobfile = {which('Convert_NKnew_to_SPMfa_job.m')};
    spm_jobman('initcfg')
    spm('defaults', 'EEG');
    [path,name,ext] = spm_fileparts(fname(id,:));
    spmname = fullfile(path_block,['ECoG_',name,ext]);
    input_array{1} = {fname(id,:)};
    input_array{2} = {fullfile(path_block,'Channel_Labels.mat')};
    input_array{3} = spmname;
    [out] = spm_jobman('run', jobfile,input_array{:});
    D = out{1}.D;
    D = chantype(D,1:length(ielec),'EEG');
    D = chanlabels(D,1:length(ielec),eeglab);
    save(D);
    
    % Create diod file
    if ~isempty(idc)
        jobfile = {which('Convert_NKnew_to_SPMfa_job.m')};
        diodname = fullfile(path_block,['DCchans_',name,ext]);
        input_array{1} = {fname(id,:)};
        input_array{2} = {fullfile(path_block,'DCchannel_Labels.mat')};
        input_array{3} = diodname;
        [out] = spm_jobman('run', jobfile, input_array{:});
        Ddiod = out{1}.D;
        Ddiod = chantype(Ddiod,1:length(idc),'Other');
        Ddiod = chanlabels(Ddiod,1:length(idc),labelsdc);
        save(Ddiod);
        clear Ddiod
    end
    
    
    % Step 3: Downsample ECoG data to 1000Hz
    %--------------------------------------------------------------------------
    jobfile = {which('Downsample_NKnew_SPM_job.m')};
    namef = fullfile(path_block,D.fname);
    [out]=spm_jobman('run', jobfile, {namef});
    D = out{1}.D;
end




