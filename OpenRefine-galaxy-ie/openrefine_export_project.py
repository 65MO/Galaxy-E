#!/usr/bin/python
import sys
import os
import pickle
#API to help interactive environnement get data from galaxy
from galaxy_ie_helpers import put

sys.path.append("refine.py")
import refine
r = refine.Refine()


if os.path.isfile("fichier_donnee.txt"):
	print "sortie erreur"
	os.remove("fichier_donnee.txt")
	sys.exit(1)

else:
	print ("Fichier_donne.txt n'existe pas :"+str(os.path.isfile('fichier_donnee.txt')))
	localefile= open('fichier_donnee.txt','w')	
	localefile.write('true')
	print(os.path.isfile('fichier_donnee.txt'))
	try:
		os.mkdir('/refine-python/temp_dossier')

	except OSError:
		pass

	finally:
		with open ('/refine-python/temp_dossier/project_openrefine','rb') as fichier :
			mon_depickler = pickle.Unpickler(fichier)
			score_recupere = mon_depickler.load()
			name_file = score_recupere.project_name.split(".")[0] 
			localefile= open('%s_refine' % name_file ,'w')
			localefile.write(score_recupere.export_rows())
			#Don't forget to close the flux, else the command put will not work
			localefile.close()	
			put('%s_refine' % name_file, file_type='tsv')


sys.exit(0)
