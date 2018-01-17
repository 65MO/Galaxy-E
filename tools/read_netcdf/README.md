# Netcdf reading and extraction
## Netcdf info
The first tool "netcdf info" use the C library netcdf (v4.5.0) to open and get general informations, variables names and attributes.
Variables that can be extracted and dimensions availables are printed in tabular files.

nc_info.xml use the C executable Nc_info.exe from the compilated NC_info.c. 
Tabular files are displayed by the bash code div_vartab.sh.
Stdout is the result of the "ncdump -h inputfile" command.

## Netcdf read
The second tool "netcdf read" use the Python module Netcdf4 (1.3.1) which is an interface to the C library.

The xml lecture_nc allows to choose a variable to extract and to add filter on dimensions.
The option "Search values for custom coordinates" use the scipy spatial function to get the closest coordinates with non-NA values.

The output is a tabular with the variable and its dimensions values (eg : latitude, longitude, time...).
Transpose.sh is some awk code to swap rows and columns.
