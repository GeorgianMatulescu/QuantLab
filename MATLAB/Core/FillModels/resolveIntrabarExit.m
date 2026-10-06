function result=resolveIntrabarExit(side,barHigh,barLow,stopPrice,targetPrice,profile)
if side==1, stopTouched=barLow<=stopPrice; targetTouched=barHigh>=targetPrice; else, stopTouched=barHigh>=stopPrice; targetTouched=barLow<=targetPrice; end
reason="";
if stopTouched && targetTouched
    if upper(profile.sameBarPolicy)=="TARGET_FIRST", reason="TARGET"; else, reason="STOP"; end
elseif stopTouched, reason="STOP"; elseif targetTouched, reason="TARGET"; end
result=struct("stopTouched",stopTouched,"targetTouched",targetTouched,"exitReason",reason);
end
