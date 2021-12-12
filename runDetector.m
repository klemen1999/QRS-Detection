function [] = runDetector(databaseName)

    if ~strcmp(databaseName,"mitbihDB") && ~strcmp(databaseName,"ltstDB")
        error("Set valid dabase")
    else
        dbDir = strcat("./",databaseName, "/*.mat");
    end

    examples = {dir(dbDir).name};
    n = length(examples);
    for i=1:n
        current = examples{i}(1:end-5);
        Detector(strcat("./",databaseName,"/",current));
        fprintf("Done %s (%d/%d)\n",current, i, n);
    end
end

