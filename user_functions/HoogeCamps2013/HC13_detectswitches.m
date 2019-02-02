function [on2,off2] = HC13_detectswitches(data)
% feed this fucntion a boolean vector (zeros and ones only). 
% if it contains a series of ones it will return the start and end position

% add zeros to beginning and end, such that ones at the beginning and end of
% the original data file get ercognized as such
data	= [0 data 0];

% find the transitions by using the shifting trick
data11	= data(1:end-1);
data12	= data(2:end);

numvect	= [1:1:length(data11)];

mdata	= data11 - data12;
on		= mdata == -1;				% this is a sample to early
off		= mdata == 1;				% this is the correct one

on2		= numvect(on);              % correct for the index of too early
off2	= numvect(off)-1;
