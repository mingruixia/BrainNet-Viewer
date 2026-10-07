function value = accelerationCapabilities(options)
%ACCELERATIONCAPABILITIES Report optional CPU/GPU acceleration resources.

arguments
    options.Refresh (1, 1) logical = false
end

persistent cached
if isempty(cached) || options.Refresh
    parallelInstalled = ~isempty(ver('parallel'));
    parallelLicensed = false;
    gpuCount = 0;
    try
        parallelLicensed = license('test', 'Distrib_Computing_Toolbox');
    catch
    end
    if parallelInstalled && parallelLicensed
        try
            gpuCount = gpuDeviceCount('available');
        catch
        end
    end
    logicalProcessors = str2double(getenv('NUMBER_OF_PROCESSORS'));
    if ~isfinite(logicalProcessors) || logicalProcessors < 1
        logicalProcessors = 1;
    end
    cached = struct( ...
        'logical_processor_count', logicalProcessors, ...
        'parallel_toolbox_installed', parallelInstalled, ...
        'parallel_toolbox_licensed', parallelLicensed, ...
        'available_gpu_count', gpuCount, ...
        'cpu_vectorization_available', true, ...
        'explicit_parallel_pool_required', false, ...
        'mandatory_gpu_dependency', false);
end
value = cached;
end
