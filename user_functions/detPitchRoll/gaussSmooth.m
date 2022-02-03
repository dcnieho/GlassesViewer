function [y_eval, dataWeight] = gaussSmooth(x, y, newX, sigma)
% Function from Jonathan's SMART
%
%     Smooths data using a Gaussian kernel.
%     Assumes that x and y are linked, e.g. x[0] and y[0] come from
%     the same trial.
%
%     Parameters
%     ----------
%     x : np.array
%         The temporal variable, e.g. reaction time
%     y : np.array
%         The dependent variable, e.g. performance
%     newX : np.array
%         The new temporal time points. e.g. RT from 100 ms to 500 ms
%         in 1 ms steps
%     sigma : int or float
%         The width of the Gaussian kernel
%
%     Returns
%     -------
%     smoothY : np.array
%         The smoothed dependent variable as a function of newX
%     weights : np.array
%         The sum of weights under the Gaussian for each new time point.
%         Used for weighted average across participants

if 0
    delta_x = newX' - x;
    
    % Calculate weights
    weights = exp(-delta_x.*delta_x / (2*sigma*sigma));
    dataWeight = sum(weights, 2, 'omitnan');
    weights = weights ./ dataWeight;
    
    for p=size(y,1):-1:1
        y_eval(:,p) = weights*y(p,:)';
    end
else
    % this version is almost as fast with matlab JIT, but much less memory
    % consumption
    for q=length(newX):-1:1
        delta_x = newX(q) - x;
        
        % Calculate weights
        weights = exp(-delta_x.*delta_x / (2*sigma*sigma));
        dataWeight(q) = sum(weights, 'omitnan');
        weights = weights ./ dataWeight(q);
        
        for p=size(y,1):-1:1
            y_eval(q,p) = weights*y(p,:)';
        end
    end
end

return