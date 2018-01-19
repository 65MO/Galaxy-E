IdCorrect_2nLayer.r script :
this script intend to correct ids from 1st layer of Tadarida software, and improve data output according to context (=the whole output of a sampling session)
It should be called with 3 consecutive arguments
1) a csv summary table of TadaridaC output from vigiechiro.herokuapp.com web portal (10 examples found in "input_examples" subdirectory)
2) the 2nd layer classifier built on validated id in Vigie-Chiro database ("ClassifEspC2b_171206.learner" in the "input_from_VigieChiro" subdirectory)
3) the directory where writing the output (set the working directory of the R session)
Output examples can be found in the "output_IdCorrect_2ndLayer" subdirectory

