import Std;

EXPORT Bundle := MODULE(Std.BundleBase)
    EXPORT Name := 'PerformanceTesting';
    EXPORT Description := 'Performance testing suite for the HPCC system';
    EXPORT Authors := ['Gavin Halliday'];
    EXPORT License := 'http://www.apache.org/licenses/LICENSE-2.0';
    EXPORT Copyright := 'Copyright (C) 2013 HPCC Systems';
    EXPORT DependsOn := [];
    EXPORT Version := '1.0.2';
END;
