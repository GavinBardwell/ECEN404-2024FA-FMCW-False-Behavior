clear;

%constants
c = physconst('LightSpeed');

%define sim values
range = 100;%in meters
velocity = 0;%in m/s, for the attacker

%define victim
fc = 77e9;
freq_sample = 1e6;%sampling frequency
bandwidth = 100e3;%bandwidth
SweepTime = 1e-4;%chirp duration

%assume victim is standing still
%sets transmitted parameters
transmitted = phased.FMCWWaveform('SampleRate', freq_sample, 'SweepBandwidth', bandwidth,...
    'OutputFormat','Sweeps','NumSweeps',2, 'SweepTime', SweepTime);
plot(transmitted);

waveform = transmitted();%create 2 
plot(waveform);
%figure out what the waveform will look like at the target distance
phased.FreeSpace('PropagationSpeed', c, 'OperatingFrequency', fc, 'SampleRate',freq_sample, 'TwoWayPropagation',true);
%define attacker
%options
% 1) benign object, just reflect the waveform and send it back
% 2) black hat, uses defined algorithm using sent waveform to create waveform to send back

%victim processing

%display data