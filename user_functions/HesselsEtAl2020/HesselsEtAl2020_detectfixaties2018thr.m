function [thrfinal] = HesselsEtAl2020_detectfixaties2018thr(mvel,f)

% cleaned up on
% 16 october 2011 IH

thr             = f.thr;

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

thr2            = meanvel + f.lambda*stdvel;        % determine new threshold based on data noise

% make vector for thr2 of length mvel
thrfinal        = repmat(thr2,numel(mvel),1);