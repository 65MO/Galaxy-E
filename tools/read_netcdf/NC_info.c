//gcc lect_data1.c -lnetcdf

//traitement fichier a faire
//while read -r l; do a=$(echo $l | cut -d' ' -f1);echo $l>var/dimensions_$a; done < model_var.tab
//for f in *; do cat $f | sed 's/ /\t\n/g' | sed '$s/$/ /' >$f.tab; done
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <netcdf.h> 


#define CDI_MAX_NAME 300
typedef struct {
    int ncvarid;
    int dimtype;
    size_t len;
    char name[CDI_MAX_NAME];
}
ncdim_t;

typedef struct {
   int ncid;
   int dims[NC_MAX_VAR_DIMS];
   int xtype;
   int ndims;
   int gmapid;
   int positive;
   int dimids[8];
   int dimtype[8];
   int chunks[8];
   int chunked;
   int chunktype;
   int natts;
   int deflate;
   int lunsigned;
   int lvalidrange;
   int *atts;
   size_t vctsize;
   double *vct;
   double missval;
   double fillval;
   double addoffset;
   double scalefactor;
   double validrange[2];
   char name[CDI_MAX_NAME];
   char longname[CDI_MAX_NAME];
   char stdname[CDI_MAX_NAME];
   char units[CDI_MAX_NAME];
   char extra[CDI_MAX_NAME];
 }
 ncvar_t;




/* This is the name of the data file we will read. */
//#define FILE_NAME "dataset-ibi-reanalysis-bio-005-003-monthly-regulargrid_1510914389133.nc"

/* Handle errors by printing an error message and exiting with a non-zero status. */
#define ERR(e) {printf("Error: %s\n", nc_strerror(e)); return 2;}

/* Handle error */
void handle_error(int status){
if (status!=NC_NOERR){
    fprintf(stderr,"%s\n",nc_strerror(status));
    exit(-1);}}


int
main(int argc, char *argv[])
{
   #define FILE_NAME argv[1]
   int ncid;
   
   /* We will learn about the data file and store results in these
      program variables. Pour nc_inq. */
   int ndims_in, nvars_in, ngatts_in, unlimdimid_in;
   //ncdim_t dims;
   
   /* Error handling. */
   int retval;
   
   /* Var pour nv_inq_dim*/
   int varid;
   size_t recs,len;
   char recname[NC_MAX_NAME+1];
   nc_type xtypep;
   int ndimsp,nattsp;

   /* Open the file. */
   if ((retval = nc_open(FILE_NAME, NC_NOWRITE, &ncid))){ERR(retval);}
   
   /* Details sur fichier. */
   if (retval = nc_inq(ncid, &ndims_in, &nvars_in, &ngatts_in,&unlimdimid_in)){ERR(retval);}
   //printf("nombre de dimensions %d\nnombre de variables: %d \nnombre d'attribus globaux %d\ntruc zarb unlimited location : %d\n\n",ndims_in, nvars_in, ngatts_in, unlimdimid_in);
   //dims=(ncdim_t*)malloc((ndims_in+1)*sizeof(ncdim_t));

/*
   // Open file
   FILE * dim_file;
   dim_file=fopen("dim2.tabular","w");

   if(dim_file==NULL){printf("Error!");exit(1);}

   // Details sur les dimensions disponibles.
   for (int i=0;i<ndims_in;i++){
      if(retval=nc_inq_dim(ncid,i,recname,&recs)){ERR(retval);}
      fprintf(dim_file,"ndim:%d\t%s\n",i,recname);}

   fclose(dim_file);
*/
   
/*
   int time_id;
   retval=nc_inq_varid(ncid,"phy",&time_id);
   printf("\n%d\n",time_id);
*/

   //int dimids[NC_MAX_VAR_DIMS];
   char * name;//char * att_name;
   int attnum;    
   ncvar_t var;
   char dim_name[NC_MAX_NAME+1];

   /*for(varid=0;varid<nvars_in;varid++){
      if(retval=nc_inq_varname (ncid,varid,name)){ERR(retval);}
      if(retval=nc_inq_varndims(ncid,varid,&ndimsp)){ERR(retval);}
      printf("\nid:%d name:%s ndim:%d ",varid,name,ndimsp);
      }*/


   /* Open file */
   FILE * var_file;
   var_file=fopen("variables.tabular","w");

   if(var_file==NULL){printf("Error!");exit(1);}

   /* Print var informations */
   for(varid=0;varid<nvars_in;varid++){
       if(retval=(nc_inq_varndims(ncid,varid,&var.ndims))){ERR(retval);}
       //if(dims!=NULL){free(dims);}
       //int *dims = (int *) malloc((var.ndims + 1) * sizeof(int));
       if(retval=(nc_inq_var(ncid, varid, var.name, &xtypep, 0,var.dims, &var.natts))){ERR(retval);}
       fprintf(var_file,"%s\t%d",var.name,var.ndims);       
//       if(var.ndims>0){printf("\t");} //KESAKWA ?
       for(int id=0;id<ndims_in;id++){
           if(retval=(nc_inq_dim(ncid,var.dims[id],dim_name,&recs))){ERR(retval);}
           if(id<var.ndims){fprintf(var_file,"\t%s\t%lu",dim_name,recs);}
           else{fprintf(var_file,"\t \t ");}
       }
       fprintf(var_file,"\n");
   }


   /*for(int j=0;j<ndimsp;j++){
         if(retval=nc_inq_attname(ncid,i,j,att_name)){ERR(retval);}
         printf("att_num:%d att_name:%s  ",attnum,att_name);}*/ 


   /*for(i=0;i<3;i++){
      if(retval=nc_inq_attname(ncid,0,0,name)){ERR(retval);}
      printf("\natt_num:%d att_name:%s",0,name);//}
      int val;
      if(retval=nc_get_att(ncid,0,"_CoordinateAxes",&val)){ERR(retval);}
      printf("\n%d",val);*/


   //printf("\n\n*** SUCCESS reading example file sfc_pres_temp.nc!\n");
   return 0;
}
