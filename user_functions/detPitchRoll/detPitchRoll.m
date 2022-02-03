function [output] = detPitchRoll(data, params)

% This script estimates roll and pitch angle for the accelerometer and 
% gryoscope in the Tobii Glasses 2 based on 
% https://philsal.co.uk/projects/imu-attitude-estimation

% NOTE: The coordinate system for the Tobii Glasses 2 has its origin in the
% scene camera, with Z pointing forward in the world, X is towards the left
% eye w.r.t. the scene camera, Y is upward w.r.t. the scene camera.

% Gyroscope reports rotation along the X, Y and Z axis in degrees/second.
% Accelerometer return acceleration along X, Y and Z axis in meter/second^2

% For details see Tobii Glasses 2 Analyzer Manual

dt = 1/params.fs; % inter-sample interval

%% pre-process data
% split out accelerometer data in its components
% roll is angle along x-axis (in below example Philip Salmony)
% pitch is angle along y-axis (in below example Philip Salmony)
% for Tobii matrices [x y z]: z is straight ahead, x is to left of camera, y is upward

Ax = data.accelerometer.ac(:,3); % X for Philip is Tobii's Z
Ay = data.accelerometer.ac(:,1); % Y for Philip is Tobii's X
Az = data.accelerometer.ac(:,2); % Z for Philip is Tobii's Y

Gx = data.gyroscope.gy(:,3); % same for Gyroscope
Gy = data.gyroscope.gy(:,1);
Gz = data.gyroscope.gy(:,2);

%% Resample accelerometer en gyroscope data using Gaussian smoothing

newT = max([data.accelerometer.ts(1) data.gyroscope.ts(1)]):dt:min([data.accelerometer.ts(end) data.gyroscope.ts(end)]);

[An, ~] = gaussSmooth(data.accelerometer.ts', [Ax Ay Az]', newT, params.sigma);
Axn = An(:,1);
Ayn = An(:,2);
Azn = An(:,3);

[Gn, ~] = gaussSmooth(data.gyroscope.ts', [Gx Gy Gz]', newT, params.sigma);
Gxn = Gn(:,1);
Gyn = Gn(:,2);
Gzn = Gn(:,3);

%% Sensor Fusion Demonstration
%
% https://github.com/pms67/Attitude-Estimation/blob/master/attitude_estimation.m
%
% Author: Philip Salmony [pms67@cam.ac.uk]
% Date: 2 August 2018

% Convert gyroscope measurements to radians
Gx_rad = Gxn * pi / 180.0;
Gy_rad = Gyn * pi / 180.0;
Gz_rad = Gzn * pi / 180.0;

% 1) Accelerometer only
roll_hat_acc  = atan2(Ayn, sqrt(Axn .^ 2 + Azn .^ 2));
pitch_hat_acc = atan2(Axn, sqrt(Ayn .^ 2 + Azn .^ 2));

% 4) Kalman Filter
A = [1 -dt 0 0; 0 1 0 0; 0 0 1 -dt; 0 0 0 1];
B = [dt 0 0 0; 0 0 dt 0]';
C = [1 0 0 0; 0 0 1 0];
P = eye(4);
Q = eye(4) * 0.01;
R = eye(2) * 10;
state_estimate = [0 0 0 0]';

roll              = zeros(1, length(newT));
bias_roll_kalman  = zeros(1, length(newT));
pitch             = zeros(1, length(newT));
bias_pitch_kalman = zeros(1, length(newT));

for i=2:length(newT)
    phi_hat   = roll(i - 1);
    theta_hat = pitch(i - 1);
    
    roll_dot  = Gx_rad(i) + sin(phi_hat) * tan(theta_hat) * Gy_rad(i) + cos(phi_hat) * tan(theta_hat) * Gz_rad(i);
    pitch_dot = cos(phi_hat) * Gy_rad(i) - sin(phi_hat) * Gz_rad(i);
    
    % Predict
    state_estimate = A * state_estimate + B * [roll_dot, pitch_dot]';
    P = A * P * A' + Q;
    
    % Update
    measurement = [roll_hat_acc(i) pitch_hat_acc(i)]';
    y_tilde = measurement - C * state_estimate;
    S = R + C * P * C';
    K = P * C' * (S^-1);
    state_estimate = state_estimate + K * y_tilde;
    P = (eye(4) - K * C) * P;
    
    roll(i)             = state_estimate(1);
    bias_roll_kalman(i) = state_estimate(2);
    pitch(i)            = state_estimate(3);
    bias_pitch_kalman(i)= state_estimate(4);
end

% Convert all estimates to degrees
roll  = roll  * 180.0 / pi;
pitch = pitch * 180.0 / pi;

% prep output, one matrix with rotation around Tobii's X (pitch), Y (yaw,
% not available) and Z (roll)
output = {newT.', [pitch.' nan(size(pitch)).' roll.']};

