..  HPCC SYSTEMS software Copyright (C) 2013 HPCC Systems.
..
..  Licensed under the Apache License, Version 2.0 (the "License");
..  you may not use this file except in compliance with the License.
..  You may obtain a copy of the License at
..
..     http://www.apache.org/licenses/LICENSE-2.0
..
..  Unless required by applicable law or agreed to in writing, software
..  distributed under the License is distributed on an "AS IS" BASIS,
..  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
..  See the License for the specific language governing permissions and
..  limitations under the License.

PerformanceTesting
==================

This folder contains a set of ECL queries that are designed to test the performance of the HPCC system,
and allow changes in speed and memory usage to be tracked over time.

To run the regression suite, select the directory of the regression suite engine, and
enter the following command:

./ecl-test --timeout -1 --suiteDir <location-of-the-bundle-directory> run -t=<cluster>

Each of the tests in the regression suite is assigned to one or more classes.  This allows subsets of the
regression tests to be included or excluded for a particular run.  Full details of the different classes is included
in TestSummary.rst.

E.g.,

./ecl-test --timeout -1 --suiteDir <location-of-the-bundle-directory> run <cluster> --runclass=quick,memory

Currently the last query (summary01) generates a result that when viewed with the new eclwatch
produces a table of job v. date giving a summary of the time taken and memory consumed.

