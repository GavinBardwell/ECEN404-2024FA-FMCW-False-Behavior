clear;
% Define Radar paramters
radar.f0 = 76e9;                % Start frequency
radar.SweepTime = 12.8e-6;      % Chirp duration
radar.B = 200e6;                % Bandwidth
radar.f_ADC = 80e6;             % ADC sampling rate
radar.Slope = radar.B/radar.SweepTime;

% Setting up target parameters
range = 200;

c = physconst('LightSpeed');

% Delay of the reflected signal
tau = 2*range/c;


% Setting up sampling frequency
fs = 2*(radar.f0 + radar.B);

% Fast time 
tFast = 0:1/fs:radar.SweepTime-1/fs;

% Inline function to simulate chirp
hdl_chirp = @(radar,t)(real(exp(1j*2*pi*(radar.f0*t + 0.5*radar.Slope*t.^2))));

% Tx chirp
s_tx = real(hdl_chirp(radar, tFast));
figure; plot(tFast,real(s_tx))          %plot of Transmitted signal
figure; plot(tFast, real(s_tx), 'k');   %plot of transmitted signal on combined plot

% Fast time for reflected chirp
tRx = (tFast - tau);

% Blanking
win_rx = (tFast>=tau) .* (tFast<radar.SweepTime); 

% Rx chirp
s_rx = win_rx.* hdl_chirp(radar, tRx);
hold; plot(tFast, real(s_rx), '-r');    %plot of recieved signal on combined plot
legend('tx', 'rx')
xlim('padded')

% Mixing
s_mix = s_rx.*s_tx;

% LPF
fPassLPF = 20e6;
s_rx_LPF = lowpass(s_mix, fPassLPF, fs, ImpulseResponse="iir", Steepness=0.85);
figure; plot(tFast,s_rx_LPF)            %plot if mixed signal after lowpass


% ADC sampling
[P,Q] = rat(radar.f_ADC/fs);
s_rx_ADC = resample(s_rx_LPF,P,Q);

% Range fft
nFFT = length(s_rx_ADC);
s_R = fftshift(fft(s_rx_ADC, nFFT)).*1/(nFFT/2);

% Plotting range profile
rmax = c*radar.f_ADC/2/radar.Slope;
raxis = linspace(-rmax/2, rmax/2, length(s_rx_ADC));
figure; stem(raxis, abs(s_R).^2);       %plot of FFT of mixed signal
xlabel('Range (m)'); ylabel('Power')
xlim([0, rmax/2])