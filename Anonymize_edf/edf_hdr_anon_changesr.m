% This script opens a .edf (European Data Format) file and allows you to:
% - anonymize the file (altering PatientID and RecordID fields)
% - manually set the sampling rate
% then saves the header (overwriting the edf file).
%
% Filename: full path and name of file to open.
% Sampling rate: desired sampling rate.
% This script is intended to correct a problem with the edf export function
% of 256-channel data sets from Natus Neuroworks database.
%
% author of this script: pierre.megevand@gmail.com
% 2014/01/28
% updates:
% 2014/04/21: corrected a bug in the sampling rate correction section

%% get file name GUI
if ~exist('directory','var')
    [filename,directory]=uigetfile('*.edf','select EDF file');
else
    [filename,directory]=uigetfile([directory '*.edf'],'select EDF file');
end
fullfilename=fullfile(directory,filename);

disp('Now working on file:');
disp(['   ' fullfilename]);

%% read edf header
edfhdr=edf_hdr_reader(fullfilename);

% set header change flag to false
edfhdr_change=false;

%% anonymize part

% display current PatientID, RecordID
disp(['Patient ID: ' edfhdr.orig.PatientID']);
disp(['Record ID: ' edfhdr.orig.RecordID']);

anonloop=true;
while anonloop
    anon=input('Would you like to anonymize the file? [y/n] ','s');
    switch anon
        case 'y'
            % PatientID
            try
                [patID_last,patID_first]=strtok(edfhdr.orig.PatientID',',');
                patID_first=strtrim(patID_first(2:end));
                edfhdr.orig.PatientID=[patID_first(1:2) patID_last(1:2) blanks(76)]';
                edfhdr_change=true;
                anonloop=false;
            catch
                error('Something went wrong when attempting to anonymize Patient ID. Could it be anonymized already? Exiting here.');
            end
            % RecordID
            try
                edfhdr.orig.RecordID(11:13)=blanks(3);
                edfhdr_change=true;
                anonloop=false;
            catch
                error('Something went wrong when attempting to anonymize Record ID. Could it be anonymized already? Exiting here.');
            end
            
        case 'n'
            disp('Not anonymizing the file.');
            edfhdr_change=false;
            anonloop=false;
        otherwise
            warning('Sorry, I did not get that.');
    end
end

if edfhdr_change
    % save header
    disp('Saving changes so far...');
    edf_hdr_writer(fullfilename,edfhdr,'orig');
    edfhdr_change=false;
end

%% sampling rate part

% display current sampling rate
if numel(unique(edfhdr.SamplingRate))==1
    disp(['Current sampling rate: ' num2str(edfhdr.SamplingRate(1)) ' Hz.']);
else
    error('There is more than 1 sampling rate across channels. Exiting here.');
end

samplingrateloop=true;
while samplingrateloop
    samplingrate=input('Would you like to edit the sampling rate? [y/n] ','s');
    switch samplingrate
        case 'y'
            samplingrateloop=false;
                        
            % request user input: sampling rate
            samplingrateinputloop=true;
            while samplingrateinputloop
                sr=input('Desired sampling rate in Hz: [e.g. 512 for Natus 256-channel data] ');
                if sr<=0
                    warning('Sampling rate cannot be <=0 Hz. Please input desired sampling rate again.');
                else
                    if sr/fix(sr)~=1
                        notroundloop=true;
                        while notroundloop
                            warning('Sampling rate is not a round number. Are you sure?');
                            notround=input('[y/n] ','s');
                            switch notround
                                case 'y'
                                    disp('Got it. Working with non-round sampling rate.');
                                    notroundloop=false;
                                    samplingrateinputloop=false;
                                case 'n'
                                    disp('Got it. Please input desired sampling rate again.');
                                    notroundloop=false;
                                otherwise
                                    warning('Sorry, I didn''t get that.');
                            end
                        end
                    else
                        samplingrateinputloop=false;
                    end
                end
            end
            % compute the value of DurDataRecord necessary to reach the desired sr
            % don't need to check again for the uniqueness of the NumSamples field;
            % this was taken care of when examining the uniqueness of sampling
            % rates above
            edfhdr.DurDataRecord=edfhdr.NumSamples{1}/sr;
            edfhdr.orig.DurDataRecord=num2str(edfhdr.DurDataRecord,8)';
            if numel(edfhdr.orig.DurDataRecord)<8
                edfhdr.orig.DurDataRecord=[edfhdr.orig.DurDataRecord' blanks(8-numel(edfhdr.orig.DurDataRecord))]';
            end
            edfhdr_change=true;
        case 'n'
            disp('Not changing the sampling rate.');
            samplingrateloop=false;
            edfhdr_change=false;
        otherwise
            warning('Sorry, I didn''t get that.');
    end
end

if edfhdr_change
    % save header
    disp('Saving changes so far...');
    edf_hdr_writer(fullfilename,edfhdr,'orig');
    edfhdr_change=false;
end

%% the end
disp('You''ve reached the end of this script. Thank you.');


