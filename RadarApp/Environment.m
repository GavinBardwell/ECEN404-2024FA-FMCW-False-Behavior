classdef Environment
    %ENVIRONMENT Summary of this class goes here    
    properties
        benign_objects
        emission_objects
        % floor
        % noise
    end
    
    methods
        function obj = Environment()
            %ENVIRONMENT Construct an instance of this class
            obj.benign_objects = [];
            obj.emission_objects = [];
            % obj.floor = 0;
            % obj.noise = 0; 
        end
    
        function obj = loadEnvironment(obj, config)
            % loads the environment from the config file
            obj.benign_objects = obj.setBenigns(config.benign_objects);
            obj.emission_objects = obj.setEmissions(config.emission_objects);
        end

        function benign_objects = setBenigns(~, benign_data)
            % Create an array of BenignObject instances from the benign data
            benign_objects = BenignObject.empty;
            for i = 1:length(benign_data)
                params.position = benign_data(i).position;
                params.velocity = benign_data(i).velocity;
                params.rcs = benign_data(i).rcs_offset;
                benign_objects(i) = BenignObject(params);
            end
        end

        function emission_objects = setEmissions(~, emission_data)
            % Create an array of EmissionObject instances from the emission data
            emission_objects = EmissionObject.empty;
            for i = 1:length(emission_data)
                params.fc = emission_data(i).fc;
                params.range_max = emission_data(i).range_max;
                params.range_res = emission_data(i).range_res;
                params.v_max = emission_data(i).v_max;
                params.tx_power = emission_data(i).tx_power;
                params.tx_gain = emission_data(i).tx_gain;
                params.position = emission_data(i).position;
                params.velocity = emission_data(i).velocity;
                emission_objects(i) = EmissionObject(params);
            end
        end

        function returnedEnvironment = saveEnvironment(obj)
            % returns the necessary environment values to be saved
            returnedEnvironment.benign_objects = obj.benign_objects;
            returnedEnvironment.emission_objects = obj.emission_objects;
        end

        % Uncomment and complete the methods below if needed
        % function obj = setFloor(obj, height)
        %     % Sets the floor of the scenario
        %     obj.floor = height;
        % end

        % function obj = setNoise(obj)
        %     % Sets the surrounding noise vector
        %     obj.noise = 1;
        % end
    end
end
