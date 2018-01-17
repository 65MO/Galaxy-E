from pylab import *
import netCDF4
from netCDF4 import Dataset
import numpy as np
import matplotlib.pyplot as plt
import sys
import os
from scipy import spatial
from math import radians, cos, sin, asin, sqrt
import itertools

#####################
#####################
 
def checklist(dim_list, dim_name, filtre, threshold):
    if not dim_list:
        error="Error "+str(dim_name)+" has no value "+str(filtre)+" "+str(threshold)
        sys.exit(error)


#Return dist in km between two coord
#Thx to : https://stackoverflow.com/questions/4913349/haversine-formula-in-python-bearing-and-distance-between-two-gps-points
def haversine(lon1, lat1, lon2, lat2):
    """
    Calculate the great circle distance between two points 
    on the earth (specified in decimal degrees)
    """
    # convert decimal degrees to radians 
    lon1, lat1, lon2, lat2 = map(radians, [lon1, lat1, lon2, lat2])

    # haversine formula 
    dlon = lon2 - lon1 
    dlat = lat2 - lat1 
    a = sin(dlat/2)**2 + cos(lat1) * cos(lat2) * sin(dlon/2)**2
    c = 2 * asin(sqrt(a)) 
    r = 6371 # Radius of earth in kilometers. Use 3956 for miles
    return c * r


#Comparison functions, return a list of indexes for the user conditions 
def is_strict_inf(filename, dim_name, threshold):
    list_dim=[]
    for i in range(0,filename.variables[dim_name].size):
        if filename.variables[dim_name][i] < threshold:
            list_dim.append(i)
    checklist(list_dim,dim_name,"<",threshold)
    return list_dim

def is_equal_inf(filename, dim_name, threshold):
    list_dim=[]
    for i in range(0,filename.variables[dim_name].size):
        if filename.variables[dim_name][i] <= threshold:
            list_dim.append(i)
    checklist(list_dim,dim_name,"<=",threshold)
    return list_dim

def is_equal_sup(filename, dim_name, threshold):
    list_dim=[]
    for i in range(0,filename.variables[dim_name].size):
        if filename.variables[dim_name][i] >= threshold:
            list_dim.append(i)
    checklist(list_dim,dim_name,">=",threshold)
    return list_dim

def is_strict_sup(filename, dim_name, threshold):
    list_dim=[]
    for i in range(0,filename.variables[dim_name].size):
        if filename.variables[dim_name][i] > threshold:
            list_dim.append(i)
    checklist(list_dim,dim_name,">",threshold)
    return list_dim

def find_nearest(array,value):
    index = (np.abs(array-value)).argmin()
    return index

def is_equal(filename, dim_name, value):
    try:
        index=filename.variables[dim_name][:].tolist().index(value)
    except:
        index=find_nearest(filename.variables[dim_name][:],value)
    return index

#######################
#######################

#Get args
#Get Input file
inputfile=Dataset(sys.argv[1])
var_file_tab=sys.argv[2]
var=sys.argv[3] #User chosen by user

Coord_bool=False


######################
######################


#Check if coord is passed as parameter
arg_n=len(sys.argv)-1
if(((arg_n-3)%3)!=0):
    Coord_bool=True #Useful to get closest coord
    arg_n=arg_n-4 #Number of arg minus lat & lon
    name_dim_lat=str(sys.argv[-4])
    name_dim_lon=str(sys.argv[-2])
    value_dim_lat=float(sys.argv[-3])
    value_dim_lon=float(sys.argv[-1])

    #Get all lat & lon
    try:
        lat=np.ma.MaskedArray(inputfile.variables[name_dim_lat])
        lon=np.ma.MaskedArray(inputfile.variables[name_dim_lon])
    except:
        sys.exit("Latitude & Longitude not found") 

    #Set all lat-lon pair avaible in list_coord
    list_coord_dispo=[]
    for i in lat:
        for j in lon:
            list_coord_dispo.append(i);list_coord_dispo.append(j)

    #Reshape
    all_coord=np.reshape(list_coord_dispo,(lat.size*lon.size,2))
    noval=True


#########################
#########################


#Get the file of variables and number of dims : var.tab
var_file=open(var_file_tab,"r") #read
lines=var_file.readlines() #line
dim_names=[]
for line in lines: #for every lines
    words=line.split()
    if (words[0]==var): #When line match user input var
        varndim=int(words[1])  #Get number of dim for the var
        for dim in range(2,varndim*2+2,2): #Get dim names
            dim_names.append(words[dim])
        #print ("Chosen var : "+sys.argv[3]+". Number of dimensions : "+str(varndim)+". Dimensions : "+str(dim_names)) #Standard msg
        

########################
########################


#Use a dictionary to save every lists of indexes
my_dic={} ##d["string{0}".format(x)]

for i in range(4,arg_n,3):
    #print("\nDimension name : "+sys.argv[i]+" action : "+sys.argv[i+1]+" .Value : "+sys.argv[i+2]+"\n") #Standard msg
    my_dic["string{0}".format(i)]="list_index_dim"
    my_dic_index="list_index_dim"+str(sys.argv[i])   #TODO Verif si il y a lon et lat

    #Apply every user filter. Call function and return list of index wich validate condition for every dim.
    if (sys.argv[i+1]=="l"): #<
        my_dic[my_dic_index]=is_strict_inf(inputfile, sys.argv[i], float(sys.argv[i+2]))
    if (sys.argv[i+1]=="le"): #<=
        my_dic[my_dic_index]=is_equal_inf(inputfile, sys.argv[i], float(sys.argv[i+2]))
    if (sys.argv[i+1]=="g"): #>
        my_dic[my_dic_index]=is_strict_sup(inputfile, sys.argv[i], float(sys.argv[i+2]))
    if (sys.argv[i+1]=="ge"): #>=
        my_dic[my_dic_index]=is_equal_sup(inputfile, sys.argv[i], float(sys.argv[i+2]))
    if (sys.argv[i+1]=="e"): #==
        my_dic[my_dic_index]=is_equal(inputfile, sys.argv[i], float(sys.argv[i+2]))
    if (sys.argv[i+1]==":"): #all
        my_dic[my_dic_index]=np.arange(inputfile.variables[sys.argv[i]].size)


#####################
#####################


#If precise coord given.
if Coord_bool: 
    while noval: #While no closest coord with valid values is found
        #Return closest coord avaible
        tree=spatial.KDTree(all_coord)
        closest_coord=(tree.query([(value_dim_lat,value_dim_lon)]))
        cc_index=closest_coord[1]

        closest_lat=float(all_coord[closest_coord[1]][0][0])
        closest_lon=float(all_coord[closest_coord[1]][0][1])

        #Get coord index into dictionary
        my_dic_index="list_index_dim"+str(name_dim_lat)
        my_dic[my_dic_index]=lat.tolist().index(closest_lat)

        my_dic_index="list_index_dim"+str(name_dim_lon)
        my_dic[my_dic_index]=lon.tolist().index(closest_lon)


        #All dictionary are saved in the string exec2 which will be exec(). Value got are in vec2
        exec2="vec2=inputfile.variables['"+var+"']["
        first=True
        for i in dim_names: #Every dim are in the right order
            if not first:
                exec2=exec2+","
            dimension_indexes="my_dic[\"list_index_dim"+i+"\"]" #new dim, custom name dic
            try:  #If some error or no specific user choices; every indexes are used for the selected dim.
                exec(dimension_indexes)
            except:
                dimension_indexes=":"
            exec2=exec2+dimension_indexes #Concatenate dim
            first=False #Not the first element now
        exec2=exec2+"]"
        #print exec2 #To check integrity of the string
        exec(exec2) #Execution, value are in vec2.
        #print vec2 #Get the value, standard output

        #Check integrity of vec2. We don't want  NA values
        i=0 
        #Check every value, if at least one non NA is found vec2 and the current closest coords are validated
        while i<len(vec2): 
            if vec2[i]!="nan": 
                break
            else: 
                i=i+1
        if i<vec2.size: #There is at least 1 nonNA value
            noval=False
        else: #If only NA, pop the closest coord and search in the second closest coord in the next loop.
            all_coord=np.delete(all_coord,cc_index,0)


#Same as before, dictionary use in exec2. exec(exec2) give vec2 and the values wanted.
else:
    exec2="vec2=inputfile.variables['"+str(sys.argv[3])+"']["
    first=True
    for i in dim_names: #Respect order
        if not first:
            exec2=exec2+","
        dimension_indexes="my_dic[\"list_index_dim"+i+"\"]"
        try:  #Avoid error and exit
            exec(dimension_indexes)
        except:
            dimension_indexes=":"
        exec2=exec2+dimension_indexes
        first=False
    exec2=exec2+"]"
    exec(exec2)
   

########################
########################


#This part create the header of every value. 
#Values of every dim from the var is saved in a list : b[].
#All the lists b are saved in the unique list a[]
#All the combinations of the dim values inside a[] are the headers of the vec2 values 

#Also write dim_name into a file to make clear header.
fo=open("header_names",'w')

a=[]
for i in dim_names:
    try: #If it doesn't work here its because my_dic= : so there is no size. Except will direcly take size of the dim.
        size_dim=inputfile[i][my_dic['list_index_dim'+i]].size
    except:
        size_dim=inputfile[i].size 
        my_dic['list_index_dim'+i]=range(size_dim)

    #print (i,size_dim) #Standard msg
    b=[]
    #Check size is useful since b.append(inputfile[i][my_dic['list_index_dim'+i][0]])  won't work
    if size_dim>1:
        for s in range(0,size_dim):
            b.append(inputfile[i][my_dic['list_index_dim'+i][s]])
            #print (i,inputfile[i][my_dic['list_index_dim'+i][s]])
    else:
        b.append(inputfile[i][my_dic['list_index_dim'+i]])
        #print (i,inputfile[i][my_dic['list_index_dim'+i]])
    a.append(b) 
    fo.write(i+"\t")
fo.write(var+"\n")
fo.close()


######################
######################


#Write header in file
fo=open("header",'w')
for combination in itertools.product(*a):
    fo.write(str(combination)+"\t")
fo.write("\n")
fo.close()


#Write vec2 in a tabular formated file
fo=open("sortie.tabular",'w')
try:
    vec2.tofile(fo,sep="\t",format="%s")
except:
    vec3=np.ma.filled(vec2,np.nan)
    vec3.tofile(fo,sep="\t",format="%s")
fo.close()


######################
######################


#Final sweet msg
print (var+" values successffuly extracted from "+sys.argv[1]+" !")
