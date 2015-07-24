% List of open inputs
% Conversion: File Name - cfg_files
% Conversion: Channel file - cfg_files
% Conversion: Output filename - cfg_entry
nrun = X; % enter the number of runs here
jobfile = {'C:\Users\parvizilab\Codes\codes\preprocess_pipeline\Convert_NKnew_to_SPMfa_job.m'};
jobs = repmat(jobfile, 1, nrun);
inputs = cell(3, nrun);
for crun = 1:nrun
    inputs{1, crun} = MATLAB_CODE_TO_FILL_INPUT; % Conversion: File Name - cfg_files
    inputs{2, crun} = MATLAB_CODE_TO_FILL_INPUT; % Conversion: Channel file - cfg_files
    inputs{3, crun} = MATLAB_CODE_TO_FILL_INPUT; % Conversion: Output filename - cfg_entry
end
spm('defaults', 'EEG');
spm_jobman('run', jobs, inputs{:});
