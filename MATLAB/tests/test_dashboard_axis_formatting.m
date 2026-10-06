clear;
clc;

fig = figure("Visible","off");
cleanup = onCleanup(@() close(fig));

axNumeric = axes(fig);
plot(axNumeric,1:3,[49500 50000 50500]);
formatAxesNatural(axNumeric,"money");

clf(fig);

axCategorical = axes(fig);
barh(axCategorical,categorical(["A","B","C"]),[1 2 3]);

% No debe lanzar error aunque el eje Y sea categórico.
formatAxesNatural(axCategorical,"money");

fprintf("TEST DASHBOARD AXIS FORMATTING SUPERADO\n");
