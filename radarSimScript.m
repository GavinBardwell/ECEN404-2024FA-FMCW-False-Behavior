clear;

% Load Config File
%run("radarConfigGenerator.m");
config = load('radar_config.mat');

% Primary Radar Configuration
fc = config.primary.fc;
c = 3e8;
lambda = c/fc;

range_max = config.primary.range_max;
t_max = 5.5*range2time(range_max, c);

range_res = config.primary.range_res;
bandwidth = rangeres2bw(range_res,c);
sweep_slope = bandwidth/t_max;

v_max = config.primary.v_max;
fd_max = speed2dop(2*v_max, lambda);
fr_max = range2beat(range_max, sweep_slope, c);
fb_max = fr_max + fd_max;

fs = max(2*fb_max, bandwidth);

% Antenna Parameters
ant_aperture = config.primary.ant_aperture;
ant_gain = aperture2gain(ant_aperture, lambda);  % in dB

% Transmitter and Receiver Parameters
tx_ppower = db2pow(config.primary.tx_power) * 1e-3;  % in watts
tx_gain = config.primary.tx_gain + ant_gain;  % in dB

rx_gain = config.primary.rx_gain + ant_gain;  % in dB
rx_nf = config.primary.rx_nf;  % in dB

% Create Primary Radar Waveform
tx_waveform = phased.FMCWWaveform('SweepTime', t_max, 'SweepBandwidth', bandwidth, ...
    'SampleRate', fs);

% Create Primary Radar Motion
radar_speed = 0;
radarmotion = phased.Platform('InitialPosition', [0; 0; 0], 'Velocity', [radar_speed; 0; 0]);

% Generate and Plot Initial Waveform
sig = tx_waveform();
figure;
subplot(211); plot(0:1/fs:t_max-1/fs, real(sig));
xlabel('Time (s)'); ylabel('Amplitude (v)');
title('FMCW signal'); axis tight;
subplot(212); spectrogram(sig, 32, 16, 32, fs, 'yaxis');
title('FMCW signal spectrogram');

% Receiver and Transmitter
transmitter = phased.Transmitter('PeakPower', tx_ppower, 'Gain', tx_gain);
receiver = phased.ReceiverPreamp('Gain', rx_gain, 'NoiseFigure', rx_nf, 'SampleRate', fs);

% Emission Radar Characteristics (if copy_primary is 1, inherit values from primary radar)
N_emission = length(config.emission_objects);
emission_objects = cell(1, N_emission);
for i = 1:N_emission
    if config.emission_objects(i).copy_primary == 1
        emission_objects{i}.fc = fc;
        emission_objects{i}.range_max = range_max;
        emission_objects{i}.range_res = range_res;
        emission_objects{i}.v_max = v_max;
        emission_objects{i}.tx_power = config.primary.tx_power;
        emission_objects{i}.tx_gain = config.primary.tx_gain;
    else
        emission_objects{i}.fc = config.emission_objects(i).fc;
        emission_objects{i}.range_max = config.emission_objects(i).range_max;
        emission_objects{i}.range_res = config.emission_objects(i).range_res;
        emission_objects{i}.v_max = config.emission_objects(i).v_max;
        emission_objects{i}.tx_power = config.emission_objects(i).tx_power;
        emission_objects{i}.tx_gain = config.emission_objects(i).tx_gain;
    end
    
    % Generate Emission Radar Waveform
    emission_objects{i}.waveform = phased.FMCWWaveform('SweepTime', t_max, 'SweepBandwidth', bandwidth, 'SampleRate', fs);
    
    % Create Platform for Emission Radar
    emission_objects{i}.motion = phased.Platform('InitialPosition', config.emission_objects(i).position, 'Velocity', config.emission_objects(i).velocity);
    
    % Create Transmitter
    emission_objects{i}.transmitter = phased.Transmitter('PeakPower', db2pow(emission_objects{i}.tx_power) * 1e-3, 'Gain', emission_objects{i}.tx_gain);
end

% Benign Objects Configuration
N_benign = length(config.benign_objects);
benign_objects = cell(1, N_benign);
for i = 1:N_benign
    benign_objects{i}.position = config.benign_objects(i).position;
    benign_objects{i}.velocity = config.benign_objects(i).velocity;
    benign_objects{i}.rcs = db2pow(config.benign_objects(i).rcs);
    
    benign_objects{i}.target = phased.RadarTarget('MeanRCS', benign_objects{i}.rcs, 'PropagationSpeed', c, 'OperatingFrequency', fc);
    benign_objects{i}.motion = phased.Platform('InitialPosition', benign_objects{i}.position, 'Velocity', benign_objects{i}.velocity);
end

% Channel for Signal Propagation
channel = phased.FreeSpace('PropagationSpeed', c, 'OperatingFrequency', fc, 'SampleRate', fs, 'TwoWayPropagation', true);

% Spectrum Analyzer for Visualization
specanalyzer = spectrumAnalyzer('SampleRate', fs, 'Method', 'welch', 'AveragingMethod', 'running', 'PlotAsTwoSidedSpectrum', true, 'FrequencyResolutionMethod', 'rbw', 'Title', 'Spectrum for received and dechirped signal', 'ShowLegend', true);

% Simulation Loop
rng(2012);
Nsweep = 64;
xr = complex(zeros(tx_waveform.SampleRate * tx_waveform.SweepTime, Nsweep));

for m = 1:Nsweep
    % Update Radar Position
    [radar_pos, radar_vel] = radarmotion(t_max);
    
    % Update Benign Object Positions
    for i = 1:N_benign
        [benign_objects{i}.pos, benign_objects{i}.vel] = benign_objects{i}.motion(t_max);
    end
    
    % Radar Transmission
    sig = tx_waveform();
    txsig = transmitter(sig);
    
    % Signal Propagation and Reflection
    total_received_sig = complex(zeros(size(txsig)));
    for i = 1:N_benign
        reflected_sig = channel(txsig, radar_pos, benign_objects{i}.pos, radar_vel, benign_objects{i}.vel);
        reflected_sig = benign_objects{i}.target(reflected_sig);
        total_received_sig = total_received_sig + reflected_sig;
    end
    
    % Emission Radar Interference
    for i = 1:N_emission
        [emission_pos, emission_vel] = emission_objects{i}.motion(t_max);
        jammer_sig = emission_objects{i}.waveform();
        jammer_txsig = emission_objects{i}.transmitter(jammer_sig);
        jammer_received_sig = channel(jammer_txsig, emission_pos, radar_pos, emission_vel, radar_vel);
        total_received_sig = total_received_sig + jammer_received_sig;
    end
    
    % Dechirp the Received Signal
    dechirpsig = dechirp(total_received_sig, sig);
    
    % Visualization
    specanalyzer([total_received_sig, dechirpsig]);
    
    % Store Dechirped Signal
    xr(:, m) = dechirpsig;
end

% Estimate Range and Velocity
rngdopresp = phased.RangeDopplerResponse('PropagationSpeed', c, 'DopplerOutput', 'Speed', 'OperatingFrequency', fc, 'SampleRate', fs, 'RangeMethod', 'FFT', 'SweepSlope', sweep_slope, 'RangeFFTLengthSource', 'Property', 'RangeFFTLength', 2048, 'DopplerFFTLengthSource', 'Property', 'DopplerFFTLength', 256);

clf;
plotResponse(rngdopresp, xr);
axis([-v_max v_max 0 range_max]);
climVals = clim;
