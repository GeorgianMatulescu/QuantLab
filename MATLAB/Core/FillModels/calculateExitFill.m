function exitPrice=calculateExitFill(side,exitReason,stopPrice,targetPrice,marketClose,profile)
switch upper(exitReason)
    case "STOP"
        if side==1, exitPrice=stopPrice-profile.stopSlippagePoints; else, exitPrice=stopPrice+profile.stopSlippagePoints; end
    case "TARGET"
        if side==1, exitPrice=targetPrice-profile.targetSlippagePoints; else, exitPrice=targetPrice+profile.targetSlippagePoints; end
    case "EOD"
        if side==1, exitPrice=marketClose-profile.entrySlippagePoints; else, exitPrice=marketClose+profile.entrySlippagePoints; end
    otherwise, error("QuantLab:UnknownExitReason","Salida desconocida: %s",exitReason);
end
end
