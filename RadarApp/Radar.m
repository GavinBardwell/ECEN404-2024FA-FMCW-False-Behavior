classdef Radar
    %This class holds and calculates all information needed for the primary
    %radar

    properties
        %constants
        c = 3e8;
        %values
        fc;
        range_max;
        range_res;
        v_max;
        ant_aperture;
        tx_ppower;
        tx_gain;
        rx_gain;
        rx_nf;
        tx_waveform;
        radar_speed = 0;
        radar_position;
        radar_velocity;
        transmitter;
        receiver;
    end

    properties (Dependent)
        lambda;
        t_max;
        bandwidth;
        sweep_slope;
        fd_max;
        fr_max;
        fb_max;
        fs;
        ant_gain;
    end

    methods
        function obj = Radar(params)
            % Constructor for Radar class
            if nargin == 1
                obj = obj.setRadar(params);
            else
                % Set default values
                default_params.fc = 1e9; % 1 GHz
                default_params.range_max = 1e3; % 1000 meters
                default_params.range_res = 10; % 10 meters
                default_params.v_max = 30; % 30 m/s
                default_params.ant_aperture = 1; % 1 square meter
                default_params.tx_power = 30; % 30 dBm
                default_params.tx_gain = 20; % 20 dB
                default_params.rx_gain = 20; % 20 dB
                default_params.rx_nf = 5; % 5 dB
                obj = obj.setRadar(default_params);
            end
        end

        function obj = setRadar(obj, params)
            % Set radar parameters from input structure
            obj.fc = params.fc;
            obj.range_max = params.range_max;
            obj.range_res = params.range_res;
            obj.v_max = params.v_max;
            obj.ant_aperture = params.ant_aperture;
            obj.tx_ppower = obj.db2pow(params.tx_power) * 1e-3;  % in watts
            obj.tx_gain = params.tx_gain;
            obj.rx_gain = params.rx_gain;
            obj.rx_nf = params.rx_nf;  % in dB
            obj.tx_waveform = phased.FMCWWaveform('SweepTime', obj.t_max, 'SweepBandwidth', obj.bandwidth, 'SampleRate', obj.fs);
            obj.radar_position = [0; 0; 0];
            obj.radar_velocity = [obj.radar_speed; 0; 0];
            obj.transmitter = phased.Transmitter('PeakPower', obj.tx_ppower, 'Gain', obj.tx_gain + obj.ant_gain);
            obj.receiver = phased.ReceiverPreamp('Gain', obj.rx_gain + obj.ant_gain, 'NoiseFigure', obj.rx_nf, 'SampleRate', obj.fs);
        end

        function value = get.lambda(obj)
            value = obj.c / obj.fc;
        end

        function value = get.t_max(obj)
            value = 5.5 * obj.range2time(obj.range_max);
        end

        function value = get.bandwidth(obj)
            value = obj.rangeres2bw(obj.range_res);
        end

        function value = get.sweep_slope(obj)
            value = obj.bandwidth / obj.t_max;
        end

        function value = get.fd_max(obj)
            value = obj.speed2dop(2 * obj.v_max);
        end

        function value = get.fr_max(obj)
            value = obj.range2beat(obj.range_max);
        end

        function value = get.fb_max(obj)
            value = obj.fr_max + obj.fd_max;
        end

        function value = get.fs(obj)
            value = max(2 * obj.fb_max, obj.bandwidth);
        end

        function value = get.ant_gain(obj)
            value = obj.aperture2gain(obj.ant_aperture);
        end

        function t = range2time(obj, range_max)
            % Calculate round trip time for given range
            t = (2 * range_max) / obj.c;
        end

        function bw = rangeres2bw(obj, range_res)
            % Calculate bandwidth required for given range resolution
            bw = obj.c / (2 * range_res);
        end

        function dop = speed2dop(obj, speed)
            % Calculate Doppler frequency for given speed
            dop = (2 * speed * obj.fc) / obj.c;
        end

        function beat = range2beat(obj, range_max)
            % Calculate beat frequency for given range
            beat = obj.sweep_slope * obj.range2time(range_max);
        end

        function gain = aperture2gain(obj, aperture)
            % Calculate antenna gain from aperture
            gain = 10 * log10(4 * pi * aperture / ((obj.c / obj.fc) ^ 2));
        end

        function pow = db2pow(obj, db_value)
            % Convert dB value to power
            pow = 10 ^ (db_value / 10);
        end

        function viewRadarWaveform(obj)
            % Plot the radar waveform
            figure;
            t = (0:1/obj.fs:obj.t_max-1/obj.fs);
            plot(t, real(obj.tx_waveform()));
            title('Radar FMCW Signal Waveform');
            xlabel('Time (s)');
            ylabel('Amplitude (v)');
            axis tight;
        end

        function returnedRadar = saveRadar(obj)
            % Save radar object to a file
            returnedRadar = struct;
            returnedRadar.fc = obj.fc;
            returnedRadar.range_max = obj.range_max;
            returnedRadar.range_res = obj.range_res;
            returnedRadar.v_max = obj.v_max;
            returnedRadar.ant_aperture = obj.ant_aperture;
            returnedRadar.tx_ppower = obj.tx_ppower;
            returnedRadar.tx_gain = obj.tx_gain;
            returnedRadar.rx_gain = obj.rx_gain;
            returnedRadar.rx_nf = obj.rx_nf;
        end
    end
end
