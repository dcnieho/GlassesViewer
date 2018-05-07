function out = bounds2bool(lo, hi, maxlen)
%BOUNDS2BOOL Create boolean index vector given bounds for index values.
%
%   BOUNDS2BOOL(LO, HI) will, when given two vectors LO and HI, return the
%   an index vector that is true at indices [LO(1):HI(1) LO(2):HI(2) ...].
%
%   BOUNDS2BOOL(LO, HI, LEN) creates a vector of length LEN.
%
%   See also bounds2ind

%   Author:      Diederick C. Niehorster
%   based on bounds2ind, by:
%   Author:      Peter John Acklam
%   Time-stamp:  2001-10-23 17:05:58 +0200
%   E-mail:      pjacklam@online.no
%   URL:         http://home.online.no/~pjacklam

% check number of input arguments
narginchk(2, 3);

% keep only runs of positive length.
i = lo <= hi;
lo = lo(i);
hi = hi(i);

if nargin==3
    % prune off indices that lay outside max vector length
    i = lo <= maxlen;
    lo = lo(i);
    hi = hi(i);
    if ~isempty(hi) && hi(end) > maxlen
        hi(end) = maxlen;
    end
end

% return empty or all false when bounds are empty
if isempty(lo)
    if nargin==3
        out = false(1, maxlen);
    else
        out = [];
    end
    return;
end

m   = length(lo);           % length of input vectors
len = hi - lo + 1;          % length of each run
n   = sum(len);             % length of index vector
idx = ones(1, n);           % initialize index vector

if nargin<3                 % length of output vector
    maxlen = sum(len);
end
out = false(1, maxlen);     % initialize output vector

idx(1) = lo(1);
len(1) = len(1) + 1;
idx(cumsum(len(1:end-1))) = lo(2:m) - hi(1:m-1);
idx = cumsum(idx);

out(idx)=true;
