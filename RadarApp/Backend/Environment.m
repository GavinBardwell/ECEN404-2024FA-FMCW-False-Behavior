classdef Environment
    %ENVIRONMENT Summary of this class goes here    
    properties
        benign_objects
        emission_objects
        floor = NaN;
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
            obj.floor = obj.setFloor(config.floor);
        end

        function benign_objects = setBenigns(~, benign_data)
            % Create an array of BenignObject instances from the benign data
            benign_objects = BenignObject.empty;
            for i = 1:length(benign_data)
                params.position = benign_data(i).position;
                params.velocity = benign_data(i).velocity;
                params.rcs = benign_data(i).rcs;
                benign_objects(i) = BenignObject(params);
            end
        end
        function setTargets(obj, operatingFrequency)
            for i = 1:length(obj.benign_objects)
               obj.benign_objects(i).calculateTarget(operatingFrequency);
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
    % Save the environment data into a struct
    returnedEnvironment = struct();
    
    % Initialize benign_objects struct array
    if ~isempty(obj.benign_objects)
        benign_structs = repmat(obj.benign_objects(1).saveObject(), 1, length(obj.benign_objects));
        for i = 1:length(obj.benign_objects)
            benign_structs(i) = obj.benign_objects(i).saveObject();
        end
    else
        benign_structs = struct([]);
    end
    returnedEnvironment.benign_objects = benign_structs;
    
    % Initialize emission_objects struct array
    if ~isempty(obj.emission_objects)
        emission_structs = repmat(obj.emission_objects(1).saveObject(), 1, length(obj.emission_objects));
        for i = 1:length(obj.emission_objects)
            emission_structs(i) = obj.emission_objects(i).saveObject();
        end
    else
        emission_structs = struct([]);
    end
    returnedEnvironment.emission_objects = emission_structs;
    returnedEnvironment.floor = obj.floor;
end



    % Uncomment and complete the methods below if needed
    function floor = setFloor(floor, height)
         % Sets the floor of the scenario
         floor = height;
    end

        % function obj = setNoise(obj)
        %     % Sets the surrounding noise vector
        %     obj.noise = 1;
        % end
    end
end
