function [def]=get_defaults_Parvizi()

% function to load default values into scripts. Those values are specific
% to the Laboratory of Behavioral and Cognitive Neuroscience (Parvizi Lab,
% Stanford University).
%--------------------------------------------------------------------------
% Written by J. Schrouff, Laboratory of Behavioral and Cognitive
% Neuroscience, Stanford University, 10/21/2014.

def = struct();

% Default sampling rates
%--------------------------------------------------------------------------
def.TDTfsample = 1525.88; % default for >2012 TDT files
def.oldNKfsample  = 1000;    % default for clinical data
def.newNKfsample  = 1000;    % default for clinical data

% Default values for pre-processing
%--------------------------------------------------------------------------
def.new_fs = 500;
def.noise_freq = 60; %default line noise
def.lineband = 3;    % band to cut around line: freq-band:freq+band
def.nharmonics = 3; %Number of harmonics including 0

% Default values for bad channel detection
% -------------------------------------------------------------------------
def.varmult = 5; % overall variance on each channel
def.stdmult = 2; % detection of 'jumps' on each channel

% Default value for event detection
% -------------------------------------------------------------------------
def.ichan = 2; % for exported edf (new NK) data, the diod should be the second channel
def.fsample_diod = 24414.1; % sampling for TDT diod
def.thresh_dur = 0; % Minimum duration of an event (in seconds)

% Default values for epoching
% -------------------------------------------------------------------------
def.fieldons = 'start'; %epoch on the stimulus onset
def.fieldbc = 'start'; %baseline correction relative to onset
def.twbc = [-200 0]; %baseline of -200 to 0 ms around onset 