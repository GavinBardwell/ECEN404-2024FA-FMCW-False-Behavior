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
        %sim results
        dechirpsig
        fftResponse
    end

    methods
        function obj = FMCWSim(config_file)
            if nargin < 1
                config_file = 'radar_config.mat';
            end
            obj.config = obj.loadConfig(config_file);
            obj = obj.initialize();
        end

        function config = loadConfig(obj, config_file)
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
            height = abs(obj.radar.radar_position(3) + obj.environment.floor);
            clutter = phased.ConstantGammaClutter( ...
                'PropagationSpeed', obj.radar.c, ...
                'OperatingFrequency', obj.radar.fc, ...
                'SampleRate', obj.radar.fs, ...
                'PRF', 1 / obj.radar.t_max, ...           % Pulse Repetition Frequency
                'Gamma', -60, ...                         % Terrain reflectivity (adjust as needed)
                'ClutterMinRange', 0, ...                 % Minimum range for clutter
                'ClutterMaxRange', obj.radar.range_max, ... % Maximum range based on radar range
                'ClutterAzimuthCenter', 0, ...            % Center azimuth of clutter (degrees)
                'ClutterAzimuthSpan', 180, ...            % Azimuth span of clutter (degrees)
                'PlatformHeight', height, ... % Radar height + floor level
                'PlatformSpeed', norm(obj.radar.radar_velocity)); % Radar platform speed
        end


        function xr = simulate(obj, Nsweep)
            if nargin < 2
                Nsweep = 64;
            end
        
            obj.environment.setTargets(obj.radar.fc);
            waveform_samples = round(obj.radar.fs * obj.radar.t_max);
            xr = complex(zeros(waveform_samples, Nsweep));

            if not(isnan(obj.environment.floor))
                clutter = obj.createGround();
            else
                clutter = []; % No clutter if floor is undefined
            end
            
            benign_channel = phased.FreeSpace('PropagationSpeed', obj.radar.c, ...
                'OperatingFrequency', obj.radar.fc, 'SampleRate', obj.radar.fs, ...
                'TwoWayPropagation', true);
            emission_channel = phased.FreeSpace('PropagationSpeed', obj.radar.c, ...
                'OperatingFrequency', obj.radar.fc, 'SampleRate', obj.radar.fs, ...
                'TwoWayPropagation', false);
            
            radar_motion = phased.Platform('InitialPosition', obj.radar.radar_position, 'Velocity', obj.radar.radar_velocity);

            benign_motions = cell(1, length(obj.environment.benign_objects));
            benign_positions = cell(1, length(obj.environment.benign_objects)); % Internal positions
            benign_velocities = cell(1, length(obj.environment.benign_objects)); % Internal velocities
            for i = 1:length(obj.environment.benign_objects)
                benign_motions{i} = phased.Platform('InitialPosition', obj.environment.benign_objects(i).position, 'Velocity', obj.environment.benign_objects(i).velocity);
                benign_positions{i} = obj.environment.benign_objects(i).position; % Initialize with current positions
                benign_velocities{i} = obj.environment.benign_objects(i).velocity; % Initialize with current velocities
            end

            emission_motions = cell(1, length(obj.environment.emission_objects));
            emission_offsets = zeros(1, length(emission_motions));
            for i = 1:length(obj.environment.emission_objects)
                emission_motions{i} = phased.Platform('InitialPosition', obj.environment.emission_objects(i).position, 'Velocity', obj.environment.emission_objects(i).velocity);
            end
            
            for m = 1:Nsweep
                [radar_pos, radar_vel] = radar_motion(obj.radar.t_max);
                 for i = 1:length(benign_motions)
                    [benign_positions{i}, benign_velocities{i}] = benign_motions{i}(obj.radar.t_max); % Update local positions/velocities
                end
        
                sig = obj.radar.tx_waveform();
                txsig = obj.radar.transmitter(sig);
                obj.total_received_sig = complex(zeros(size(txsig)));
                
                for i = 1:length(obj.environment.benign_objects)
                    reflected_sig = benign_channel(txsig, radar_pos, benign_positions{i}, radar_vel, benign_velocities{i});
                    reflected_sig = obj.environment.benign_objects(i).target(reflected_sig);
                    obj.total_received_sig = obj.total_received_sig + reflected_sig;
                end
        
                for i = 1:length(emission_motions)
                    %do the actual simulartion portion of it
                    [emission_pos, emission_vel] = emission_motions{i}(obj.radar.t_max);
                    emission_sig = obj.environment.emission_objects(i).waveform();
                    emission_txsig = obj.environment.emission_objects(i).transmitter(emission_sig);
                    emission_received_sig = emission_channel(emission_txsig, emission_pos, radar_pos, emission_vel, radar_vel);
                    
                    %resize the array and offset it to make it loop
                    %properly
                    phase_offset = obj.environment.emission_objects(i).phase() / 360 * size(emission_received_sig, 1);
                    current_offset = round(emission_offsets(i) + phase_offset);
                    emission_received_sig = resize(emission_received_sig, size(obj.total_received_sig, 1) + current_offset, Pattern="circular");
                    
                    % Cut down the signal to the required size after resizing
                    emission_received_sig = emission_received_sig(current_offset + 1 : current_offset + size(obj.total_received_sig, 1));

                    % Update offset for the next loop
                    emission_offsets(i) = mod(current_offset + size(txsig, 1), size(emission_sig, 1));

                    obj.total_received_sig = obj.total_received_sig + emission_received_sig;
                end
                                % Create clutter
                if ~isempty(clutter)
                    clutter_returns = sum(clutter(), 2); % Sum across channels if necessary
                    obj.total_received_sig = obj.total_received_sig + clutter_returns;
                end
                obj.total_received_sig = obj.radar.receiver(obj.total_received_sig);
                obj.dechirpsig = dechirp(obj.total_received_sig, sig);
                %obj.specanalyzer([obj.total_received_sig, obj.dechirpsig]);
                xr(:, m) = obj.dechirpsig;
            end
        end

        function xr_frames = simulateFrames(obj, Nframes, Nsweep)
            if nargin < 2
                Nsweep = 64;
                Nframes = 1;
            end
        
            obj.environment.setTargets(obj.radar.fc);
            waveform_samples = round(obj.radar.fs * obj.radar.t_max);
            % Initialize 3D array to hold all frames
            xr_frames = complex(zeros(waveform_samples, Nsweep, Nframes));

            if not(isnan(obj.environment.floor))
                clutter = obj.createGround();
            else
                clutter = []; % No clutter if floor is undefined
            end
            
            benign_channel = phased.FreeSpace('PropagationSpeed', obj.radar.c, ...
                'OperatingFrequency', obj.radar.fc, 'SampleRate', obj.radar.fs, ...
                'TwoWayPropagation', true);
            emission_channel = phased.FreeSpace('PropagationSpeed', obj.radar.c, ...
                'OperatingFrequency', obj.radar.fc, 'SampleRate', obj.radar.fs, ...
                'TwoWayPropagation', false);
            
            radar_motion = phased.Platform('InitialPosition', obj.radar.radar_position, 'Velocity', obj.radar.radar_velocity);

            benign_motions = cell(1, length(obj.environment.benign_objects));
            benign_positions = cell(1, length(obj.environment.benign_objects)); % Internal positions
            benign_velocities = cell(1, length(obj.environment.benign_objects)); % Internal velocities
            for i = 1:length(obj.environment.benign_objects)
                benign_motions{i} = phased.Platform('InitialPosition', obj.environment.benign_objects(i).position, 'Velocity', obj.environment.benign_objects(i).velocity);
                benign_positions{i} = obj.environment.benign_objects(i).position; % Initialize with current positions
                benign_velocities{i} = obj.environment.benign_objects(i).velocity; % Initialize with current velocities
            end

            emission_motions = cell(1, length(obj.environment.emission_objects));
            emission_offsets = zeros(1, length(emission_motions));
            phase_offsets = zeros(1, length(obj.environment.emission_objects));
            for i = 1:length(obj.environment.emission_objects)
                emission_motions{i} = phased.Platform('InitialPosition', obj.environment.emission_objects(i).position, 'Velocity', obj.environment.emission_objects(i).velocity);
                phase_offsets(i) = round(obj.environment.emission_objects(i).phase() / 360 * waveform_samples);
            end

            %actual simulation loop
            for frame = 1:Nframes
                xr = complex(zeros(waveform_samples, Nsweep)); % Initialize for each frame  
                for m = 1:Nsweep
                    [radar_pos, radar_vel] = radar_motion(obj.radar.t_max);
                     for i = 1:length(benign_motions)
                        [benign_positions{i}, benign_velocities{i}] = benign_motions{i}(obj.radar.t_max); % Update local positions/velocities
                    end
            
                    sig = obj.radar.tx_waveform();
                    txsig = obj.radar.transmitter(sig);
                    obj.total_received_sig = complex(zeros(size(txsig)));
                    
                    for i = 1:length(obj.environment.benign_objects)
                        reflected_sig = benign_channel(txsig, radar_pos, benign_positions{i}, radar_vel, benign_velocities{i});
                        reflected_sig = obj.environment.benign_objects(i).target(reflected_sig);
                        obj.total_received_sig = obj.total_received_sig + reflected_sig;
                    end
            
                    for i = 1:length(emission_motions)
                        %do the actual simulartion portion of it
                        [emission_pos, emission_vel] = emission_motions{i}(obj.radar.t_max);
                        emission_sig = obj.environment.emission_objects(i).waveform();
                        emission_txsig = obj.environment.emission_objects(i).transmitter(emission_sig);
                        emission_received_sig = emission_channel(emission_txsig, emission_pos, radar_pos, emission_vel, radar_vel);
                        
                        %resize the array and offset it to make it loop
                        %properly
                        phase_offset = obj.environment.emission_objects(i).phase() / 360 * size(emission_received_sig, 1);
                        current_offset = round(emission_offsets(i) + phase_offset);
                        emission_received_sig = resize(emission_received_sig, size(obj.total_received_sig, 1) + current_offset, Pattern="circular");
                        
                        % Cut down the signal to the required size after resizing
                        emission_received_sig = emission_received_sig(current_offset + 1 : current_offset + size(obj.total_received_sig, 1));
    
                        % Update offset for the next loop
                        emission_offsets(i) = mod(current_offset + size(txsig, 1), size(emission_sig, 1));
    
                        obj.total_received_sig = obj.total_received_sig + emission_received_sig;
                    end
                                    % Create clutter
                    if ~isempty(clutter)
                        clutter_returns = sum(clutter(), 2); % Sum across channels if necessary
                        obj.total_received_sig = obj.total_received_sig + clutter_returns;
                    end
                    obj.total_received_sig = obj.radar.receiver(obj.total_received_sig);
                    obj.dechirpsig = dechirp(obj.total_received_sig, sig);

                    xr(:, m) = obj.dechirpsig;
                end
                % Store the current frame in the 3D array
                xr_frames(:, :, frame) = xr;
            end
        end



        function plotRangeDoppler(obj, xr, targetGraph)
            % Check if targetGraph is provided; if not, set it to empty
            if nargin < 3 || isempty(targetGraph)
                targetGraph = [];
            end
            numRows= size(xr, 1);
            tWin = taylorwin(numRows,5, -35);
            % Create a phased.RangeDopplerResponse object with given parameters
            rngdopresp = phased.RangeDopplerResponse('PropagationSpeed', obj.radar.c, ...
                'DopplerOutput', 'Speed', 'OperatingFrequency', obj.radar.fc, ...
                'SampleRate', obj.radar.fs, 'RangeMethod', 'FFT', 'SweepSlope', obj.radar.sweep_slope, ...
                'RangeFFTLengthSource', 'Property', 'RangeFFTLength', 2048, ...
                'DopplerFFTLengthSource', 'Property', 'DopplerFFTLength', 256);
            
            % Calculate the response data using the object and signal xr
            xr_window = xr .* tWin;
            [resp, rng_grid, dop_grid] = rngdopresp(xr_window);
            
            obj.fftResponse.resp = resp;
            obj.fftResponse.rng_grid = rng_grid;
            obj.fftResponse.dop_grid = dop_grid;
            % If targetGraph is empty, create a new figure and UIAxes for the plot
            if isempty(targetGraph)
                figureHandle = figure('Name', 'Range-Doppler Response', 'NumberTitle', 'off');
                targetGraph = uiaxes('Parent', figureHandle);
            end
        
            % Plot the response on the provided UIAxis (targetGraph)
            surf(targetGraph, dop_grid, rng_grid, mag2db(abs(resp)), 'EdgeColor', 'none');
            view(targetGraph, 0, 90); % Set the view to a 2D view
            xlabel(targetGraph, 'Doppler (m/s)');
            ylabel(targetGraph, 'Range (m)');
            title(targetGraph, 'Range-Doppler Response');
            axis(targetGraph, [-obj.radar.v_max, obj.radar.v_max, 0, obj.radar.range_max]);
            colorbar(targetGraph);
        end

        function fftFrames = runFFTFrames(obj, xr_frames)
            numRows= size(xr_frames, 1);
            numFrames = size(xr_frames, 3);
            tWin = taylorwin(numRows,5, -35);
            % Create a phased.RangeDopplerResponse object with given parameters
            rngdopresp = phased.RangeDopplerResponse('PropagationSpeed', obj.radar.c, ...
                'DopplerOutput', 'Speed', 'OperatingFrequency', obj.radar.fc, ...
                'SampleRate', obj.radar.fs, 'RangeMethod', 'FFT', 'SweepSlope', obj.radar.sweep_slope, ...
                'RangeFFTLengthSource', 'Property', 'RangeFFTLength', 2048, ...
                'DopplerFFTLengthSource', 'Property', 'DopplerFFTLength', 256);
               % Initialize the response data for all frames
            resp_all_frames = cell(1, numFrames);
            rng_grid_all = cell(1, numFrames);
            dop_grid_all = cell(1, numFrames);
            
            % Loop through each frame and calculate range-Doppler
            % response
            for frame = 1:numFrames
                % Extract the frame data
                xr_frame = xr_frames(:, :, frame);
            
                % Apply Taylor window to the frame data
                xr_window = xr_frame .* tWin;
            
                % Calculate the response for the current frame using rngdopresp
                [resp, rng_grid, dop_grid] = rngdopresp(xr_window);
            
                % Store the response, range grid, and Doppler grid for the current frame
                resp_all_frames{frame} = resp;
                rng_grid_all{frame} = rng_grid;
                dop_grid_all{frame} = dop_grid;
            end
            fftFrames.resp_frames = resp_all_frames;
            fftFrames.rng_grid = rng_grid_all;
            fftFrames.dop_grid = dop_grid_all;
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

        function plotRangeVsPower(obj, targetAxis)
            % Calculate the range-power data
            % Integrate power over all Doppler bins
            power_vs_range = sum(abs(obj.fftResponse.resp), 2); % Sum over the Doppler dimension
            
            % Convert power to decibels (optional)
            power_vs_range_db = 10 * log10(power_vs_range);
        
            % Plot in the provided UIAxes if available, otherwise create a new figure
            if nargin > 1 && ~isempty(targetAxis)
                % Plot in the specified UIAxes
                plot(targetAxis, obj.fftResponse.rng_grid, power_vs_range_db);
                xlabel(targetAxis, 'Range (m)');
                ylabel(targetAxis, 'Power (dB)');
                title(targetAxis, 'Range vs Power');
                grid(targetAxis, 'on');
            else
                % Plot in a new figure window
                figure;
                plot(obj.fftResponse.rng_grid, power_vs_range_db);
                xlabel('Range (m)');
                ylabel('Power (dB)');
                title('Range vs. Power');
                grid on;
            end
        end
        
        function plotVelocityVsPower(obj, targetAxis)
            power_vs_doppler = sum(abs(obj.fftResponse.resp), 1);%sum over range dimension
        
            % Convert power to decibels 
            power_vs_doppler_db = 10 * log10(power_vs_doppler);
            % Plot in the provided UIAxes if available, otherwise create a new figure
            if nargin > 1 && ~isempty(targetAxis)
                % Plot in the specified UIAxes
                plot(targetAxis, obj.fftResponse.dop_grid, power_vs_doppler_db);
                xlabel(targetAxis, 'Velocity (m/s)');
                ylabel(targetAxis, 'Power (dB)');
                title(targetAxis, 'Velocity vs Power');
                grid(targetAxis, 'on');
            else
                % Plot in a new figure window
                figure;
                plot(obj.fftResponse.dop_grid, power_vs_doppler_db);
                xlabel('Velocity (m/s)');
                ylabel('Power (dB)');
                title('Velocity vs Power');
                grid on;
            end
        end
               
        function animateRangeDopplerResponse(obj, resp_all_frames, rng_grid_all, dop_grid_all, targetGraph, videoFileName)
    % Inputs:
    % resp_all_frames: Cell array containing the range-Doppler response for each frame
    % rng_grid_all: Cell array containing the range grid for each frame
    % dop_grid_all: Cell array containing the Doppler grid for each frame
    % targetGraph: UIAxes or axes handle for plotting the animation
    % videoFileName: Optional name of the video file to save the animation
    videoFileName = 'doppler.mp4';
    numFrames = length(resp_all_frames);

    % Create a new figure and UIAxes for the animated plot if targetGraph is not provided or empty
    if nargin < 5 || isempty(targetGraph)
        figureHandle = figure('Name', 'Range-Doppler Response Animation', 'NumberTitle', 'off');
        targetGraph = uiaxes('Parent', figureHandle);
    end

    % Create a VideoWriter object if videoFileName is provided
    if ~isempty(videoFileName)
        videoWriter = VideoWriter(videoFileName, 'MPEG-4');
        videoWriter.FrameRate = 10; % Set the frame rate (adjust as needed)
        open(videoWriter);
    end

    % Animate through the frames
    for d = 1:numFrames
        % Extract the response for the current frame
        resp = resp_all_frames{d};
        rng_grid = rng_grid_all{d};
        dop_grid = dop_grid_all{d};

        % Plot the range-Doppler response for the current frame
        % Use surf to create a similar plot as in plotRangeDoppler
        surf(targetGraph, dop_grid, rng_grid, mag2db(abs(resp)), 'EdgeColor', 'none');
        view(targetGraph, 0, 90); % Set the view to a 2D view
        xlabel(targetGraph, 'Doppler (m/s)');
        ylabel(targetGraph, 'Range (m)');
        title(targetGraph, sprintf('Range-Doppler Response - Frame %d of %d', d, numFrames));
        axis(targetGraph, [-obj.radar.v_max, obj.radar.v_max, 0, obj.radar.range_max]);
        colorbar(targetGraph);

        % Capture the frame if video recording is enabled
        if ~isempty(videoFileName)
            frame = getframe(figureHandle); % Get the current frame
            writeVideo(videoWriter, frame); % Write the frame to the video file
        end

        % Pause to create the effect of animation
        pause(0.1); % Adjust the pause duration to control the speed of animation
    end

    % Close the video writer if it was opened
    if nargin >= 6 && ~isempty(videoFileName)
        close(videoWriter);
    end
end


function animateRangeVsPower(obj, resp_all_frames, rng_grid_all, targetAxis, videoFileName)
    % Inputs:
    % resp_all_frames: Cell array containing the range-Doppler response for each frame
    % rng_grid_all: Cell array containing the range grid for each frame
    % targetAxis: UIAxes or axes handle for plotting the animation
    % videoFileName: Optional name of the video file to save the animation
    videoFileName = 'RangeVsPower.mp4';
    numFrames = length(resp_all_frames);

    % Create a new figure and UIAxes for the animated plot if targetAxis is not provided or empty
    if nargin < 4 || isempty(targetAxis)
        figureHandle = figure('Name', 'Range vs Power Animation', 'NumberTitle', 'off', 'Position', [100, 100, 800, 600]);
        targetAxis = axes('Parent', figureHandle); % Use standard axes
    else
        % If targetAxis is provided, assume it is part of an existing figure
        figureHandle = ancestor(targetAxis, 'figure');
    end

    % Create a VideoWriter object if videoFileName is provided
    if ~isempty(videoFileName)
        videoWriter = VideoWriter(videoFileName, 'MPEG-4');
        videoWriter.FrameRate = 10; % Set the frame rate (adjust as needed)
        open(videoWriter);
    end

    % Animate through the frames
    for d = 1:numFrames
        % Extract the response for the current frame
        resp = resp_all_frames{d};
        rng_grid = rng_grid_all{d};

        % Calculate the power vs range for the current frame
        power_vs_range = sum(abs(resp), 2); % Sum over the Doppler dimension
        power_vs_range_db = 10 * log10(power_vs_range); % Convert power to decibels

        % Clear the axis to prepare for new plot
        cla(targetAxis);

        % Plot the range vs power for the current frame
        plot(targetAxis, rng_grid, power_vs_range_db);
        xlabel(targetAxis, 'Range (m)');
        ylabel(targetAxis, 'Power (dB)');
        title(targetAxis, sprintf('Range vs Power - Frame %d of %d', d, numFrames));
        grid(targetAxis, 'on');
        axis(targetAxis, [min(rng_grid), max(rng_grid), min(power_vs_range_db) - 10, max(power_vs_range_db) + 10]);

        % Capture the frame if video recording is enabled
        if ~isempty(videoFileName)
            % Capture the entire figure instead of the target axis
            frame = getframe(figureHandle); % Get the current frame
            writeVideo(videoWriter, frame); % Write the frame to the video file
        end

        % Pause to create the effect of animation
        pause(0.1); % Adjust the pause duration to control the speed of animation
    end

    % Close the video writer if it was opened
    if nargin >= 5 && ~isempty(videoFileName)
        close(videoWriter);
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
