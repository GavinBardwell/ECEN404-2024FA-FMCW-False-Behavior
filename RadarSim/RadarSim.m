%using fmcw{radar/example)
%DEFINE PRAMATERS
%
clear;
fc = 77e9;
c = 3e8;
lambda = c/fc;

%configure the max range for the radar... allows for more precise results
%and upper limit of what we should measure
range_max = 200;
t_max = 5.5*range2time(range_max, c);

%define the bandwidth 
%current example is given a resolution and then calculates bandwidth and
%sweep slope change
range_res = 1;
bandwidth = rangeres2bw(range_res,c);
sweep_slope = bandwidth/t_max;


%calculate max beat frequency for range
fr_max = range2beat(range_max, sweep_slope, c);
%calculate max beat frequency for doppler must give max expected velocity
v_max = 230*1000/3600;%200km/hr
fd_max = speed2dop(2*v_max, lambda);
fb_max = fr_max + fd_max;

%pick the sample rate o greate of bandwidth or beat frequency
fs = max(2*fb_max, bandwidth);

%PARAMETERS DEFINE DONE
%CREATE TRANSMITTED WAVEFORM
tx_waveform = phased.FMCWWaveform('SweepTime',t_max, 'SweepBandwidth', bandwidth ,...
    'SampleRate', fs);

%generate radar movement
radar_speed = 0;%100*1000/3600;
radarmotion = phased.Platform('InitialPosition',[0;0;0],...
    'Velocity',[radar_speed;0;0]);
%USED TO GENERATE TRANSMITTED WAVEFORM
%generate our intial waveform

sig = tx_waveform();
subplot(211); plot(0:1/fs:t_max-1/fs,real(sig));
xlabel('Time (s)'); ylabel('Amplitude (v)');
title('FMCW signal'); axis tight;
subplot(212); spectrogram(sig,32,16,32,fs,'yaxis');
title('FMCW signal spectrogram');

%CREATE RECIEVER
%benign target example
car_dist = 20;
car_speed = 15*1000/3600;
car_rcs = db2pow(min(10*log10(car_dist)+5,20));
cartarget = phased.RadarTarget('MeanRCS',car_rcs,'PropagationSpeed',c,...
    'OperatingFrequency',fc);
carmotion = phased.Platform('InitialPosition',[car_dist;0;0.5],...
    'Velocity',[car_speed;0;0]);

%propogation model of transmitted
channel = phased.FreeSpace('PropagationSpeed',c,...
    'OperatingFrequency',fc,'SampleRate',fs,'TwoWayPropagation',true);

specanalyzer = spectrumAnalyzer('SampleRate',fs, ...
    'Method','welch','AveragingMethod','running', ...
    'PlotAsTwoSidedSpectrum',true, 'FrequencyResolutionMethod','rbw', ...
    'Title','Spectrum for received and dechirped signal', ...
    'ShowLegend',true);

%RADAR SET UP
ant_aperture = 6.06e-4;                         % in square meter
ant_gain = aperture2gain(ant_aperture,lambda);  % in dB

tx_ppower = db2pow(5)*1e-3;                     % in watts
tx_gain = 9+ant_gain;                           % in dB

rx_gain = 15+ant_gain;                          % in dB
rx_nf = 4.5;                                    % in dB

transmitter = phased.Transmitter('PeakPower',tx_ppower,'Gain',tx_gain);
receiver = phased.ReceiverPreamp('Gain',rx_gain,'NoiseFigure',rx_nf,...
    'SampleRate',fs);


%JAMMING SET UP

% Define the jammer's initial position and velocity
%jamming test at 6in(.15m), 15in(.38m), 48in(1.2m)
%preferabbly 3 datasets
jammer_distance =.15;
jammer_positions = [[jammer_distance; 0; 0]];%, [0; jammer_distance; 0]];

N_jammers = size(jammer_positions, 2);              % Number of jammers

% Initialize jammer structures
jammers = struct('jammotion', [], 'waveform', [], 'transmitter', [], 'channel_jammer', []);

for i = 1:N_jammers
    % Create a platform for the jammer
    jammers(i).jammotion = phased.Platform('InitialPosition', jammer_positions(:,i), ...
        'Velocity', [0; 0; 0]); % Assuming stationary jammers
    
    % Define the jammer's waveform (can be customized per jammer if needed)
    jammers(i).waveform = phased.FMCWWaveform('SweepTime', t_max, ...
        'SweepBandwidth', bandwidth, 'SampleRate', fs, ...
        'SweepDirection', 'Up');
    
    % Define the jammer's transmitter with specified power and gain
    jammer_tx_power = db2pow(10) * 1e-3;  % Example: 10 dBm
    jammer_tx_gain = tx_gain;              % Using same transmit gain as radar
    jammers(i).transmitter = phased.Transmitter('PeakPower', jammer_tx_power, ...
        'Gain', jammer_tx_gain);
    
    % Define a separate channel for the jammer
    jammers(i).channel_jammer = phased.FreeSpace('PropagationSpeed', c, ...
        'OperatingFrequency', fc, 'SampleRate', fs, ...
        'TwoWayPropagation', false);
end

% Simulation loop
rng(2012);
Nsweep = 64;
xr = complex(zeros(tx_waveform.SampleRate * tx_waveform.SweepTime, Nsweep));

for m = 1:Nsweep
    % Update radar and target positions
    [radar_pos, radar_vel] = radarmotion(t_max);
    [tgt_pos, tgt_vel] = carmotion(t_max);
    
    % Radar transmission
    sig = tx_waveform();
    txsig = transmitter(sig);
    
    % Signal propagation and target reflection
    txsig_target = channel(txsig, radar_pos, tgt_pos, radar_vel, tgt_vel);
    txsig_target = cartarget(txsig_target);
    txsig_target = receiver(txsig_target);
    
    % Initialize total jammer received signal
    jammer_received_total = 0;
    
    % Iterate over each jammer to generate and propagate their signals
    for i = 1:N_jammers
        % Update jammer position
        [jammer_pos, jammer_vel] = jammers(i).jammotion(t_max);
        
        % Generate jammer signal
        jammer_sig = jammers(i).waveform();
        jammer_txsig = jammers(i).transmitter(jammer_sig);
        
        % Propagate jammer signal to radar
        jammer_received_sig = jammers(i).channel_jammer(jammer_txsig, jammer_pos, ...
            radar_pos, jammer_vel, radar_vel);
        
        % Accumulate jammer signals
        jammer_received_total = jammer_received_total + jammer_received_sig;
    end
    
    % Combine radar and jammer signals
    total_received_sig = txsig_target + jammer_received_total;
    
    % Dechirp the received signal
    dechirpsig = dechirp(total_received_sig, sig);
    
    % Visualization
    specanalyzer([total_received_sig, dechirpsig]);
    
    % Store dechirped signal
    xr(:, m) = dechirpsig;
end



%ESTIMATE RANGE AND VELOCITY
rngdopresp = phased.RangeDopplerResponse('PropagationSpeed',c,...
    'DopplerOutput','Speed','OperatingFrequency',fc,'SampleRate',fs,...
    'RangeMethod','FFT','SweepSlope',sweep_slope,...
    'RangeFFTLengthSource','Property','RangeFFTLength',2048,...
    'DopplerFFTLengthSource','Property','DopplerFFTLength',256);

clf;
plotResponse(rngdopresp,xr);                     % Plot range Doppler map
axis([-v_max v_max 0 range_max])

climVals = clim;

