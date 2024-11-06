classdef FMCWSim < handle
    properties
        % Config file
        config
        % Radar and Environment
        radar
        environment
        % Analysis tools
        specanalyzer
        total_received_sig
        dechirpsig
    end

    methods
        function obj = FMCWSim(config_file)
            if nargin < 1
                config_file = 'radar_config.mat';
            end
            obj.config = obj.loadConfig(config_file);
            obj = obj.initialize();
        end

        function config = loadConfig(~, config_file)
            % Load configuration from file
            config = load(config_file);
        end

        function obj = initialize(obj)
            % Initialize radar, environment, and spectrum analyzer
            obj = obj.initializeRadar();
            obj = obj.initializeEnvironment();
            obj = obj.initializeSpectrumAnalyzer();
        end

        function obj = initializeRadar(obj)
            % Initialize the primary radar
            obj.radar = Radar(obj.config.primary);
        end

        function obj = initializeEnvironment(obj)
            % Initialize the environment with benign and emission objects
            %FIXME RANGE_RES B/T RADAR AND EMISSION'S MUST EQUAL
            obj.environment = Environment();
            obj.environment = obj.environment.loadEnvironment(obj.config);
        end

        function obj = initializeSpectrumAnalyzer(obj)
            % Initialize Spectrum Analyzer for visualization
            obj.specanalyzer = dsp.SpectrumAnalyzer('SampleRate', obj.radar.fs, 'Method', 'welch', 'AveragingMethod', 'running', ...
                'PlotAsTwoSidedSpectrum', true, 'FrequencyResolutionMethod', 'rbw', 'Title', ...
                'Spectrum for received and dechirped signal', 'ShowLegend', true);
        end

        function clutter = createGround(obj)
                    % Define clutter with radar and environment parameters
            clutter = phased.ConstantGammaClutter( ...
                'Sensor', obj.radar.reciever, ...
                'PropagationSpeed', obj.radar.c, ...
                'OperatingFrequency', obj.radar.fc, ...
                'SampleRate', obj.radar.fs, ...
                'PRF', 1 / obj.radar.t_max, ... % Pulse Repetition Frequency
                'Gamma', 0.3, ... % Terrain reflectivity
                'ClutterMinRange', 500, ...
                'ClutterMaxRange', 5000, ...
                'ClutterAzimuthCenter', 0, ...
                'ClutterAzimuthSpan', 60, ...
                'PlatformHeight', obj.radar.radar_position(3) + obj.environment.floor, ...
                'PlatformSpeed', norm(obj.radar.radar_velocity), ...
                'PlatformDirection', [90; 0]); % Adjust direction as needed
        end

        function xr = simulate(obj, Nsweep)
            if nargin < 2
                Nsweep = 64;
            end
        
            obj.environment.setTargets(obj.radar.fc);
            waveform_samples = round(obj.radar.fs * obj.radar.t_max);
            xr = complex(zeros(waveform_samples, Nsweep));
            
                    % Create clutter
            clutter = obj.createGround();
            
            benign_channel = phased.FreeSpace('PropagationSpeed', obj.radar.c, ...
                'OperatingFrequency', obj.radar.fc, 'SampleRate', obj.radar.fs, ...
                'TwoWayPropagation', true);
            emission_channel = phased.FreeSpace('PropagationSpeed', obj.radar.c, ...
                'OperatingFrequency', obj.radar.fc, 'SampleRate', obj.radar.fs, ...
                'TwoWayPropagation', false);
            
            radar_motion = phased.Platform('InitialPosition', obj.radar.radar_position, 'Velocity', obj.radar.radar_velocity);
            benign_motions = cell(1, length(obj.environment.benign_objects));
            for i = 1:length(obj.environment.benign_objects)
                benign_motions{i} = phased.Platform('InitialPosition', obj.environment.benign_objects(i).position, 'Velocity', obj.environment.benign_objects(i).velocity);
            end
            emission_motions = cell(1, length(obj.environment.emission_objects));
            for i = 1:length(obj.environment.emission_objects)
                emission_motions{i} = phased.Platform('InitialPosition', obj.environment.emission_objects(i).position, 'Velocity', obj.environment.emission_objects(i).velocity);
            end
        
            for m = 1:Nsweep
                [radar_pos, radar_vel] = radar_motion(obj.radar.t_max);
                for i = 1:length(benign_motions)
                    [obj.environment.benign_objects(i).position, obj.environment.benign_objects(i).velocity] = benign_motions{i}(obj.radar.t_max);
                end
        
                sig = obj.radar.tx_waveform();
                txsig = obj.radar.transmitter(sig);
                obj.total_received_sig = complex(zeros(size(txsig)));
                
                for i = 1:length(obj.environment.benign_objects)
                    reflected_sig = benign_channel(txsig, radar_pos, obj.environment.benign_objects(i).position, radar_vel, obj.environment.benign_objects(i).velocity);
                    reflected_sig = obj.environment.benign_objects(i).target(reflected_sig);
                    obj.total_received_sig = obj.total_received_sig + reflected_sig;
                end
        
                for i = 1:length(emission_motions)
                    [emission_pos, emission_vel] = emission_motions{i}(obj.radar.t_max);
                    emission_sig = obj.environment.emission_objects(i).waveform();
                    emission_txsig = obj.environment.emission_objects(i).transmitter(emission_sig);
                    emission_received_sig = emission_channel(emission_txsig, emission_pos, radar_pos, emission_vel, radar_vel);
                    obj.total_received_sig = obj.total_received_sig + emission_received_sig;
                end
        
                obj.dechirpsig = dechirp(obj.total_received_sig, sig);
                %obj.specanalyzer([obj.total_received_sig, obj.dechirpsig]);
                xr(:, m) = obj.dechirpsig;
            end
        end



        function plotRangeDoppler(obj, xr, targetGraph)
            % Check if targetGraph is provided; if not, set it to empty
            if nargin < 3 || isempty(targetGraph)
                targetGraph = [];
            end
        
            % Create a phased.RangeDopplerResponse object with given parameters
            rngdopresp = phased.RangeDopplerResponse('PropagationSpeed', obj.radar.c, ...
                'DopplerOutput', 'Speed', 'OperatingFrequency', obj.radar.fc, ...
                'SampleRate', obj.radar.fs, 'RangeMethod', 'FFT', 'SweepSlope', obj.radar.sweep_slope, ...
                'RangeFFTLengthSource', 'Property', 'RangeFFTLength', 2048, ...
                'DopplerFFTLengthSource', 'Property', 'DopplerFFTLength', 256);
        
            % Calculate the response data using the object and signal xr
            [data, rng_grid, dop_grid] = rngdopresp(xr);
        
            % If targetGraph is empty, create a new figure and UIAxes for the plot
            if isempty(targetGraph)
                figureHandle = figure('Name', 'Range-Doppler Response', 'NumberTitle', 'off');
                targetGraph = uiaxes('Parent', figureHandle);
            end
        
            % Plot the response on the provided UIAxis (targetGraph)
            surf(targetGraph, dop_grid, rng_grid, mag2db(abs(data)), 'EdgeColor', 'none');
            view(targetGraph, 0, 90); % Set the view to a 2D view
            xlabel(targetGraph, 'Doppler (m/s)');
            ylabel(targetGraph, 'Range (m)');
            title(targetGraph, 'Range-Doppler Response');
            axis(targetGraph, [-obj.radar.v_max, obj.radar.v_max, 0, obj.radar.range_max]);
            colorbar(targetGraph);
        end



        function openSpectrumAnalyzer(obj)
            % Open the spectrum analyzer
            obj.specanalyzer([obj.total_received_sig, obj.dechirpsig]);
        end

        function plotRadarWaveform(obj, signal)
            % Plot the radar waveform
            figure;
            t = (0:1/obj.radar.fs:obj.radar.t_max-1/obj.radar.fs);
            plot(t, real(signal));
            title('Radar FMCW Signal Waveform');
            xlabel('Time (s)');
            ylabel('Amplitude (v)');
            axis tight;
        end

function plotRangeVsPower(obj, xr, targetAxis)
    % Calculate the range-power data
    range_power = sum(abs(xr), 2);
    range_axis = linspace(0, obj.radar.range_max, length(range_power));

    % Plot in the provided UIAxes if available, otherwise create a new figure
    if nargin > 2 && ~isempty(targetAxis)
        % Plot in the specified UIAxes
        plot(targetAxis, range_axis, 10*log10(range_power));
        xlabel(targetAxis, 'Range (m)');
        ylabel(targetAxis, 'Power (dB)');
        title(targetAxis, 'Range vs Power');
        grid(targetAxis, 'on');
    else
        % Plot in a new figure window
        figure;
        plot(range_axis, 10*log10(range_power));
        xlabel('Range (m)');
        ylabel('Power (dB)');
        title('Range vs Power');
        grid on;
    end
end

function plotVelocityVsPower(obj, xr, targetAxis)
    % Define Doppler FFT parameters
    dopplerFFTLength = 256;  % Number of points for FFT along Doppler axis
    fs = obj.radar.fs;       % Sampling frequency of radar

    % Perform FFT on the radar signal along the Doppler axis
    dopplerData = fftshift(fft(xr, dopplerFFTLength, 2), 2);

    % Calculate Doppler frequency axis
    dopplerAxis = linspace(-fs/2, fs/2, dopplerFFTLength);

    % Convert Doppler frequency to velocity (using Doppler effect formula)
    wavelength = obj.radar.c / obj.radar.fc;
    velocityAxis = dopplerAxis * wavelength / 2;  % m/s

    % Sum the power across range bins to get overall power at each velocity
    velocityPower = sum(abs(dopplerData), 1);

    % Plot in the provided UIAxes if available, otherwise create a new figure
    if nargin > 2 && ~isempty(targetAxis)
        % Plot in the specified UIAxes
        plot(targetAxis, velocityAxis, 10*log10(velocityPower));
        xlabel(targetAxis, 'Velocity (m/s)');
        ylabel(targetAxis, 'Power (dB)');
        title(targetAxis, 'Velocity vs Power');
        grid(targetAxis, 'on');
    else
        % Plot in a new figure window
        figure;
        plot(velocityAxis, 10*log10(velocityPower));
        xlabel('Velocity (m/s)');
        ylabel('Power (dB)');
        title('Velocity vs Power');
        grid on;
    end
end



        function saveInfo(obj, filename)
            % Save radar and environment info to a file
            info.radar = obj.radar.saveRadar();
            info.environment = obj.environment.saveEnvironment();
            save(filename, '-struct', 'info');
        end

        function saveRangeVsPower(obj, filename, data)
            % Save Range vs Power data to a file
            save(filename, 'data');
        end

        function saveVelocityVsPower(obj, filename, data)
            % Save Velocity vs Power data to a file
            save(filename, 'data');
        end
    end
end
