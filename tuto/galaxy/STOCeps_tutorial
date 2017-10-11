---
layout: tutorial_hands_on
topic_name: STOC eps abondance occurrences
tutorial_name: STOCeps
---  
# Introduction

Le programme STOCeps (Suivi Temporel Oiseaux Communs_Echantillonnages Ponctuels Simples) est conçu pour évaluer les variations spatiales et temporelles de l’abondance des populations nicheuses d’oiseaux communs. Il est basé sur des points d’écoute.

> ![Logo STOCeps](/Users/trigodeteloise/Desktop/MNHN-sation/Méthode STOC/Logo-STOC-Vigie-Nature.png "STOCeps")
> ![STOCeps](https://www.google.fr/searchq=stoc+eps&source=lnms&tbm=isch&sa=X&ved=0ahUKEwiLw7rCms_VAhUBOxoKHXFHBCwQ_AUICigB#imgrc=p3wuwK7SetpctM)"STOCeps"

> ### Agenda
>
> Dans ce tutoriel, nous verrons:
>
> 1. Chargement des fichiers
> 2. Analyses
> 3. Création des graphiques 
> 4. Workflow
> {:toc}
>
{: .agenda}

# Chargement des fichiers
Pour importer les fichiers, il faut cliquer sur le bouton téléchargement en haut à gauche. Il est préférable de les importer au format tsv ou csv.
La fenêtre « **Téléverser depuis le web ou à partir de votre pc** » s'affiche. Il faut sélectionner « **choisir un fichier en local** » puis « **démarrer** » pour charger les données. Une fois que les données sont chargées, on peut fermer la fenêtre. Dans type, il est préférable de sélectionner tabular. Les données s'affichent à droite une fois chargées.

# Analyses
### :pencil2: Obtenir une base de données ALAARV
>
> 1. Outil "Filtrer des données sur une colonne en utilisant des expressions simples"

Il permet de créer une fichier tabulé avec les données pour une espèce (Exemple ici pour ALAARV).

> 2. Ce qui est fait 

Pour sélectionner que les lignes mentionnant l'espèce ALAARV dans la troisième colonne du jeu de données, il faut utiliser la condition suivante : c3=='ALAARV'.

### :pencil2: Obtenir le nombre de carrés STOC par année pour l'espèce ALAARV et pour toutes les espèces
>
> 1. Outil "Compter le nombre d'occurrences de chaque enregistrement"

Il compte les occurrences de valeurs uniques dans la(les) colonne(s) sélectionnée(s)".

> 2. Ce qui est fait 

Il permet d'obtenir le nombre de carrés STOC par année pour toutes les espèces ou pour une espèce (ex : ALAARV). Il suffit d'indiquer le champ dans lequel on veut compter les termes dans « Select/Unselect all ».

### :pencil2: Joindre le nombre de carrés STOC par année pour toutes les espèces et pour l'espèce ALAARV en une table

> 1. Outil "Joindre les lignes de deux jeux de données l'un à côté de l'autre par un champ spécifique"

Cet outil joint les lignes de deux jeux de données par un champ spécifique. 

> 2. Ce qui est fait 

Il joint le nombre de carrés STOC par année pour toutes les espèces avec le nombre de carrés STOC par année pour l'espèce ALAARV pour le champ année.

### :pencil2: Trier les colonnes

> 1. Outil "Couper des colonnes d'un jeu de données tabulé"

Cet outil joint les lignes de deux jeux de données par un champ spécifique. 

> 2. Ce qui est fait 

Il joint le nombre de carrés STOC par année pour toutes les espèces avec le nombre de carrés STOC par année pour l'espèce ALAARV pour le champ année.

### :pencil2: Convertir le champ année en commentaire

> 1. Outil "Trouver et Remplacer des patterns dans des colonnes en utilisant des expressions régulières (regex)"

Cet outil travaille ligne après ligne sur la donnée spécifiée en entrée et remplace le texte correspondant aux patterns d'expression régulière rentrés par la correspondance proposée. Cet outil utilise les expressions régulières du language de programmation python.

> 2. Ce qui est fait 

Il a permis de convertir le champ année en commentaire pour que la somme (présenté partie 7) soit effectuée uniquement sur le nombre d'individus.

### :pencil2: Additionner les abondances pour une année

> 1. Outil "Trouver et Remplacer des patterns dans des colonnes en utilisant des expressions régulières (regex)"

Cet outil travaille ligne après ligne sur la donnée spécifiée en entrée et remplace le texte correspondant aux patterns d'expression régulière rentrés par la correspondance proposée. Cet outil utilise les expressions régulières du language de programmation python.

> 2. Ce qui est fait 

Il a permis de convertir le champ année en commentaire pour que la somme soit effectuée uniquement sur le nombre d'individus.

### :pencil2: Additionner les abondances pour une année

> 1. Outil "Grouper des données par une colonne et pratiquer des opérations d'agrégation sur d'autres colonnes"

Il permet de grouper les jeux de données d'entrée par une colonne particulière et d'appliquer des fonctions d'agrégation. 

> 2. Ce qui est fait 

Il permet d'effectuer une somme entre les abondances pour une année. 

### :pencil2: Obtenir les fichiers des variations annuelles par espèce et de la tendance globale par espèce

 Avec l'outil "STOCeps Création des fichiers des variations annuelles par espèces et de la tendance globale par espèce".
 
 Il permet d'obtenir les fichiers :
 
> 1. variations annuelles par espèce

Ce fichier contient les sorties et les interprétations du modèle statistique qui permet de voir les variations inter-annuelles d'abondance des populations d'oiseaux pour chaque espèce. 
Avec ce jeux de données, l'outil "Filtrer des données sur une colonne en utilisant des expressions simples" permet de sélectionner les informations sur l'espèce voulu (ici l'espèce ALAARV) pour créer le graphique "Variation d'abondance pour l'espèce ALAARV". 
Il faut indiquer la condition : c2=='ALAARV'.

> 2. tendance globale par espèce

Ce fichier contient les sorties et ses interprétations du modèle statistique qui permet d'avoir la tendance globale de la variation d'abondance sur l'ensemble de la période de temps de l'espèce considérée.
L'outil doit être exécuté avec les deux jeux de données : « variations annuelles par espèce » et « tendance globale par espèce ».

### :pencil2: Obtenir les fichiers des variations annuelles par groupe de spécialistes, de la tendance globale par groupe de spécialistes et des informations relatives au calcul de l'indicateur par groupe de spécialistes

Avec l'outil "STOCeps2 Création des fichiers des variations annuelles par groupe de spécialiste et de la tendance globale par groupe de spécialiste"

Il permet d'obtenir les fichiers :
 
> 1. variations annuelles par groupe de spécialistes
Ce fichier contient les variations inter-annuelles d'abondance par groupe de spécialistes par habitats. Un indice annuel correspond à la moyenne géométrique des indices annuels des espèces spécialistes du groupe.
Avec ce jeu de données, l'outil "Filtrer des données sur une colonne en utilisant des expressions simples" permet de sélectionner les informations sur le groupe de spécialistes voulu (généralistes, milieux agricoles, milieux bâtis et milieux forestiers).
Après cela, il faut utiliser l'outil « Joindre les lignes de deux jeux de données l'un à côté de l'autre par un champ spécifique » pour joindre côte à côte les informations de variation d'abondance sur les groupes. Ce jeu de données permet de créer le graphique "Variation d'abondances au cours du temps par groupe de spécialistes".

> 2. tendance globale par groupe de spécialistes
Ce fichier contient les sorties du modèle statistique qui permet d'avoir la tendance globale de la variation d'abondance sur l'ensemble de la période de temps des groupes de spécialistes. 
Le modèle utilisé est une régression linéaire des abondances relatives en fonction du temps.

> 3. informations relatives au calcul de l'indicateur par groupe de spécialistes
Ce fichier contient le détail des poids attribués à chaque espèce et chaque année dans le calcul de l'indicateur par groupe de spécialistes. 
En effet, l'effectif de certaines espèces étant trop faible pour avoir une bonne estimation de leur abondance relative, un poids leur est attribué.

# Création des graphiques
Il faut cliquer sur "visualisation" et sur "chart".

# Workflow 
Sur Galaxy-E, il est possible de créer un workflow pour automatiser toutes les étapes de traitement des bases de données. 
Un workflow est la description d'une suite de tâches permettant un enchaînement automatisé de différentes opérations et étapes. 
Sur Galaxy-E, il est possible de créer un workflow pour automatiser toutes les étapes de traitement des jeux de données. 
Quand ce workflow est lancé avec un jeu de données STOCeps, il permet d'obtenir les jeux de données servants à la création des graphiques.

>    > ### :nut_and_bolt: Comments
>    > Pour extraire un workflow, il faut cliquer sur les « options de l'historique » puis « extraire un Workflow ».
>    > Dans « workflow », il est possible de modifier manuellement son workflow ou de l'exécuter sur un jeu de données/fichier audio en appuyant sur « run ».
>    {: .comment}
