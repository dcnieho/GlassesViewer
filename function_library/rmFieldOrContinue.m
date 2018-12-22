function t = rmFieldOrContinue(s,field)
% adaptation of rmfield that does not error if fields do not exist, but
% just deletes all those that do exist

% almost all code is copied from rmfield itself, just some small
% adaptations made

% handle input arguments
if ~isa(s,'struct') 
    error('MATLAB:rmfield:Arg1NotStructArray', 'S must be a structure array.'); 
end
if ~ischar(field) && ~iscellstr(field)
   error('MATLAB:rmfield:FieldnamesNotStrings',...
      'FIELDNAMES must be a string or a cell array of strings.');
elseif ischar(field)
   field = cellstr(field); 
end

% get fieldnames of struct
f = fieldnames(s);

% Determine which fieldnames to delete.
idxremove = [];
for i=length(field):-1:1
  j = find(strcmp(field{i},f) == true);
  if isempty(j)
    if length(field{i}) > namelengthmax
      error('MATLAB:rmfield:FieldnameTooLong',...
        'The string ''%s''\nis longer than the maximum MATLAB name length.  It is not a valid fieldname.',...
        field{i});
    else
      % DCN: no error when fieldname doesn't exist, just skip it for
      % removing
      continue;
    end
  end
  idxremove = [idxremove;j];
end

if ~isempty(idxremove)  % DCN: its possible there is nothing to remove
  % set indices of fields to keep
  idxkeep = 1:length(f);
  idxkeep(idxremove) = [];

  % remove the specified fieldnames from the list of fieldnames.
  f(idxremove,:) = [];

  % convert struct to cell array
  c = struct2cell(s);

  % find size of cell array
  sizeofarray = size(c);
  newsizeofarray = sizeofarray;

  % adjust size for fields to be removed
  newsizeofarray(1) = sizeofarray(1) - length(idxremove);

  % rebuild struct
  t = cell2struct(reshape(c(idxkeep,:),newsizeofarray),f);
else
  t = s;
end