classdef primaryRadar
    %This class holds and calculates all information needed for the primary
    %radar
    %   Detailed explanation goes here

    properties
        Property1
    end

    methods
        function obj = primaryRadar(inputArg1,inputArg2)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end

        function obj = setRadar(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end