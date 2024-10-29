
% Script to Run FMCWRadarSimulation
clear;
% Create an instance of FMCWRadarSimulation
radarSim = FMCWSim();

% Load configuration file
radarSim.loadConfig('radar_config.mat');

% Simulate the environment
Nsweep = 64;
xr = radarSim.simulateEnvironment(Nsweep);

% Plot the waveform
radarSim.plotWaveform(radarSim.tx_waveform());

% Plot the signal spectrum
radarSim.plotSignalSpectrum(radarSim.tx_waveform());

% Plot the range-Doppler response
radarSim.plotRangeDopplerResponse(xr);
