% Primary Radar characteristics
clear;
primary.fc = 77e9;                   % Carrier frequency in Hz
primary.range_max = 200;             % Maximum range in meters
primary.range_res = .25;               % Range resolution in meters
primary.v_max = 230 * 1000 / 3600;   % Maximum speed in m/s

primary.ant_aperture = 6.06e-4;      % Antenna aperture in square meters
primary.tx_power = 5;                % Transmit power in dBm
primary.tx_gain = 9;                 % Transmit gain in dB

primary.rx_gain = 15;                % Receive gain in dB
primary.rx_nf = 4.5;                 % Receiver noise figure in dB
emission_objects = [];
% Emission Radar characteristics
emission_objects(1).copy_primary = 0;       % Copy primary parameters (1 for true, 0 for false)
emission_objects(1).fc = 77e9;              % Carrier frequency in Hz
emission_objects(1).range_max = 200;        % Maximum range in meters
emission_objects(1).range_res = 1;        % Range resolution in meters
emission_objects(1).v_max = 230 * 1000 / 3600; % Maximum speed in m/s
emission_objects(1).tx_power = 10;          % Transmit power in dBm
emission_objects(1).tx_gain = 9;           % Transmit gain in dB
emission_objects(1).position = [.15; 0; 0];  % Initial position in meters
emission_objects(1).velocity = [0; 0; 0];   % Initial velocity in m/s

benign_objects = [];
% Benign Objects
benign_objects(1).position = [10; 0; 0];    % Initial position in meters
benign_objects(1).velocity = [1; 0; 0];     % Initial velocity in m/s
benign_objects(1).rcs_offset = 2;                 % Radar cross-section in dBsm

% Save to .mat file
save('radar_config.mat', 'primary', 'emission_objects', 'benign_objects');
