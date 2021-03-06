function d = LBCN_HilbertTransform(fname,bands,rescale,sc_method,sc_baseline, sc_file)

% Function to perform Hilbert transform in a specific frequency band. This
% code is using the SPM function, that can deal with either continuous or
% epoched data (calling FieldTrip).
% Inputs:
% fname      : name of file(s) (SPM format) to decompose
% bands      : matrix of frequency bands to look at, e.g. [30 180; 1 4]
% rescale    : rescale (1) or not (default:0)
% sc_method  : rescaling method, either 'log','logR','zscore','diff','rel',
%              'sqrt' (see SPM12)
% sc_baseline: time window for baseline correction (based on event onset)
% sc_file    : file to compute baseline from (if different then specified file)
% Outputs:
% d: files containing the time frequency decomposition for all channels
% -------------------------------------------------------------------------
% Written by J. Schrouff, LBCN, 07/31/2015

% Get inputs
% -------------------------------------------------------------------------
def = get_defaults_Parvizi;

if nargin <1 || isempty(fname)
    fname = spm_select(inf,'.mat', 'Select file to decompose',[],pwd,'.mat');
end

if nargin <2 || isempty(bands)
    bands = def.bands;
end

if nargin <3 || isempty(rescale)
    rescale = 0;  % rescale TF
end

list_methods = def.listrescale;
if nargin<4 || isempty(sc_method)
    sc_method = 'log';
elseif isempty(find(strcmpi(sc_method,list_methods),1))
    disp('Scaling method not supported')
    disp('Exiting')
elseif strcmpi(sc_method,'LogR') || strcmpi(sc_method,'Diff') || ...
                strcmpi(sc_method,'Rel') || strcmpi(sc_method,'Zscore')
            if nargin<5 || isempty(sc_baseline)
                sc_baseline = def.sc_baseline;
            end
            if nargin<6 || isempty(sc_file)
                sc_file = def.sc_file;
            elseif size(sc_file,1) == 1 && size(fname,1)>1
                %repeat baseline file for all TF computed
                sc_file = repmat(sc_file,size(fname,1),1);
            end            
end

% Use SPM batch to compute Hilbert Transform
% -------------------------------------------------------------------------
fc = zeros(1,size(bands,1));
width = zeros(1,size(bands,1));
% Compute central frequency and band width
for i = 1: size(bands,1)
    fc(i) = round((bands(i,1)+bands(i,2))/2);
    width(i) = max(abs(bands(i,1)-fc(i)),abs(bands(i,2)-fc(i)));
end
d = cell(size(fname,1),1);
for i = 1:size(fname,1)
    % inputs for the batch
    input_array{1} = width;
    input_array{2} = fc;
    input_array{3} = {deblank(fname(i,:))};
    [matlabbatch] = batch_job(input_array);
    % run batch for Hilbert transform
    if i == 1
        spm_jobman('initcfg')
        spm('defaults', 'EEG');
    end
    [out] = spm_jobman('run', matlabbatch);
    d{i} = out{1}.Dtf;
    
    %rescale file if specified
    if rescale
        input_array{1} = {fullfile(d{i}.path,d{i}.fname)};
        input_array{2} = sc_method;
        if strcmpi(sc_method,'LogR') || strcmpi(sc_method,'Diff') || ...
                strcmpi(sc_method,'Rel') || strcmpi(sc_method,'Zscore') 
            input_array{3} = sc_baseline;
            if ~isempty(sc_file)
                input_array{4} = sc_file(i,:); % one file submitted per TF computed
            else
                input_array{4} = [];
            end
        end
        [matlabbatch] = batch_rescale_job(input_array);
        [out] = spm_jobman('run', matlabbatch);
        d{i} = out{1}.D;
    end
    
end



function [matlabbatch] = batch_job(input_array)
% -------------------------------------------------------------------------
matlabbatch{1}.spm.meeg.tf.tf.D = input_array{3};
matlabbatch{1}.spm.meeg.tf.tf.channels{1}.all = 'all';
matlabbatch{1}.spm.meeg.tf.tf.frequencies = input_array{2};
matlabbatch{1}.spm.meeg.tf.tf.timewin = [-Inf Inf];
matlabbatch{1}.spm.meeg.tf.tf.method.hilbert.freqres = input_array{1};
matlabbatch{1}.spm.meeg.tf.tf.method.hilbert.filter.type = 'but';
matlabbatch{1}.spm.meeg.tf.tf.method.hilbert.filter.dir = 'twopass';
matlabbatch{1}.spm.meeg.tf.tf.method.hilbert.filter.order = 3;
matlabbatch{1}.spm.meeg.tf.tf.method.hilbert.polyorder = 1;
matlabbatch{1}.spm.meeg.tf.tf.method.hilbert.subsample = 1;
matlabbatch{1}.spm.meeg.tf.tf.phase = 1;
matlabbatch{1}.spm.meeg.tf.tf.prefix = '';


function [matlabbatch] = batch_rescale_job(input_array)
% -------------------------------------------------------------------------
matlabbatch{1}.spm.meeg.tf.rescale.D = input_array{1};
matlabbatch{1}.spm.meeg.tf.rescale.prefix = 'r';

if strcmpi(input_array{2},'logR')
    matlabbatch{1}.spm.meeg.tf.rescale.method.LogR.baseline.timewin = input_array{3};
    matlabbatch{1}.spm.meeg.tf.rescale.method.LogR.baseline.Db = input_array{4};
elseif strcmpi(input_array{2},'diff')
    matlabbatch{1}.spm.meeg.tf.rescale.method.Diff.baseline.timewin = input_array{3};
    matlabbatch{1}.spm.meeg.tf.rescale.method.Diff.baseline.Db = input_array{4};
elseif strcmpi(input_array{2},'rel')
    matlabbatch{1}.spm.meeg.tf.rescale.method.Rel.baseline.timewin = input_array{3};
    matlabbatch{1}.spm.meeg.tf.rescale.method.Rel.baseline.Db = input_array{4};
elseif strcmpi(input_array{2},'zscore')
    matlabbatch{1}.spm.meeg.tf.rescale.method.Zscore.baseline.timewin = input_array{3};
    matlabbatch{1}.spm.meeg.tf.rescale.method.Zscore.baseline.Db = input_array{4};
elseif strcmpi(input_array{2},'log')
    matlabbatch{1}.spm.meeg.tf.rescale.method.Log = 1;
elseif strcmpi(input_array{2},'logeps')
    matlabbatch{1}.spm.meeg.tf.rescale.method.Logeps = 1;
elseif strcmpi(input_array{2},'sqrt')
    matlabbatch{1}.spm.meeg.tf.rescale.method.Sqrt = 1;   
end







