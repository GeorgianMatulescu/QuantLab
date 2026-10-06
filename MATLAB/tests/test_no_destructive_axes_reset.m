clear;
clc;

matlabRoot = fileparts(fileparts(mfilename('fullpath')));
componentRoot = fullfile( ...
    matlabRoot,"Dashboard","Components");

files = [ ...
    "resetDashboardAxes.m"; ...
    "resetResearchAxes.m"; ...
    "clearDashboardAxesSafely.m"];

for i = 1:numel(files)
    source = string(fileread(fullfile(componentRoot,files(i))));
    lines = splitlines(source);

    % Analizar únicamente líneas que no sean comentarios completos.
    executableLines = lines(~startsWith(strtrim(lines),"%"));
    executableSource = join(executableLines,newline);

    assert(~contains(executableSource,"allchild("), ...
        "%s vuelve a utilizar allchild.",files(i));

    assert(isempty(regexp( ...
        char(executableSource), ...
        'cla\s*\(\s*ax\s*,\s*["'']reset["'']\s*\)', ...
        'once')), ...
        "%s vuelve a utilizar cla reset.",files(i));
end

safeSource = fileread(fullfile( ...
    componentRoot,"clearDashboardAxesSafely.m"));

assert(contains(safeSource,"children = ax.Children"));
assert(contains(safeSource,'ax.NextPlot = "replace"'));

fprintf("TEST NO DESTRUCTIVE AXES RESET SUPERADO\n");
