classdef EmissionObject < handle
    %EMISSIONOBJECT contains all information regarding one emitting object
    %in our environment
    
    properties
        fc  % Carrier frequency in Hz
        range_max % Maximum range in meters
        range_res % Range resolution in meters
        v_max % Maximum speed in m/s
        tx_power % Transmit power in dBm
        tx_gain % Transmit gain in dB
        position % Initial position in meters (x, y, z)
        velocity % Initial velocity in m/s (x, y, z)
    end
    
    properties (Constant)
        c = 3e8; % Speed of light in m/s
    end
    
    properties (Dependent)
        waveform
        t_max
        bandwidth
        sweep_slope
        fd_max
        fr_max
        fb_max
        fs
        transmitter
    end
    
    methods
        function obj = EmissionObject(params)
            % Constructor to initialize properties based on input parameters
            if nargin == 1
                obj.fc = params.fc;
                obj.range_max = params.range_max;
                obj.range_res = params.range_res;
                obj.v_max = params.v_max;
                obj.tx_power = params.tx_power;
                obj.tx_gain = params.tx_gain;
                obj.position = params.position;
                obj.velocity = params.velocity;
            else
                obj.fc = 0;
                obj.range_max = 0;
                obj.range_res = 0;
                obj.v_max = 0;
                obj.tx_power = 0;
                obj.tx_gain = 0;
                obj.position = [0; 0; 0];
                obj.velocity = [0; 0; 0];
            end
        end
        
        function obj = updateParameters(obj, params)
            if isfield(params, 'fc')
                obj.fc = params.fc;
            end
            if isfield(params, 'range_max')
                obj.range_max = params.range_max;
            end
            if isfield(params, 'range_res')
                obj.range_res = params.range_res;
            end
            if isfield(params, 'v_max')
                obj.v_max = params.v_max;
            end
            if isfield(params, 'tx_power')
                obj.tx_power = params.tx_power;
            end
            if isfield(params, 'tx_gain')
                obj.tx_gain = params.tx_gain;
            end
            if isfield(params, 'position')
                obj.position = params.position;
            end
            if isfield(params, 'velocity')
                obj.velocity = params.velocity;
            end
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
        
        function value = get.waveform(obj)
            value = phased.FMCWWaveform('SweepTime', obj.t_max, 'SweepBandwidth', obj.bandwidth, 'SampleRate', obj.fs);
        end
        
        function value = get.transmitter(obj)
            value = phased.Transmitter('PeakPower', db2pow(obj.tx_power) * 1e-3, 'Gain', obj.tx_gain);
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
    end
end