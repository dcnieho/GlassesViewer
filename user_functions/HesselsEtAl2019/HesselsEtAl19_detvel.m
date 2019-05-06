function [v] = HesselsEtAl19_detvel(x,time)

dt1	= time(2:end-1) - time(1:end-2);
dx1	= x(2:end-1)    - x(1:end-2);
dt2	= time(3:end)   - time(2:end-1);
dx2	= x(3:end)      - x(2:end-1);
v	= [NaN;(dx1./dt1 + dx2./dt2)/2;NaN];
