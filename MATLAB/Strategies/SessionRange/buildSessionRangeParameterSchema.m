function schema = buildSessionRangeParameterSchema()
%BUILDSESSIONRANGEPARAMETERSCHEMA Defaults congelados de la variante.

schema = buildCRT3HParameterSchema();
entry = schema.name=="crt3h.entryFraction";
target = schema.name=="crt3h.rewardRisk";
schema.default_value(entry) = 0.60;
schema.default_value(target) = 0.66;
schema.label(entry) = "Session Range Entry Fraction";
schema.label(target) = "Session Range Target R Multiple";
schema.description(entry) = ...
    "Progress from swept session extreme toward opposite range extreme";
end
