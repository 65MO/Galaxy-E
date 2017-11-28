import os 
import sys

paranoid = sys.argv[1]
escape_dates = sys.argv[2]
escape_scinot = sys.argv[3]
escape_leadzero = sys.argv[4]
input_file = sys.argv[5]
output_file = sys.argv[6]

cmd = 'perl /home/bornea/galaxy-apostl-docker/tools/escapeExcel/escape_excel.pl'
if paranoid == 'TRUE':
	cmd = cmd + ' --paranoid'
if escape_dates == 'TRUE':
	cmd = cmd + ' --no-dates'
if escape_scinot == 'TRUE':
	cmd = cmd + ' --no-sci'
if escape_leadzero== 'TRUE':
	cmd = cmd + ' --no-zeroes'

cmd = cmd + ' ' + input_file + ' ' + output_file

os.system(cmd)
