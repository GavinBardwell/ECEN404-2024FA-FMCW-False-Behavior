
% Script to Run FMCWRadarSimulation
%{
clear;
addpath('Backend');
addpath('Config_Files');
%addpath('Config_Files');
% Create an instance of FMCWRadarSimulation
radarSim = FMCWSim('best_jamming.mat');

% Load configuration file
%radarSim.loadConfig('default.mat');

% Simulate the environment
Nsweep = 128;
NFrames = 64;

%xr = radarSim.simulate(Nsweep);
%radarSim.plotRangeDoppler(xr);

xr_frames = radarSim.simulateFrames(NFrames, Nsweep);
fftFrames = radarSim.runFFTFrames(xr_frames);

radarSim.animateRangeDopplerResponse(fftFrames.resp_frames, fftFrames.rng_grid, fftFrames.dop_grid);
radarSim.animateRangeVsPower(fftFrames.resp_frames, fftFrames.rng_grid);
%}

detectFalseBehavior(fftFrames);
% Plot the waveform

%radarSim.plotWaveform(radarSim.tx_waveform());

% Plot the signal spectrum
%radarSim.plotSignalSpectrum(radarSim.tx_waveform());

% Plot the range-Doppler response

%radarSim.plotRangeDoppler(xr);

%radarSim.plotRangeVsPower();

%radarSim.plotVelocityVsPower();

%radarSim.openSpectrumAnalyzer();

%radarSim.createRangeVsPowerrVideo(xr);