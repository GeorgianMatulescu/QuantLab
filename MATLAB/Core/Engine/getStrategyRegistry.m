function registry = getStrategyRegistry()
%GETSTRATEGYREGISTRY Registro dinámico de plugins instalados.
registry = discoverStrategyPlugins();
end
