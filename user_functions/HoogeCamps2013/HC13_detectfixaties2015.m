function [fmark] = HC13_detectfixaties2015(mvel,f,time)

% cleaned up on
% 16 october 2011 IH

thr             = f.thr;
minfix          = f.minfix;                        % minfix in ms

qvel            = mvel < thr;                      % look for velocity below threshold
qnotnan         = ~isnan(mvel);
qall            = qnotnan & qvel;
meanvel         = mean(mvel(qall));                % determine the velocity mean during fixations
stdvel          = std(mvel(qall));                 % determine the velocity std during fixations

counter         = 0;
oldthr          = 0;
while 1
    thr2        = meanvel + f.lambda*stdvel;
    qvel        = mvel < thr2;                     % look for velocity below threshold
    
    if round(thr2) == round(oldthr) || counter == f.counter % f.counter for maximum number of iterations
        break;
    end
    meanvel     = mean(mvel(qvel));
    stdvel      = std(mvel(qvel));                 % determine the velocity std during fixations    
    oldthr      = thr2;
    counter     = counter + 1;
end

thr2            = meanvel + f.lambda*stdvel;       % determine new threshold based on data noise
qvel            = mvel < thr2;                     % look for velocity below threshold
[on,off]        = HC13_detectswitches(qvel');      % determine fixations

on              = time(on);                        % convcert to time
off             = time(off);                       % convert to time

qfix            = off - on > minfix;               % look for small fixations       
on              = on(qfix);                        % delete fixations smaller than minfix
off             = off(qfix);                       % delete fixations smaller than minfix

on(2:end)       = on(2:end);                       % 
off(1:end-1)    = off(1:end-1);                    % 

fmark           = sort([on;off]);                  % sort the markers
