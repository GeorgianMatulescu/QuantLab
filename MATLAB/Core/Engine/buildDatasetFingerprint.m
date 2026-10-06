function fingerprint = buildDatasetFingerprint(data,cfg)
%BUILDDATASETFINGERPRINT Huella reproducible y ligera de BarData.

data = ensureCanonicalBarData(data,cfg);

if isempty(data)
    fingerprint = "BARDATA-V1-EMPTY";
    return;
end

weights = (1:height(data))';
priceChecksum = sum(weights.*data.close,"omitnan");
volumeChecksum = sum(weights.*data.volume,"omitnan");
firstDate = string(data.datetime_local(1),"yyyyMMddHHmmss");
lastDate = string(data.datetime_local(end),"yyyyMMddHHmmss");

fingerprint = "BARDATA-V1-N" + height(data) + ...
    "-" + firstDate + "-" + lastDate + ...
    "-P" + string(sprintf("%.6f",priceChecksum)) + ...
    "-V" + string(sprintf("%.2f",volumeChecksum));
end
