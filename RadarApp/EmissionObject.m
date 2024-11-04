classdef EmissionObject
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
    end
end
