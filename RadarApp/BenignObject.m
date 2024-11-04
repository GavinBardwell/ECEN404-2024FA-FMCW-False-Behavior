classdef BenignObject
    %Contains all information of a benign object in our environment    
    properties
        position
        velocity
        rcs
    end
    
    methods
        function obj = BenignObject(params)
                %constructor
                if(nargin == 3)
                    obj.position = params.position;
                    obj.velocity = params.velocity;
                    obj.rcs = params.rcs;
                end
        end
        
        function obj = setPosition(position)
            obj.position = position;
        end
        
        function obj = setVelocity(velocity)
            obj.velocity = velocity;
        end
    end
end

