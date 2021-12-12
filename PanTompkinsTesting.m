path = "./ltstDB/s20011m.mat";
S = load(path);
sig1 = S.val(1,:);
sig1 = sig1(:,1:5000);
%fs = 250;
Fs = 200;

[sig_bp, sig_d, sig_m, delay] = preprocess(sig1);

% Learning phase 1
TRAIN_SEC = 2;
% On signal filtered with moving average
trainSig_m = sig_m(1:Fs*TRAIN_SEC);

SPKI = max(trainSig_m)*0.25;
NPKI = mean(trainSig_m)*0.5;
THRESHOLD_I1 = NPKI + 0.25*(SPKI-NPKI);
THRESHOLD_I2 = 0.5 * THRESHOLD_I1;

% On signal filtered with bandpass filter
trainSig_bp = sig_bp(1:Fs*TRAIN_SEC);

SKPF = max(trainSig_bp)*0.25;
NKPF = mean(trainSig_bp)*0.5;
THRESHOLD_F1 = NKPF + 0.25*(SKPF-NKPF);
THRESHOLD_F2 = 0.5*THRESHOLD_F1;

% Learning phase 2
TRAIN_SEC_2 = 10;
trainSig_m2 = sig_m(1:Fs*TRAIN_SEC_2);
[peaks_m,peaksLocs_m] = findpeaks(trainSig_m2,'MINPEAKDISTANCE',round(0.2*Fs));
overThreshold = peaks_m>THRESHOLD_I1;
peaks_m = peaks_m(overThreshold);
peaksLocs_m = peaksLocs_m(overThreshold);
%figure(2);plot(trainSig_m2); hold on; plot(peaksLocs_m, peaks_m,".",'MarkerSize',20);

rrIntervals = peaksLocs_m(2:end)-peaksLocs_m(1:end-1);
RR_AVG1 = mean(rrIntervals);
RR_AVG2 = mean(rrIntervals);
RR_LOW = 0.92*RR_AVG2;
RR_HIGH = 1.16*RR_AVG2;
RR_MISSED = 1.66*RR_AVG2;

% Algorithem starts
RR1_BUFFER = peaksLocs_m(end);
RR2_BUFFER = peaksLocs_m(end);
QRS_ix = peaksLocs_m+delay;
previousSlope = sig_d(peaksLocs_m(end));


PEAK_INTERVAL = round((0.2*Fs)/2);
i=TRAIN_SEC_2*Fs;
while i < length(sig_m)-PEAK_INTERVAL
    currWindow = sig_m(i-PEAK_INTERVAL:i+PEAK_INTERVAL);
    [maxVal, maxIx] = max(currWindow);
    % Found a peak
    if maxIx == PEAK_INTERVAL+1
        % Peak is signal peak
        if sig_bp(i)>THRESHOLD_F1
            disp("test")
        end
        if sig_m(i) > THRESHOLD_I1 && sig_bp(i) > THRESHOLD_F1
            % check if new detection is within 360ms after last one
            if i-QRS(end) < Fs*0.36
                % might be T-wave
                currentSlope = sig_d(i);
                if currentSlove > previousSlope/2
                    QRS_ix= [QRS, i+TRAIN_SEC_2*Fs+delay];
                    % set i to i+200ms
                    i = i+0.2*Fs;
                end
            else
                QRS_ix= [QRS, i+TRAIN_SEC_2*Fs+delay];
                % set i to i+200ms
                i = i+0.2*Fs;
            end
        elseif sig_m(i) < THRESHOLD_I2 && sig_bp(i) < THRESHOLD_F2
        end
    end
    i = i+1;
end

plot(sig_bp);
%figure(1);plot(trainSig_bp); hold on; plot(peaksLocs_bp, peaks_bp,".",'MarkerSize',20);
%figure(2);plot(trainSig_m); hold on; plot(peaksLocs_m, peaks_m,".",'MarkerSize',20);
%disp(peaksLocs_bp);
%disp(peaksLocs_m);

%figure(1); plot(sig1);
%figure(2); plot(sigPreprocessed);
%{
trainSig_m = sig_m(1:Fs*TRAIN_SEC);
trainSig_bp = sig_h(1:Fs*TRAIN_SEC);

%[peaks,peaksLocs] = findpeaks(trainSig_bp,'MINPEAKDISTANCE',round(0.2*Fs));
%plot(trainSig_bp); hold on; plot(peaksLocs, peaks,".",'MarkerSize',20); hold on;



% Learning phase 2


a=[];b=[];
for i=Fs*TRAIN_SEC:length(sig1)-PEAK_INTERVAL
    currWindow_m = sig_m(i-PEAK_INTERVAL-delay:i+PEAK_INTERVAL-delay);
    currWindow_h = sig_h(i-PEAK_INTERVAL-6-16:i+PEAK_INTERVAL-6-16);
    [maxVal_m, maxIx_m] = max(currWindow_m);
    [maxVal_h, maxIx_h] = max(currWindow_h);
    if maxIx_h==PEAK_INTERVAL+1
        % We found a peak that we need to classify
        a=[a, maxIx_h+i+PEAK_INTERVAL+1];
        b=[b, maxVal_h];
        display("test");
    end
end
%}
%figure(1)
%plot(sig_m(Fs*TRAIN_SEC:length(sig_m)-PEAK_INTERVAL));


%fprintf("SPKI:%d, NPKI:%d, THR1:%d, THR2:%d\n", SPKI, NPKI, THRESHOLD_I1, THRESHOLD_I2);
%plot(trainSig_m); hold on; plot(peaksLocs, peaks,".",'MarkerSize',20); hold on;
%plot((1:400), ones(1,400)*THRESHOLD_I1); hold on; plot((1:400), ones(1,400)*THRESHOLD_I2);

% Fiducial points
%[pks,locs] = findpeaks(sigPreprocessed,'MINPEAKDISTANCE',round(0.2*fs));



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

