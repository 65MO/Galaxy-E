# RData reader for Galaxy
This tool first reads a RData binary file then extracts the chosen elements to single outputs.

## TODO
* The tool should indicates when the Rdata file doesn't match the attributes(s) selected.
Can happen when multiple files are avaibles and the user doesn't select the good one.
	* Done

* Add a test section in the xmls files.

* Adapt the files extensions.
	* Done ? Test with various Rdatas
	
## Known errors
* Execution fail when the variable to extract return a null value
	* Resolved
* The tool yet can't display list and language types ?
	* Resolved
