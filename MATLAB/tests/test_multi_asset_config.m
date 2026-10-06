matlabRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(genpath(matlabRoot));

mnq = loadQuantLabConfig(matlabRoot,"MNQ");
mes = loadQuantLabConfig(matlabRoot,"MES");
mym = loadQuantLabConfig(matlabRoot,"MYM");

assert(mnq.instrumentSpec.tickSize==0.25);
assert(mnq.instrumentSpec.contractMultiplier==2);
assert(mes.instrumentSpec.tickSize==0.25);
assert(mes.instrumentSpec.contractMultiplier==5);
assert(mym.instrumentSpec.tickSize==1);
assert(mym.instrumentSpec.contractMultiplier==0.5);
assert(mym.exchange=="CBOT");

assert(endsWith(mes.dataFile, ...
    fullfile("MES","1_min","MES_CONTFUT_1_min_ALL.csv")));
assert(endsWith(mym.dataFile, ...
    fullfile("MYM","1_min","MYM_CONTFUT_1_min_ALL.csv")));

assert(mnq.executionProfiles(2).entrySlippagePoints==0.25);
assert(mes.executionProfiles(2).entrySlippagePoints==0.25);
assert(mym.executionProfiles(2).entrySlippagePoints==1);
assert(mym.executionProfiles(3).stopSlippagePoints==4);

fprintf("TEST MULTI ASSET CONFIG SUPERADO\n");
