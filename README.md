# representative_timelines
Data assembly methodology for producing representative timelines

## Overview

This repository provides the code for constructing cross-sector representative timelines of people's experiences. It should be used alongside the technical guidance **Representative timeline modelling of people's experiences: Analytic methodology** and the factsheet **Modelling Insights – timelines of people’s lived experience** released by the Social Wellbeing Agency.

This analysis was first developed to understand the experience of families in South Auckland around the birth of a child. This research was conducted in partnership between the Social Wellbeing Agency and The Southern Initiative (TSI). While parts of the code are written in the context of families and the birth of a child, the methodology is general and can be applied to a variety of journeys.

## Dependencies

In order to repeat this analysis, or adapt this project in the IDI, it is necessary to have an approved IDI project. Visit the Stats NZ website for more information. To repeat this analysis in a different environment you will need R, RStudio and SQL installed. Your environment will also have to be configured to allow R to connect with, and fetch data from, SQL.

The analysis requires several R packages in order to run. These are not programs, but public code of a similar nature to the code files included in this repository (but developed and reviewed by much larger teams of professional developers). You will need these packages installed in your environment in order to run the analysis.

As R packages can be updated from time to time users experiencing difficulties may wish to download the exact same version of these packages as were used in development. The packages and their versions are as follows: `TraMinR` version 2.0.10, `cluster` version 2.0.6, `Matrix` version 1.2.10, `tidyverse` version 1.2.1, `odbc` version 1.1.5, `DBI` version 0.8.0, `dplyr` version 0.7.6, `dbplyr` version 1.2.2.

The code for installing a specific version of the packages is:
```
install.packages(devtools)
library(devtools)
install_version("package_name", version = "x.x.x", repos = "http://cran.us.r-project.org")
```

## Visualisation

This repository does not include specific tools for visualising the resulting output. A visualisation tool for the results can be found in its own repository: [timeline_visualisation](https://github.com/nz-social-wellbeing-agency/timeline_visualisation). In general, our approach has been to use the code in this repository to prepare the data that describes the representative timelines, submit this data for review and checking by Stats NZ, and load the data into the visualisation tool once it has been released from the IDI. Instructions for the timeline visualisation can be found in its own repository.

## Folder and file descriptions
The folder contains the code to first prepare individual resolution timelines, and then to group and summarise these timelines to produce representative timelines.

The key files are:

 - **sql/setup_views_of_Events.sql** this creates SQL views of the birth events and the roles associated with each event.
- **sql/setup_views_of_indicators.sql** this creates SQL views of all of the measures that will be included in the timeline, and summarised alongside the timeline.
- **rprogs/stage_details.csv** is one of the three control files. This file governs the definition of which time periods are of interest, including the time periods that make up the timeline. All time periods are defined relative to the date of the reference event (the birth in our example).
- **rprogs/measures_process.csv** is one of the three control files. This file governs which measures are summarised for which periods and roles. E.g. we only calculate number of previous pregnancies for the mother.
- **rprogs/description_rename.csv** is one of the three control files. This file governs renaming of specific inputs during the data assembly.
- **rprogs/journey_timelines.R** runs the first stage of the data assembly and prepares the data into individual timelines according to the three control files.
- **rprogs/journey_output.R** takes the information prepared for individual timelines, groups and summarises it to produce representative timelines.

## Adaptation

Researchers should feel free to repurpose this methodology to construct cross-sector representative timelines of other journeys. In developing this analysis, we have sought to separate the population and measure definitions from the data processing. This means that when repeating the analysis, users should only need to change a limit collection of files and inputs.

Prior to adapting this methodology, we recommend researchers review the methodology diagrams found at the end of **Representative timeline modelling of people's experiences: Analytic methodology**. Adaptation is then recommended in the following order:

* Update the definition of the reference events and reference population in the appropriate SQL file. Following this, revise the control file that defines each time period.
* Update the definition of the measures to be analysed in the appropriate SQL file. Following this, revise the control file that defines how each measure is to be summarised.
* Revise the control file that renames variables if necessary.
* Run the R script to create individual level timelines, adapting as necessary.
* Run the R script to combine individual timelines into representative timelines, adapting as necessary.

To minimise the changes required in the R scripts, it is important to avoid changing the names of the columns in the SQL tables and views used by the R process. By extension, we also recommend including all the columns as named in our analysis even if some of these are redundant (for example, even if multiple roles in the same journey are not of interest in your adaptation you still need to include a column for role). Renaming input columns or removing columns will cause the analysis to break.

## Getting Help
If you have any questions email info@swa.govt.nz
