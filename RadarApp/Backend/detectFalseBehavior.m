
function isFalse = detectFalseBehavior(simData)
    %{
    sim data will be the data post fft. It will be in the form
    simData.resp_frames -- a cell of frames, Resp is a MxP matrix. This is the response of the input signal from FFT
    
    simData.rng_grid -- rng_grid is the range samples at which range-doppler response is
        evaulated, grid column of length M
    
    simData.dop_grid -- dop_grid is the frequency samples that range dop is evaluates 

    It will be also in the form of all the 
    %}
    %USER CODE GOES HERE

    %calculate threshold
    threshLimit = 10;
    threshFrames = simData.resp_frames(1:threshLimit);
    
    % Initialize variables for calculations
    max_values = zeros(1, threshLimit);  % To store the max of each frame
    mean_values = zeros(1, threshLimit); % To store the mean of each frame

    % Loop over the first 5 frames
    %% 
    for i = 1:size(threshFrames, 2)
        frame_data = abs(threshFrames{i}); % Extract the i-th frame data
        max_values(i) = log(max(frame_data(:))); % Take the maximum of the current frame
        mean_values(i) = log(mean(frame_data(:))); % Take the mean of the current frame
    end
    
    % Calculate the overall threshold
    peak_average_threshold = mean(max_values) / mean(mean_values);
    %end threshold calculation

    % Calculate if within range
    false_frames = zeros(1, size(simData.resp_frames, 2));
    for i = threshLimit:size(simData.resp_frames, 2)
        peak_average = peak_to_average(simData.resp_frames(i));
        p_a = peak_average > peak_average_threshold + .5;
        p_a_l = peak_average < (peak_average_threshold - .5);
        
        % Using threshold return true or false
        if p_a || p_a_l
            false_frames(i) = true;
        else
            false_frames(i) = false;
        end
    end

    isFalse = false_frames;
    %%USER CODE GOES HERE
end

function val = peak_to_average(frame)
    magnitude = abs(frame{1}(:)); % Flatten to vector
    val = log(max(magnitude)) / log(mean(magnitude));
end
