function isFalse = detectFalseBehavior(simData)
    %{
    sim data will be the data post fft. It will be in the form
    simData.resp -- Resp is a MxP matrix. This is the response of the input signal from FFT
    
    simData.rng_grid -- rng_grid is the range samples at which range-doppler response is
        evaulated, grid column of length M
    
    simData.dop_grid -- dop_grid is the frequency samples that range dop is evaluates 
    %}
    %USER CODE GOES HERE
        isFalse = false();
    %%USER CODE GOES HERE
end

