ECL bundles repository
======================

This repository serves as a central list of all known ECL bundles.

Bundles listed here fall into three categories:

Supported bundles
  are maintained by the HPCC platform team, and tested against each release.

Approved bundles
  are maintained by external contributors, but have passed initial review
  and testing by the HPCC platform team and thus should be considered stable and safe to
  use, and should remain compatible across platform versions

Other bundles
  are created and maintained by external contributors, and have not been
  approved by the platform team. Use at your own risk

If you have developed a bundle that you would like to add to any of these lists, create
a pull request against this file to add your bundle's repository to the appropriate list.

For more information about how to create an Ecl bundle, see the `Ecl Bundle Writer's Guide`_.

To install a bundle to your development machine, use the ecl command line tool:

ecl bundle install <bundle_url>.git

For complete details, see the Client Tools Manual, available in the download section of hpccsystems.com

.. _`Ecl Bundle Writer's Guide`: https://github.com/hpcc-systems/HPCC-Platform/blob/master/ecl/ecl-bundle/BUNDLES.rst

Supported bundles
=================

+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| ML_Core               | Machine Learning core bundle                      | https://github.com/hpcc-systems/ML_Core               |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| PBblas                | Parallel BLAS support for machine learning        | https://github.com/hpcc-systems/PBblas                |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| GLM                   | General Linear Model                              | https://github.com/hpcc-systems/GLM                   |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| LearningTrees         | Random forest classification and regression       | https://github.com/hpcc-systems/LearningTrees         |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| LinearRegression      | Ordinary Least Squares Linear Regression          | https://github.com/hpcc-systems/LinearRegression      |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| LogisticRegression    | Logistic Regression classification                | https://github.com/hpcc-systems/LogisticRegression    |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| SupportVectorMachines | Support Vector Machines                           | https://github.com/hpcc-systems/SupportVectorMachines |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| DataPatterns          | Data profiling tool                               | https://github.com/hpcc-systems/DataPatterns          |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| PerformanceTesting    | Performance test suite                            | https://github.com/hpcc-systems/PerformanceTesting    |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| Visualizer            | HPCC Visualizations support                       | https://github.com/hpcc-systems/Visualizer            |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+

Approved bundles
================

+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| Bloom                 | Bloom filter support                              | https://github.com/hpcc-systems/Bloom                 |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| CellFormatter         | Format ECL data for display                       | https://github.com/hpcc-systems/CellFormatter         |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| DataMgmt              | Generational data mgmt; live ROXIE query updates  | https://github.com/hpcc-systems/DataMgmt              |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| MySqlImport           | Import schemas from MySQL                         | https://github.com/hpcc-systems/MySqlImport           |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| StringMatch           | Various string matching algorithms                | https://github.com/hpcc-systems/StringMatch           |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| Trigram               | Trigram manipulation                              | https://github.com/hpcc-systems/Trigram               |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+

Other bundles
=============
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| Finance Library       | Commonly used financial operations                | https://github.com/JamesDeFabia/FinanceLibrary        |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| PrefixTree            | Improves Levenshtein edit distance performance    | https://github.com/Charles-Kaminski/PrefixTree        |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| File Management       | Manages the promotion of a set of files           | https://github.com/johnholt/File_Management           |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| Dapper                | Turns verbose ECL calls into simple verbs         | https://github.com/OdinProAgrica/dapper               |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| Sassy                 | ECL helper for SAS calls                          | https://github.com/lpezet/SASsy                       |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| DataPull              | Inter-cluster data replication                    | https://github.com/dcamper/DataPull                   |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
| GPU Deep Learning     | GPU Accelerated Deep Learning                     | https://github.com/hpcc-systems/GPU-Deep-Learning     |
+-----------------------+---------------------------------------------------+-------------------------------------------------------+
