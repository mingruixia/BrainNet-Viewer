classdef TestLinuxHardwareProfile < matlab.unittest.TestCase
    methods (Test)
        function readsSocketsAndAvailablePhysicalMemory(t)
            cpu=sprintf(['processor : 0\nmodel name : Test CPU\nphysical id : 0\ncore id : 0\n\n' ...
                'processor : 1\nphysical id : 0\ncore id : 0\n\nprocessor : 2\nphysical id : 1\ncore id : 0\n']);
            memory=sprintf('MemTotal: 16777216 kB\nMemFree: 100 kB\nMemAvailable: 6291456 kB\n');
            actual=brainnet.app.internal.linuxHardwareProfile(cpu,memory);
            t.verifyEqual(actual.cpu,'Test CPU | 2C/3T');
            t.verifyEqual(actual.memory,'6.0 / 16.0 GiB available');
        end
        function unavailableFieldsAreNotGuessed(t)
            actual=brainnet.app.internal.linuxHardwareProfile(sprintf('processor : 0\nHardware : ARM Test\n'),sprintf('MemTotal: 16777216 kB\nMemFree: 100 kB\n'));
            t.verifyEqual(actual.cpu,'ARM Test | 1 logical processors');
            t.verifyEqual(actual.memory,'16.0 GiB total');
            actual=brainnet.app.internal.linuxHardwareProfile('',sprintf('MemTotal: 1 kB\nMemAvailable: 2 kB\n'));
            t.verifyEqual(actual.memory,'0.0 GiB total');
            t.verifyEqual(actual.cpu,'Unknown processor');
        end
    end
end
