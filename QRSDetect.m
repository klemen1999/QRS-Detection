function [idx] = QRSDetect(fileName, M, Fs)
    S = load(fileName);
    sig = S.val(1,:);
    
    % Constants:
    ALPHA = 0.01 + (0.1-0.01).*rand();
    GAMMA = 0.15;
    FEATURE_LEN = 150;
    
    if mod(M,2) == 0
        error("M must be an odd number");
    end
    
    % Original Preprocessing
    %{
    % High Pass
    b1 = 1/M * ones(1,M);
    y1 = filter(b1,1,sig);
    addedDelay = (M+1)/2;
    y2 = [zeros(1,addedDelay), sig(1:end-addedDelay)];
    sig_h = y2-y1;
    
    % Low pass
    windowSize = 15;
    sig_l = sig_h.^2;
    b2 = ones(1, windowSize);
    sig_l = filter(b2, 1, sig_l);
    
    processedSig = sig_l;
    %}

    % More complex preprocessing from Pan-Tompkins Algorithm
    % sig_bp = signal filtered with bandpass filter
    % sig_d = signal after derivative
    % processedSig = signal after full preprocessing
    % delay = total delay added with this preprocessing
    [sig_bp, sig_d, processedSig, delay] = preprocess(sig);

    % Decision making stage
    
    i = FEATURE_LEN/2+1;
    threshold = max(processedSig(1:Fs*1))*0.75;
    idx = [];
    
    while i < length(processedSig)-FEATURE_LEN/2
        currWindow = processedSig(i-FEATURE_LEN/2:i+FEATURE_LEN/2);
        [maxVal, maxIx] = max(currWindow);
        

        % Original threshold algorithm
        %{
        if maxVal > threshold
            currIx = i+maxIx-FEATURE_LEN/2;
            idx = [idx, currIx];
            threshold = ALPHA*GAMMA*maxVal + (1-ALPHA)*threshold;
        end
        %}
        
        % Next QRS can't be closer than 200ms to previous one
        %{
        if maxVal > threshold
            currIx = i+maxIx-FEATURE_LEN/2;
            if ~isempty(idx) && currIx-idx(end) >= Fs*0.2
                idx = [idx, currIx];
                threshold = ALPHA*GAMMA*maxVal + (1-ALPHA)*threshold;
            elseif isempty(idx)
                idx = [idx, currIx];
                threshold = ALPHA*GAMMA*maxVal + (1-ALPHA)*threshold;
            end
        end
        %}
        
        
        % If next QRS is within 200-360ms from previous check if it isn't
        % just a high T-wave based on slope
        if maxVal > threshold
            currIx = i+maxIx-FEATURE_LEN/2;
            if ~isempty(idx) && currIx-idx(end) >= Fs*0.2 && ...
                    currIx-idx(end) <= Fs*0.36
                slopePrev = mean(sig_d(idx(end)-10:idx(end)));
                slopeNow = mean(sig_d(currIx-10:currIx));
                if slopeNow >= 0.5*slopePrev
                    idx = [idx, currIx];
                    threshold = ALPHA*GAMMA*maxVal + (1-ALPHA)*threshold;
                end
            elseif ~isempty(idx) && currIx-idx(end) >= Fs*0.2 || isempty(idx)
                idx = [idx, currIx];
                threshold = ALPHA*GAMMA*maxVal + (1-ALPHA)*threshold;
            end
        end
        
        i = i + FEATURE_LEN + 1;
    end
end


% Preprocessing ispired by Pan-Tompikins algorithm
function [sig_bp, sig_d, sig_m, delay] = preprocess(sig)
    % Low pass: H(z)=(1-z^-6)^2/(1-z^-1)^2
    b = [1, zeros(1,4),-2, zeros(1,4), 1];
    a = [1, -2, 1];
    sig_l = filter(b,a,sig);
    delay = 6;
    
    % High pass: H(z)=(-1+32z^-16+z^-32)/(1+z^-1)
    b= zeros(1,33);
    b(1) = -1; b(16) = 32; b(32) = 1;
    a= [1, 1];
    sig_h = filter(b,a,sig_l);
    delay = delay + 16;

    % Derivative: H(z) = (1/8T)(-z^(-2) - 2z^(-1) + 2z + z^(2))
    h = [-1, -2, 0, 2, 1];
    sig_d = conv(sig_h, h);
    delay = delay + 2;

    % Squaring
    sig_s = sig_d.^2;

    % Moving average (over 30 samples for fs=200)
    h = ones(1, 30);
    sig_m = conv(sig_s, h);
    delay = delay + 15;
    sig_bp = sig_h(delay:end);
    sig_d = sig_d(delay:end);
    sig_m = sig_m(delay:end);
end