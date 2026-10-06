clear; clc;
matlabRoot = fileparts(fileparts(mfilename('fullpath')));

folders = [ ...
    fullfile(matlabRoot,"Core","Market"); ...
    fullfile(matlabRoot,"Core","SDK")];

for folder = folders'
    files = dir(fullfile(folder,"*.m"));
    for i = 1:numel(files)
        source = lower(fileread(fullfile(files(i).folder,files(i).name)));
        assert(~contains(source,"orb_range"));
        assert(~contains(source,"emacross"));
        assert(~contains(source,"rewardrisk"));
    end
end

fprintf("TEST GENERIC CORE NO STRATEGY COUPLING SUPERADO\n");
