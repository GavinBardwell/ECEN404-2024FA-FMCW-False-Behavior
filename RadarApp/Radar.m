classdef Radar
    %This class holds and calculates all information needed for the primary
    %radar
    %   Detailed explanation goes here

    properties
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
    end

    methods
        function obj = Radar(inputArg1,inputArg2)
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