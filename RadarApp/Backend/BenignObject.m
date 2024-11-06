classdef BenignObject < handle
    %Contains all information of a benign object in our environment    
    properties (Access = private, Constant, Hidden =true)
        c= 3e8
    end
    properties (Dependent, Hidden = true)
        motion
    end
     properties
        position
        velocity
        rcs
     end
     properties (Hidden = true)
        target
    end
    
    methods
        function obj = BenignObject(params)
                %constructor
                obj.position = params.position;
                obj.velocity = params.velocity;
                obj.rcs = params.rcs;
        end
        
        function obj = setPosition(position)
            obj.position = position;
        end
        
        function obj = setVelocity(velocity)
            obj.velocity = velocity;
        end
        function calculateTarget(obj, operatingFreq)
            obj.target = phased.RadarTarget('MeanRCS', obj.rcs, 'PropagationSpeed', obj.c, 'OperatingFrequency', operatingFreq);
        end
        function value = get.motion(obj)
            value = phased.Platform('InitialPosition', obj.position, 'Velocity', obj.velocity);
        end
        function returnedObject = saveObject(obj)
            returnedObject = struct;
            returnedObject.position = obj.position;
            returnedObject.velocity = obj.velocity;
            returnedObject.rcs = obj.rcs;
        end
    end
end

