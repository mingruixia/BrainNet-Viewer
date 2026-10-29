function value = linuxHardwareProfile(cpuText, memoryText)
%LINUXHARDWAREPROFILE Physical host hardware, not MATLAB/Java heap limits.
if nargin < 1, cpuText=readProc('/proc/cpuinfo'); end
if nargin < 2, memoryText=readProc('/proc/meminfo'); end
blocks=regexp(char(cpuText),'\r?\n\s*\r?\n','split');
model=regexp(char(cpuText),'(?m)^model name\s*:\s*([^\r\n]+)','tokens','once');
if isempty(model),model=regexp(char(cpuText),'(?m)^Hardware\s*:\s*([^\r\n]+)','tokens','once');end
cpu='Unknown processor';if ~isempty(model),cpu=strtrim(model{1});end
logicalCount=0;pairs=strings(0,1);
for k=1:numel(blocks)
    if isempty(regexp(blocks{k},'(?m)^processor\s*:\s*\d+','once')),continue;end
    logicalCount=logicalCount+1;
    socket=regexp(blocks{k},'(?m)^physical id\s*:\s*(\d+)','tokens','once');
    core=regexp(blocks{k},'(?m)^core id\s*:\s*(\d+)','tokens','once');
    if ~isempty(socket)&&~isempty(core),pairs(end+1)=string(socket{1})+":"+string(core{1});end %#ok<AGROW>
end
if logicalCount>0
    if numel(pairs)==logicalCount
        cpu=sprintf('%s | %dC/%dT',cpu,numel(unique(pairs)),logicalCount);
    else
        cpu=sprintf('%s | %d logical processors',cpu,logicalCount);
    end
end
total=memoryBytes(memoryText,'MemTotal');available=memoryBytes(memoryText,'MemAvailable');
memory='Usage unavailable';
if isfinite(total)&&total>0
    memory=sprintf('%.1f GiB total',total/1024^3);
    if isfinite(available)&&available>=0&&available<=total
        memory=sprintf('%.1f / %.1f GiB available',available/1024^3,total/1024^3);
    end
end
value=struct('cpu',cpu,'memory',memory);
end

function text=readProc(path)
text='';try,text=fileread(path);catch,end
end

function value=memoryBytes(text,key)
token=regexp(char(text),['(?m)^' key ':\s+(\d+)\s+kB\s*$'],'tokens','once');
value=NaN;if ~isempty(token),value=str2double(token{1})*1024;end
end
