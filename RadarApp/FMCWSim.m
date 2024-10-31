classdef FMCWSim
    properties
        config
        c = 3e8;
        fc
        lambda
        range_max
        t_max
        range_res
        bandwidth
        sweep_slope
        v_max
        fd_max
        fr_max
        fb_max
        fs
        ant_aperture
        ant_gain
        tx_ppower
        tx_gain
        rx_gain
        rx_nf
        tx_waveform
        radar_speed = 0;
        radar_position
        radar_velocity
        transmitter
        receiver
        N_emission
        emission_objects
        specanalyzer
    end
    
    methods
        function obj = FMCWSim(config_file)
            if nargin < 1
                config_file = 'radar_config.mat';
            end
            obj.c = 3e8;
            obj.config = obj.loadConfig(config_file);
            obj = obj.initializeParameters();
            obj = obj.initializeWaveformAndMotion();
            obj = obj.initializeTransmitterReceiver();
            obj = obj.initializeObjects();
            obj = obj.initializeSpectrumAnalyzer();
        end
        
        function config = loadConfig(~, config_file)
            config = load(config_file);
        end
        
        function obj = initializeParameters(obj)
            % Primary Radar Configuration
            obj.fc = obj.config.primary.fc;
            obj.lambda = obj.c / obj.fc;

            obj.range_max = obj.config.primary.range_max;
            obj.t_max = 5.5 * obj.range2time(obj.range_max);

            obj.range_res = obj.config.primary.range_res;
            obj.bandwidth = obj.rangeres2bw(obj.range_res);
            obj.sweep_slope = obj.bandwidth / obj.t_max;

            obj.v_max = obj.config.primary.v_max;
            obj.fd_max = obj.speed2dop(2 * obj.v_max);
            obj.fr_max = obj.range2beat(obj.range_max);
            obj.fb_max = obj.fr_max + obj.fd_max;

            obj.fs = max(2 * obj.fb_max, obj.bandwidth);

            % Antenna Parameters
            obj.ant_aperture = obj.config.primary.ant_aperture;
            obj.ant_gain = obj.aperture2gain(obj.ant_aperture);

            % Transmitter and Receiver Parameters
            obj.tx_ppower = obj.db2pow(obj.config.primary.tx_power) * 1e-3;  % in watts
            obj.tx_gain = obj.config.primary.tx_gain + obj.ant_gain;
            obj.rx_gain = obj.config.primary.rx_gain + obj.ant_gain;
            obj.rx_nf = obj.config.primary.rx_nf;  % in dB
        end
        
        function obj = initializeWaveformAndMotion(obj)
            % Create Primary Radar Waveform
            obj.tx_waveform = phased.FMCWWaveform('SweepTime', obj.t_max, 'SweepBandwidth', obj.bandwidth, 'SampleRate', obj.fs);

            % Create Primary Radar Motion
            obj.radar_speed = 0;
            obj.radar_position = [0; 0; 0];
            obj.radar_velocity = [obj.radar_speed; 0; 0];
        end
        
        function obj = initializeTransmitterReceiver(obj)
            % Create Transmitter and Receiver
            obj.transmitter = phased.Transmitter('PeakPower', obj.tx_ppower, 'Gain', obj.tx_gain);
            obj.receiver = phased.ReceiverPreamp('Gain', obj.rx_gain, 'NoiseFigure', obj.rx_nf, 'SampleRate', obj.fs);
        end
        
        function obj = initializeObjects(obj)
            obj.N_emission = length(obj.config.emission_objects);
            obj.emission_objects = struct([]);
            
            for i = 1:obj.N_emission
                emission_object = obj.config.emission_objects(i);
                obj.emission_objects(i).fc = emission_object.fc;
                obj.emission_objects(i).range_max = emission_object.range_max;
                obj.emission_objects(i).range_res = emission_object.range_res;
                obj.emission_objects(i).v_max = emission_object.v_max;
                obj.emission_objects(i).tx_power = emission_object.tx_power;
                obj.emission_objects(i).tx_gain = emission_object.tx_gain;
                obj.emission_objects(i).position = emission_object.position;
                obj.emission_objects(i).velocity = emission_object.velocity;
            end
        end
        
        function obj = initializeSpectrumAnalyzer(obj)
            % Initialize Spectrum Analyzer for Visualization
            obj.specanalyzer = dsp.SpectrumAnalyzer('SampleRate', obj.fs, 'Method', 'welch', 'AveragingMethod', 'running', ...
                'PlotAsTwoSidedSpectrum', true, 'FrequencyResolutionMethod', 'rbw', 'Title', ...
                'Spectrum for received and dechirped signal', 'ShowLegend', true);
        end
        
        function t = range2time(obj, range_max)
            t = (2 * range_max) / obj.c;
        end
        
        function bw = rangeres2bw(obj, range_res)
            bw = obj.c / (2 * range_res);
        end
        
        function dop = speed2dop(obj, speed)
            dop = (2 * speed * obj.fc) / obj.c;
        end
        
        function beat = range2beat(obj, range_max)
            beat = obj.sweep_slope * obj.range2time(range_max);
        end
        
        function gain = aperture2gain(obj, aperture)
            gain = 10 * log10(4 * pi * aperture / (obj.lambda ^ 2));
        end
        
        function pow = db2pow(obj, db_value)
            pow = 10 ^ (db_value / 10);
        end
        
        function xr = simulateEnvironment(obj, Nsweep)
            if nargin < 2
                Nsweep = 64;
            end
            
            rng(2012);
            waveform_samples = round(obj.tx_waveform.SampleRate * obj.tx_waveform.SweepTime);
            xr = complex(zeros(waveform_samples, Nsweep));
            
            for m = 1:Nsweep
                % Update Radar Position
                radar_pos = obj.radar_position + m * obj.radar_velocity * obj.t_max;
                
                % Simulate Benign and Emission Object Interactions
                total_received_sig = complex(zeros(size(obj.tx_waveform())));
                
                % Add Emission Radar Interference
                for i = 1:obj.N_emission
                    emission_obj = obj.emission_objects(i);
                    jammer_waveform = obj.tx_waveform();
                    total_received_sig = total_received_sig + jammer_waveform;
                end
                
                % Dechirp the Received Signal
                dechirpsig = dechirp(total_received_sig, obj.tx_waveform());
                
                % Store Dechirped Signal
                xr(:, m) = dechirpsig;
                
                % Spectrum Analysis
                obj.specanalyzer([total_received_sig, dechirpsig]);
            end
        end
        
        function plotRangeDopplerResponse(obj, xr, targetGraph)
            % Create a phased.RangeDopplerResponse object with given parameters
            rngdopresp = phased.RangeDopplerResponse('PropagationSpeed', obj.c, 'DopplerOutput', ...
                'Speed', 'OperatingFrequency', obj.fc, 'SampleRate', obj.fs, 'RangeMethod', 'FFT', ...
                'SweepSlope', obj.sweep_slope, 'RangeFFTLengthSource', 'Property', 'RangeFFTLength', 2048, ...
                'DopplerFFTLengthSource', 'Property', 'DopplerFFTLength', 256);
        
            % Calculate the response data using the object and signal xr
            [data, rng_grid, dop_grid] = rngdopresp(xr);
        
            % Plot the response on the provided UIAxis (targetGraph)
            surf(targetGraph, dop_grid, rng_grid, mag2db(abs(data)), 'EdgeColor', 'none');
            view(targetGraph, 0, 90); % Set the view to a 2D view
            xlabel(targetGraph, 'Doppler (m/s)');
            ylabel(targetGraph, 'Range (m)');
            title(targetGraph, 'Range-Doppler Response');
            axis(targetGraph, [-obj.v_max, obj.v_max, 0, obj.range_max]);
            colorbar(targetGraph);
        end

        
        function plotWaveform(obj, signal)
            figure;
            t = (0:1/obj.fs:obj.t_max-1/obj.fs);
            plot(t, real(signal));
            title('FMCW Signal Waveform');
            xlabel('Time (s)');
            ylabel('Amplitude (v)');
            axis tight;
        end
        
        function plotSignalSpectrum(obj, signal)
            figure;
            spectrogram(signal, 32, 16, 32, obj.fs, 'yaxis');
            title('Signal Spectrum');
        end

        function plotRangePower(obj, xr, uiax)
            range_power = sum(abs(xr), 2);
            range_axis = linspace(0, obj.range_max, length(range_power));
            plot(uiax, range_axis, 10*log10(range_power));
            xlabel(uiax, 'Range (m)');
            ylabel(uiax, 'Power (dB)');
            title(uiax, 'Range vs Power');
            grid(uiax, 'on');
        end
    end
end
