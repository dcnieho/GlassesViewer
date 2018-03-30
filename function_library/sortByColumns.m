function x=sortByColumns(x,cols)
if ~iscell(cols), cols = {cols}; end
% do back to front (like sortrows, see doc there) to get wanted effect
cols = cols(end:-1:1);

tidx = [1:length(x.(cols{1}))].';
for p=1:length(cols)
    [~,sidx]    = sort(x.(cols{p})(tidx,:));
    tidx        = tidx(sidx);
end

x = structfun(@(x) x(tidx,:),x,'uni',false);
end