function mark = timeToMark(time,fs)
% marks are 1-based, corresponding to t=0s
mark = round(time*fs)+1;
end