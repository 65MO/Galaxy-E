#!/usr/bin/python
import sys
import os
import pickle
import refine
sys.path.append("refine.py")
r = refine.Refine()
p = r.new_project(sys.argv[1])
cwd = os.getcwd()

sys.stdout.write("Importing data from galaxy into openrefine")
try:
	os.mkdir(cwd+'/temp_dossier')
	with open(cwd+'/temp_dossier/project_openrefine','wb') as fichier :
		mon_pickler = pickle.Pickler(fichier)
		mon_pickler.dump(p)
except OSError:
	pass
	

