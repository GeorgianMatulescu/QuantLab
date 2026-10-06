function validateTemplateBarConfig(cfg)
%VALIDATETEMPLATEBARCONFIG Add strategy-specific config checks here.
normalizeInstrumentSpec(cfg);
normalizeSessionSpec(cfg);
end
