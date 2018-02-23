# A reproducible annual data-synopsis report for British Columbia groundfish species

[![Travis-CI Build Status](https://travis-ci.org/seananderson/pbs-synopsis.svg?branch=master)](https://travis-ci.org/seananderson/pbs-synopsis)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/github//seananderson/pbs-synopsis/?branch=master&svg=true)](https://ci.appveyor.com/project/seananderson/pbs-synopsis)

The combination of fishery dependent data, such as catch and effort, and fishery independent survey data, such as biomass indices and age compositions, forms the backbone of most fisheries stock assessments. For British Columbia groundfish fisheries, we collect vast quantities of such data with 100% at-sea observer coverage, 100% dockside monitoring of landings, and multiple trawl, trap, and hook-and-line surveys deployed annually. However, we lack the capacity to conduct formal stock assessments for most stocks annually, and therefore, much of this data is not regularly published or readily accessible. We are developing a reproducible report to give a snapshot of long-term and recent population and fishing trends and data availability for all British Columbia groundfish stocks of commercial and conservation interest. The report generation is fully automated --- pulling data from databases, generating visualizations, and stitching the document together to facilitate annual publication. Our goals are (1) to facilitate groundfish scientists and managers regularly reviewing trends in survey indices and stock composition to potentially flag stocks for prioritized assessment; (2) to generate standardized datasets and visualizations that will help assessment scientists develop operating models and select candidate management procedures as part of a planned management-procedure framework for data-limited groundfish stocks; and (3) to increase data transparency between Fisheries and Oceans Canada, the fishing industry, non-governmental organizations, and the public. We have developed an early version of the report and will be refining it based on consultation with other groundfish scientists, fisheries managers, industry representatives, and other interested parties.

# Installation

The gfsynopsis package is *not* ready for use yet. In particular, the documentation is far from complete. However, it can be installed with:

```r
# install.packages("devtools")
devtools::install_github("seananderson.ca/pbs-synopsis")
library("gfsynopsis")
```
