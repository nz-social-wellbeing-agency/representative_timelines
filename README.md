# representative_timelines
Data assembly methodology for producing representative timelines

# timeline_visualisation

An interactive visualisation tool for exploring journey timelines.

## Overview

This repsoitory contains the code necessary to run SIA's interactive timeline visualisation tool. Developed as part of SIA's cross-sector representative timeline modeling, however it can be used independently of our timeline construction methodology (https://github.com/nz-social-investment-agency/representative_timelines).

## Features

TO DO

## Installation and dependencies



It is necessary to have an IDI project if you wish to run the code. Visit the Stats NZ website for more information.

Depending on your existing environment, expertise, and intended use of the visualisation app the steps you need to install the app may vary. Consider each of the following sections in turn.

### Packages

The visualsiation tool requires several R packages in order to run. These are not programs, but public code of a similar nature to the code files included in this repositry (but developed and reviewed by much larger teams of professional developers).

The four code packages are shiny, shinywidgets, tidyverse and readxl. All four of these packages are well established and reviewed. As the packages can be updated from time to time users experiencing difficulties may wish to download the exact same version of these packages as were used in the development of the interactive visualisation. The versions of each packages are as follows:

 - shiny, version 1.3.2
 - shinywidgets, version 0.4.8
 - tidyverse, version 1.2.1
 - readxl, version 1.3.1

The code for installing these specific versions of the packages is:
```
install.packages(devtools)
install_version("shiny", version = "1.3.2", repos = "http://cran.us.r-project.org")
install_version("shinywidgets", version = "0.4.8" repos = "http://cran.us.r-project.org")
install_version("tidyverse", version = "1.2.1", repos = "http://cran.us.r-project.org")
install_version("readxl", version = "1.3.1", repos = "http://cran.us.r-project.org")
```

### Visualisation

This repositry does not include specific tools for visualising the resulting output. A visualisation tool for the results can be found in its own repository: [timeline_visualisation](https://github.com/nz-social-investment-agency/timeline_visualisation). In general, our approach has been to use the code in this repository to prepare the data that describes the representative timelines, submit this data for review and checking by Stats NZ, and load the data into the visualisation tool once it has been released from the lab. Instructions for the timeline visualisation can be found in its repository.

## Folder and file descriptions
The folder contains the code to first prepare individual resolution timelines, and then to group and summarise these timelines to produce representative timelines.

The key files and folders are:

 - **global.R** is one of the core files for the base version of the visualsation app, it is responsible for the initial setup and preparation.
- **server.R** is one of the core files for the base version of the visualsation app, it is responsible for the background calculations and data management.
- **ui.R** is one of the core files for the base version of the visualsation app, it is responsible for the display and responsiveness of the user interface.
- **reference_app.R** is a docmentation file, providing a demonstration of a less common coding technique used in the app. Developers seeking to modify the code are advised to first familiarse themselves with the contents of this demo.
- **comparison_variant** contains all the equivalent core files (global, server and ui) for the comparison variant of the visualisation app.
- **www** contains the data files loaded by the app when it is run. Users seeking to investigate different data files should place them here.

## Getting Help
If you have any questions email info@sia.govt.nz

