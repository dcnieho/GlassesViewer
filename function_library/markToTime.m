function time = markToTime(mark,fs)
% marks are 1-based, corresponding to t=0s
time = (mark-1)./fs;
end