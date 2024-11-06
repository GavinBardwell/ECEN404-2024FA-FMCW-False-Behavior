clear;

% Load Config File
run("radarConfigGenerator.m");
config = load('radar_config.mat');

% Primary Radar Configuration
fc = config.primary.fc;
c = 3e8;
lambda = c/fc;

range_max = config.primary.range_max;
t_max = 5.5*range2time(range_max, c);

range_res = config.primary.range_res;
bandwidth = rangeres2bw(range_res, c);
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
receiver = phased.ReceiverPreamp('Gain', rx_gain, 'NoiseFigure', rx_nf, ...
    'SampleRate', fs);

% Emission Radar Characteristics (if copy_primary is 1, inherit values from primary radar)
N_emission = length(config.emission_objects);
emission_objects = struct([]);
for i = 1:N_emission
    if config.emission_objects(i).copy_primary == 1
        emission_objects(i).fc = fc;
        emission_objects(i).range_max = range_max;
        emission_objects(i).range_res = range_res;
        emission_objects(i).v_max = v_max;
        emission_objects(i).tx_power = config.primary.tx_power;
        emission_objects(i).tx_gain = config.primary.tx_gain;
    else
        emission_objects(i).fc = config.emission_objects(i).fc;
        emission_objects(i).range_max = config.emission_objects(i).range_max;
        emission_objects(i).range_res = config.emission_objects(i).range_res;
        emission_objects(i).v_max = config.emission_objects(i).v_max;
        emission_objects(i).tx_power = config.emission_objects(i).tx_power;
        emission_objects(i).tx_gain = config.emission_objects(i).tx_gain;
    end
    
    % Generate Emission Radar Waveform
    emission_objects(i).waveform = phased.FMCWWaveform('SweepTime', t_max, 'SweepBandwidth', bandwidth, 'SampleRate', fs);
    
    % Create Platform for Emission Radar
    emission_objects(i).motion = phased.Platform('InitialPosition', config.emission_objects(i).position, 'Velocity', config.emission_objects(i).velocity);
    
    % Create Transmitter
    emission_objects(i).transmitter = phased.Transmitter('PeakPower', db2pow(emission_objects(i).tx_power) * 1e-3, 'Gain', emission_objects(i).tx_gain);

    %each emission oject requires its own seperate channel
    emission_objects(i).channel_jammer = phased.FreeSpace('PropagationSpeed', c, ...
        'OperatingFrequency', fc, 'SampleRate', fs, ...
        'TwoWayPropagation', false);
end

% Benign Objects Configuration
N_benign = length(config.benign_objects);
benign_objects = struct([]);
for i = 1:N_benign
    benign_objects(i).position = config.benign_objects(i).position;
    benign_objects(i).velocity = config.benign_objects(i).velocity;
    benign_objects(i).distance = norm(benign_objects(i).position);
    benign_objects(i).rcs = db2pow(10*log10(benign_objects(i).distance) + config.benign_objects(i).rcs_offset);
    benign_objects(i).target = phased.RadarTarget('MeanRCS', benign_objects(i).rcs, 'PropagationSpeed', c, 'OperatingFrequency', fc);
    benign_objects(i).motion = phased.Platform('InitialPosition', benign_objects(i).position, 'Velocity', benign_objects(i).velocity);

end

% Channel for Signal Propagation
%channel = phased.FreeSpace('PropagationSpeed', c, 'OperatingFrequency', fc, 'SampleRate', fs, 'TwoWayPropagation', false);

% Spectrum Analyzer for Visualization
specanalyzer = spectrumAnalyzer('SampleRate', fs, 'Method', 'welch', 'AveragingMethod', 'running', ...
    'PlotAsTwoSidedSpectrum', true, 'FrequencyResolutionMethod', 'rbw', 'Title', ...
    'Spectrum for received and dechirped signal', 'ShowLegend', true);

% Channel for Emission Signal Propagation (One-way)
emission_channel = phased.FreeSpace('PropagationSpeed', c, ...
    'OperatingFrequency', fc, 'SampleRate', fs, ...
    'TwoWayPropagation', false);

% Channel for Benign Objects (Two-way)
benign_channel = phased.FreeSpace('PropagationSpeed', c, ...
    'OperatingFrequency', fc, 'SampleRate', fs, ...
    'TwoWayPropagation', true);

% Simulation Loop
rng(2012);
Nsweep = 64;
xr = complex(zeros(tx_waveform.SampleRate * tx_waveform.SweepTime, Nsweep));
% Floor Clutter Configuration
floor_rcs = 0.5;  % Example RCS for the floor (you may adjust this based on desired noise level)
floor_pos = [0; 0; -1];  % Set floor position below radar
floor_clutter = phased.RadarTarget('MeanRCS', floor_rcs, 'PropagationSpeed', c, 'OperatingFrequency', fc);

% Simulation Loop Update
for m = 1:Nsweep
    % Existing radar position update
    [radar_pos, radar_vel] = radarmotion(t_max);
    
    % Update benign object positions as before
    for i = 1:N_benign
        [benign_objects(i).pos, benign_objects(i).vel] = benign_objects(i).motion(t_max);
    end
    
    % Radar Transmission
    sig = tx_waveform();
    txsig = transmitter(sig);
    
    % Signal Propagation and Reflection for Benign Objects (unchanged)
    total_received_sig = complex(zeros(size(txsig)));
    for i = 1:N_benign
        reflected_sig = benign_channel(txsig, radar_pos, benign_objects(i).pos, radar_vel, benign_objects(i).vel);
        reflected_sig = benign_objects(i).target(reflected_sig);
        total_received_sig = total_received_sig + reflected_sig;
    end
    
    % Emission Radar Interference (unchanged)
    for i = 1:N_emission
        [emission_pos, emission_vel] = emission_objects(i).motion(t_max);
        jammer_sig = emission_objects(i).waveform();
        jammer_txsig = emission_objects(i).transmitter(jammer_sig);
        jammer_received_sig = emission_channel(jammer_txsig, emission_pos, radar_pos, emission_vel, radar_vel);
        total_received_sig = total_received_sig + jammer_received_sig;
    end
    
    % Floor Clutter Reflection (new addition)
    %floor_reflected_sig = benign_channel(txsig, radar_pos, floor_pos, radar_vel, [0; 0; 0]);
    %floor_reflected_sig = floor_clutter(floor_reflected_sig);
    %total_received_sig = total_received_sig + floor_reflected_sig;  % Add floor clutter to received signal
    
    % Continue with dechirping and visualization as before
    dechirpsig = dechirp(total_received_sig, sig);
    specanalyzer([total_received_sig, dechirpsig]);
    xr(:, m) = dechirpsig;
end


% Estimate Range and Velocity
rngdopresp = phased.RangeDopplerResponse('PropagationSpeed', c, 'DopplerOutput', 'Speed', 'OperatingFrequency', fc, ...
    'SampleRate', fs, 'RangeMethod', 'FFT', 'SweepSlope', sweep_slope, 'RangeFFTLengthSource', 'Property', ...
    'RangeFFTLength', 2048, 'DopplerFFTLengthSource', 'Property', 'DopplerFFTLength', 256);

clf;
plotResponse(rngdopresp, xr);
axis([-v_max v_max -3 range_max]);
climVals = clim;

% Plot Range vs Power
figure;
range_power = sum(abs(xr), 2);
range_axis = linspace(0, range_max, length(range_power));
plot(range_axis, 10*log10(range_power));
xlabel('Range (m)');
ylabel('Power (dB)');
title('Range vs Power');
grid on;
% Calculate the Range-Doppler Response
rngdopresp = phased.RangeDopplerResponse('PropagationSpeed', c, ...
    'DopplerOutput', 'Speed', 'OperatingFrequency', fc, ...
    'SampleRate', fs, 'RangeMethod', 'FFT', 'SweepSlope', sweep_slope, ...
    'RangeFFTLengthSource', 'Property', 'RangeFFTLength', 2048, ...
    'DopplerFFTLengthSource', 'Property', 'DopplerFFTLength', 256);

% Generate the Range-Doppler Response Map
[response, range_grid, speed_grid] = rngdopresp(xr);