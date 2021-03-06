function [data, filePath] = FETDataRead(filePath)
% FETDataRead reads data from a text file with FET characteristics
%
%   The function reads the delimited data stored in the file and saves it
%   in an output matrix. It also performs several checks to confirm that
%   the file contains transfer characteristics in the linear and saturation
%   regime.
%
%   INPUT:
%   path2File       - full path to file with data, user is prompted to 
%                     select a file if not given
%
%   OUTPUT:
%   data.type       - string specifying type of data (transfer or output)
%   data.x          - vector containing x-axis data (gate or drain voltage)
%   data.Is         - matrix containing source current data
%   data.Id         - matrix containing drain current data
%   data.Ig         - matrix containing gate current data
%   data.Vstep      - vector containing the drain or gate voltage steps
%   data.DataMatrix - matrix containing the raw data from file
%   data.path       - file path
%   data.title      - title (file name without extension)
%
%   Sam Schott, 06.10.2017
%   ss2151@cam.ac.uk
%

global path

V_DRAIN_IDENTIFIERS = {'Vd', 'Drain voltage'};
V_GATE_IDENTIFIERS = {'Vg', 'Gate voltage'};

I_SOURCE_IDENTIFIERS = {'Is', 'source', 'Source current'};
I_DRAIN_IDENTIFIERS = {'Id', 'Isd', 'Drain current'};
I_GATE_IDENTIFIERS = {'Ig', 'Gate current'};

if nargin==0
    [fileName, dirName] = uigetfile([path, '*.txt'], 'Select file');
    filePath = fullfile(dirName, fileName);
    % output empty matrix if no file is selected
    if fileName == 0
        data = [];
        return;
    end
    path = dirName;
end

S = importdata(filePath);

% save raw data to output structure
data.DataMatrix = S.data;

% check if data is from output or transfer curve
if isinstring(S.colheaders{1}, V_DRAIN_IDENTIFIERS)
    data.type = 'output';
elseif isinstring(S.colheaders{1}, V_GATE_IDENTIFIERS)
    data.type = 'transfer';
else
    error('Data has a unknown format. Please check if you have selected the right file.');
end

% save x-axis data to output structure
data.x = data.DataMatrix(:, 1);

% find colummns with source, drain and gate currents
check_source = isinstring(S.colheaders, I_SOURCE_IDENTIFIERS);
check_drain = isinstring(S.colheaders, I_DRAIN_IDENTIFIERS);
check_gate = isinstring(S.colheaders, I_GATE_IDENTIFIERS);
if sum(check_drain) == 0 || sum(check_gate) == 0
    error('The data file is imcomplete. Please check the format of your data');
end

% extract data to ouput structure
data.Is = data.DataMatrix(:, check_source);
data.Id = data.DataMatrix(:, check_drain);
data.Ig = data.DataMatrix(:, check_gate);

% calculate source values if not provided
if isempty(data.Is)
    data.Is = data.Id + data.Ig;
end

% determine stepped voltage values and save as vector
step_names = S.colheaders(check_drain);

data.Vstep = [];
nsteps = sum(check_drain);

for i = 1:nsteps
    find = regexp(step_names{i}, '(\d+(\.\d+)*)', 'match');
    data.Vstep(i) = str2double(find);
end

[~, name, ~] = fileparts(filePath);

data.path = filePath;
data.title = name;

end
