
vecPackage=c("RODBC","dplyr","reshape","data.table","rgdal","lubridate","RPostgreSQL","doBy","reshape2")
ip <- installed.packages()[,1]

for(p in vecPackage)
    if (!(p %in% ip))
        install.packages(pkgs=p,repos = "http://cran.univ-paris1.fr/",dependencies=TRUE)

library(RODBC)
library(reshape)
library(data.table)
library(rgdal)
library(lubridate)
library(RPostgreSQL)
library(doBy)
library(reshape2)

if("STOC_eps" %in% dir()) setwd("STOC_eps/")
if(!("export" %in% dir())) setwd("/GitHub/STOC_eps")

openDB.PSQL <- function(user="postgres",mp=NULL,nomDB=NULL){

    library(RPostgreSQL)
    drv <- dbDriver("PostgreSQL") #### CHARGE LES DRIVERS DE LA BASE DE DONNEE
    if(is.null(nomDB)) nomDB <- "stoc_eps"

    if(is.null(user)) {
        con <- dbConnect(drv, dbname=nomDB) #### CREER CONNECTION A LA BASE DE DONNEES
    } else {
        con <- dbConnect(drv, dbname=nomDB,user=user, password=mp)
    }

    return(con)
}



clean.PSQL <- function(nomDB=NULL) {
    if(is.null(nomDB)) nomDB <- "stoc_eps"
    drv <- dbDriver("PostgreSQL")
    veccon <- dbListConnections(drv)
    for(i in 1:length(veccon)) dbDisconnect(veccon[[i]])
}





getCode_sp <- function(con,champSp,sp) {
    if(is.null(con)) con <- openDB.PSQL()
    querySp <- paste(" select ",champSp,", pk_species as code_sp, french_name from species where ",champSp," in  ",paste("('",paste(sp,collapse="' , '"),"')",";",sep=""),sep="")
    cat("\nRequete recupÃ©ration des code_sp:\n\n",querySp,"\n\n")

    dsp <- dbGetQuery(con, querySp)

    return(dsp$code_sp)


}


trad_fr2eng <- function(d) {

    tabTrad <- read.csv("Librairie/traduc_fr2eng.csv",stringsAsFactor=FALSE)
    rownames(tabTrad) <- tabTrad$fr

    colnames(d) <- ifelse(colnames(d) %in% tabTrad$fr,tabTrad[colnames(d),"eng"],colnames(d))
    return(d)
}


makeTableCarre <- function(con=NULL,user="postgres",mp="postgre",nomDB=NULL,savePostgres=FALSE,output=TRUE,sp=NULL,
                           champSp = "code_sp",nomChampSp="espece",
                           spExcluPassage1=c("MOTFLA","SAXRUB","ANTPRA","OENOEN","PHYTRO"),# (Prince et al. 2013 Env. Sc. and Pol.) + "OENOEN","PHYTRO" avis d'expert F. Jiguet
                           seuilAbondance=.99,
                           champsHabitat=TRUE,selectTypeHabitat=NULL,
                           altitude_min=NULL,altitude_max=NULL,firstYear=NULL,lastYear=NULL,
                           departement=NULL,onf=TRUE,
                           id_carre=NULL,insee=NULL,
                           distance_contact="inf",formatTrend = FALSE,isEnglish=FALSE,addAbscence=FALSE,
                           id_output="France", #"NicolasM",
                           operateur=c("Lorrilliere Romain",
                                       "lorrilliere@mnhn.fr"),
                           encodingSave="utf-8") {#"ISO-8859-1") {

    ##   spExcluPassage1=c("MOTFLA","SAXRUB","ANTPRA") ;seuilAbondance=.99;distance_contact=100;champSp = "code_sp";nomChampSp="espece";onf=TRUE
    ##   sp=NULL;champsHabitat=TRUE;id_output="France";con=NULL;savePostgres=FALSE;output=FALSE;altitude=NULL;firstYear=2001;lastYear=2017;operateur=c("Lorrilliere Romain","lorrilliere@mnhn.fr"); encodingSave="ISO-8859-1";formatTrend = TRUE;anglais=FALSE;departement="44"

    start <- Sys.time()
    dateExport <- format(start,"%Y-%m-%d")

    if(is.null(con)) con <- openDB.PSQL(user,mp,nomDB)
    if(is.null(firstYear)) firstYear <- 2001
    if(is.null(lastYear)) lastYear <- as.numeric(format(start,"%Y"))
    if(is.null(altitude_max)) altitude_max <- 8000
    if(is.null(altitude_min)) altitude_min <- 0

    if(is.null(distance_contact)) {
        distance_contact_txt <- ""
    } else {
        if(distance_contact == "100") {
            distance_contact_txt <- " distance_contact in ('LESS25','LESS100') and "
        } else {
            if(distance_contact == "200") {
                distance_contact_txt <- " distance_contact in ('LESS25','LESS100','MORE100','LESS200') and "
            } else {
                if(distance_contact == "inf") {
                    distance_contact_txt <- " distance_contact in ('U','LESS25','LESS100','MORE100','LESS200','MORE200') and "
                } else {
                    stop("distance_contact non pris en charge")
                }}}}

    seuil_txt <- as.character(trunc(seuilAbondance*100))


    if(is.null(distance_contact)) {
        champ_seuil <- paste("abondAll_seuil",seuil_txt,sep="")
    } else {
        if(distance_contact == "100") {
            champ_seuil <- paste("abond100_seuil",seuil_txt,sep="")
        } else {
            if(distance_contact == "200") {
                champ_seuil <- paste("abond200_seuil",seuil_txt,sep="")
            } else {
                if(distance_contact == "inf") {
                    champ_seuil <- paste("abondAll_seuil",seuil_txt,sep="")
                } else {
                    stop("distance_contact non pris en charge")
                }}}}

    flag.query1 <- flag.query2 <- FALSE
    if(!is.null(sp)) {
        if(champSp != "code_sp") {

            sp <- getCode_sp(con,champSp,sp)

        }

        sp1 <- sp[!(sp %in% spExcluPassage1)]
        if(length(sp1) > 0){
            spList1 <- paste("('",paste(sp1,collapse="' , '"),"')",sep="")
            flag.query1 <- TRUE
        }

        sp2 <- sp[sp %in% spExcluPassage1]
        if(length(sp2) > 0){
            spList2 <- paste("('",paste(sp2,collapse="' , '"),"')",sep="")
            flag.query2 <- TRUE
        }

    } else {

        spListExclud <- paste("('",paste(spExcluPassage1,collapse="' , '"),"')",sep="")
        flag.query1 <- flag.query2 <- TRUE
    }


    selectQueryOp <- ""
    selectQueryOp1 <- "SELECT id_inventaire, code_sp, sum(abondance) as abond
				FROM
				observation as o, inventaire as i,carre_annee as ca, carre as c
				WHERE
				o.id_inventaire = i.pk_inventaire and
				o.id_carre = c.pk_carre and
				o.id_carre = ca.id_carre and o.annee=ca.annee and
				ca.qualite_inventaire_stoc > 0 and
                                "
    selectQueryOp2 <- "
			GROUP BY
			id_inventaire, code_sp"

    if(!is.null(departement)) depList <- paste("('",paste(departement,collapse="' , '"),"')",sep="")
    if(!is.null(id_carre)) carreList <- paste("('",paste(id_carre,collapse="' , '"),"')",sep="")
    if(!is.null(insee)) inseeList <- paste("('",paste(insee,collapse="' , '"),"')",sep="")
    if(!is.null(selectTypeHabitat)) queryTypeHab <- paste(" AND ( ",paste(selectTypeHabitat,collapse=" = TRUE OR ")," = TRUE) ",sep="") else queryTypeHab <- " "

    selectQuery <- paste(distance_contact_txt," i.annee >= ",firstYear,"
and i.annee <= ",lastYear," and c.etude in ('STOC_EPS'",ifelse(onf,", 'STOC_ONF'",""),")  and  c.altitude <= ",altitude_max," and  c.altitude >= ",altitude_min," ",ifelse(is.null(departement),"",paste(" and departement in ",depList," ")),"
",
ifelse(is.null(id_carre),"",paste(" and o.id_carre in ",carreList," ")),"
",
ifelse(is.null(insee),"",paste(" and p.insee in ",inseeList," ")),"
",
ifelse(!is.null(selectTypeHabitat),queryTypeHab," ")," ", sep="")


    if(flag.query1) {   ##### DEMARRE SI flag.query1=TRUE
        selectQueryOp <- paste(selectQueryOp,selectQueryOp1,
                               ifelse(is.null(sp),paste("code_sp not  in ",spListExclud," and "),paste(" code_sp in ",spList1," and ")),"  passage_stoc in (1,2) and",
                               selectQuery,selectQueryOp2)
        if(flag.query2) {
            selectQueryOp <- paste(selectQueryOp,"
                                union
                                ")
        }
    }

    if(flag.query2) {
        selectQueryOp <- paste(selectQueryOp," --  ## begin ## ajout des especes tardives dont on ne garde que le second passage
            ",
            selectQueryOp1,
            ifelse(is.null(sp),paste("code_sp in ",spListExclud," and "),paste(" code_sp in ",spList2," and ")),"  passage_stoc = 2 and",
            selectQuery,selectQueryOp2)
    }










    queryObs <- paste("
select oc.id_carre as carre, oc.annee, (oc.annee::varchar(4)||oc.id_carre::varchar(100))::varchar(100) as id_carre_annee, c.etude,
qualite_inventaire_stoc, commune,insee,departement,
code_sp, e.scientific_name as nom_scientifique, e.french_name as nom_francais, e.english_name as nom_anglais, e.euring,e.taxref,
abond_brut as abondance_brut, abond  as abondance,
altitude, longitude_grid_wgs84,latitude_grid_wgs84, ",
ifelse(champsHabitat," foret_p, ouvert_p, agri_p, urbain_p,
foret_ps, ouvert_ps, agri_ps, urbain_ps,
nbp_foret_p, nbp_ouvert_p, nbp_agri_p, nbp_urbain_p,
nbp_foret_ps, nbp_ouvert_ps, nbp_agri_ps, nbp_urbain_ps, ",""),
" c.db as data_base_name, ",
"'",dateExport,"'::varchar(10) as date_export,
'",operateur[1],"'::varchar(50) as operateur,
'",operateur[2],"'::varchar(50) as email_operateur

from( -- ## begin ## somme sur carre des max par points sur 2 passages  
	select id_carre, annee,code_sp,sum(abond_brut) as abond_brut,sum(abond) as abond
	from -- ## begin ## obs max par point sur 2 passages
		(select id_point, annee,code_sp,max(abond_brut) as abond_brut,max(abond) as abond
		from -- ## begin ## correction abondance obs par seuil
			(select id_inventaire,id_point, passage_stoc, annee, code_sp,abond as abond_brut, ",champ_seuil," as seuil_abondance_sp,LEAST(abond, ",champ_seuil,") as abond
			from -- ## begin ## selection classe de distance et different filtre
				(",selectQueryOp,"
				) -- ## end ## selection classe de distance et different filtre
			as opb, espece_abondance_point_seuil as s, inventaire as i
			WHERE
			opb.code_sp = s.pk_species and opb.id_inventaire = i.pk_inventaire

			) -- ## end ## correction abondance obs par seuil
		as op
		group by id_point,annee,code_sp
		) -- ## end ## obs max par point sur 2 passages
	as omp, point as p
	where omp.id_point = p.pk_point
	group by id_carre, annee,code_sp) -- ## end ## somme sur carre des max par points sur 2 passages
as oc, carre as c, species as e, carre_annee as ca
where
oc.id_carre = c.pk_carre and oc.code_sp = e.pk_species and oc.id_carre = ca.id_carre and oc.annee = ca.annee
order by
oc.id_carre, annee,code_sp;",sep="")



                                        # browser()
    cat("\nRequete principale:\n\n",queryObs,"\n\n")

    d <- dbGetQuery(con, queryObs)




    if(addAbscence) {
        cat("\n Ajout des absences: \n")
        ##browser()
        colSp <- c("code_sp","euring","taxref",colnames(d)[grep("nom",colnames(d))])
        colCarreAn<- setdiff(colnames(d),c(colSp,"abondance_brut","abondance","qualite_inventaire_stoc"))
        colAbond <- c("code_sp","id_carre_annee","abondance_brut","abondance","qualite_inventaire_stoc")

        dsp <- unique(subset(d,select=colSp))
        dCarreAn <- unique(subset(d,select=colCarreAn))
        dAbund <- subset(d,select=colAbond)

        tabInv <- unique(d$id_carre_annee)

        tabInv <- expand.grid(dCarreAn$id_carre_annee,dsp$code_sp)
        colnames(tabInv) <- c("id_carre_annee","code_sp")

        dAbund <- merge(dAbund,tabInv,by=c("code_sp","id_carre_annee"),all=TRUE)

        dAbund$abondance_brut[is.na(dAbund$abondance_brut)] <- 0
        dAbund$abondance[is.na(dAbund$abondance)] <- 0

        dd <- merge(dAbund,dsp, by = "code_sp")
        dd <- merge(dd,dCarreAn,by="id_carre_annee")

      
        dd <- dd[,colnames(d)]

#c.code_sp,c.scientific_name,c.french_name,c.nom_anglais,c.euring,c.taxref,c.abondance_brut,c.abondance,
        
        queryCarreAn <- paste("select ca.id_carre as carre, ca.annee, pk_carre_annee as id_carre_annee, c.etude,ca.qualite_inventaire_stoc,
 c.commune,c.insee,c.departement ,
c.altitude, c.longitude_grid_wgs84 ,c.latitude_grid_wgs84,",
ifelse(champsHabitat," ca.foret_p,ca.ouvert_p,ca.agri_p,ca.urbain_p,ca.foret_ps,ca.ouvert_ps,ca.agri_ps,ca.urbain_ps,
ca.nbp_foret_p,ca.nbp_ouvert_p,ca.nbp_agri_p,ca.nbp_urbain_p,ca.nbp_foret_ps,ca.nbp_ouvert_ps,ca.nbp_agri_ps,ca.nbp_urbain_ps, ",""),
" c.db as data_base_name, ",
"'",dateExport,"'::varchar(10) as date_export,
'",operateur[1],"'::varchar(50) as operateur,
'",operateur[2],"'::varchar(50) as email_operateur
from
carre as c , carre_annee as ca
where
ca.id_carre = c.pk_carre and  c.altitude <= ",altitude_max," and  c.altitude >= ",altitude_min,ifelse(is.null(departement),"",paste(" and departement in ",depList," "))," and
 ca.qualite_inventaire_stoc > 0 and ca.annee >= ",firstYear,"  and ca.annee <= ",lastYear," and c.etude in ('STOC_EPS'",ifelse(onf,", 'STOC_ONF'",""),")
order by
ca.id_carre, annee;",sep="")


                                      
        cat("\nRequete inventaire: Recherche de tous les inventaires\n\n",queryCarreAn,"\n\n")

        dToutCarreAn <- dbGetQuery(con, queryCarreAn)### recup tous les pairs carres/annee ou une sps a été observé (donc si aucune obs, le carre normalement saute sauf si selection de plusieurs esp avec une sur ces carres)

    
         
        
        dCarreAbs <- subset(dToutCarreAn,!(id_carre_annee %in% dd$id_carre_annee))

        if(nrow(dCarreAbs)>0) {
            nbSp <- nrow(dsp)
            nbCarreAbs <- nrow(dCarreAbs)

            dCarreAbs2 <- as.data.frame(lapply(dCarreAbs, rep,nbSp))
            dspAbs <- as.data.frame(lapply(dsp, rep,each= nbCarreAbs))#### chaque element de nbCarreAbs est répété x fois
            dCarreAbs <- cbind(dCarreAbs2,dspAbs)#### tu réécris sur dCarreAbs ?
            dCarreAbs$abondance <- 0
            dCarreAbs$abondance_brut <- 0
           
           # setdiff(colnames(d),colnames(dCarreAbs))
            
            dCarreAbs <- dCarreAbs[,colnames(d)]

            d <- rbind(dd,dCarreAbs)
        } else {
            d <- dd
        }

                                        #  browser()
        d <- d[order(d$carre,d$annee,d$code_sp),]

    }

    if (formatTrend){
                                        #  browser()
        d <- subset(d,select=c("carre","annee","code_sp","abondance"))
        colnames(d)[3:4] <- c(nomChampSp,"abond")
    }

    if(isEnglish) {
        cat(" - Traduction des noms de colonnes\n\n")
        d <- trad_fr2eng(d)

    }


################### as ",ifelse(formatTrend,"abond","abondance"),"
############# ",ifelse(!(is.null(nomChampSp)),paste(" as ",nomChampSp,sep="")),"
                                        #if(savePostgres) sqlCreateTable(con,"outcome.FrenchBBS_montaneOpen",d)
    ##  as longitude_square_grid_wgs84   as latitude_squarre_grid_wgs84


    if(is.null(sp)) suffSp <- "allSp" else if(length(sp)<4) suffSp <- paste(sp,collapse="-") else suffSp <- paste(length(sp),"sp",sep="")
    fileOut <- paste("export/data_FrenchBBS_squarre_",id_output,"_",suffSp,"_",firstYear,"_",lastYear,".csv",sep="")
    write.csv2(d,fileOut,row.names=FALSE)
    cat(" --> ",fileOut,"\n")
    end <- Sys.time() ## heure de fin

    dbDisconnect(con)

    cat("     #      ==> Duree:",round(as.difftime(end - start,units="mins")),"minutes\n")
    if(output) return(d)
}
















makeTablePoint <- function(con=NULL,user=NULL,mp=NULL,nomDB=NULL,savePostgres=FALSE,output=TRUE,sp=NULL,champSp = "code_sp",nomChampSp="espece",
                           spExcluPassage1=c("MOTFLA","SAXRUB","ANTPRA","OENOEN","PHYTRO"),# (Prince et al. 2013 Env. Sc. and Pol.) + "OENOEN","PHYTRO" avis d'expert F. Jiguet
                           seuilAbondance=.99,
                           champsHabitat=TRUE,champsCoordGrid=TRUE,altitude_min=NULL,altitude_max=NULL,
                           firstYear=NULL,lastYear=NULL,
                           departement=NULL,insee=NULL,onf=TRUE,
                           id_carre=NULL,
                           selectHabitat = NULL, selectTypeHabitat= NULL,
                           distance_contact="inf",formatTrend = FALSE,isEnglish=FALSE,addAbscence=FALSE,
                           id_output="AlexR_2017-11-23", #"NicolasM",
                           operateur=c("Lorrilliere Romain",
                                       "lorrilliere@mnhn.fr"),
                           encodingSave="utf-8") {#"ISO-8859-1") {

    ## con=NULL;savePostgres=FALSE;output=TRUE;sp=NULL;champSp = "code_sp";
    ## spExcluPassage1=c("MOTFLA","SAXRUB","ANTPRA")  ;seuilAbondance=.99;
    ## champsHabitat=TRUE;champsCoordGrid=TRUE;altitude=NULL;firstYear=NULL;lastYear=NULL;
    ## departement="44";onf=TRUE;distance_contact="100";
    ## selectHabitat = NULL; selectTypeHabitat= NULL#c("urbain_ps","agri_ps");
    ## formatTrend = FALSE;anglais=FALSE;addAbscence=FALSE;
    ## id_output="VincentP_2017-10-16"; #"NicolasM";
    ## operateur=c("Lorrilliere Romain",
    ##             "lorrilliere@mnhn.fr");
    ## encodingSave="utf-8"



    start <- Sys.time()
    dateExport <- format(start,"%Y-%m-%d")

    flag.query1 <- FALSE
    flag.query2 <- FALSE



    if(is.null(con)) con <- openDB.PSQL(user,mp,nomDB)
    if(is.null(firstYear)) firstYear <- 2001
    if(is.null(lastYear)) lastYear <- as.numeric(format(start,"%Y"))
    if(is.null(altitude_max)) altitude_max <- 8000
    if(is.null(altitude_min)) altitude_min <- 0

    if(is.null(distance_contact)) {
        distance_contact_txt <- ""
    } else {
        if(distance_contact == "100") {
            distance_contact_txt <- " distance_contact in ('LESS25','LESS100') and "
        } else {
            if(distance_contact == "200") {
                distance_contact_txt <- " distance_contact in ('LESS25','LESS100','MORE100','LESS200') and "
            } else {
                if(distance_contact == "inf") {
                    distance_contact_txt <- " distance_contact in ('U','LESS25','LESS100','MORE100','LESS200','MORE200') and "
                } else {
                    stop("distance_contact non pris en charge")
                }}}}

    seuil_txt <- as.character(trunc(seuilAbondance*100))


    if(is.null(distance_contact)) {
        champ_seuil <- paste("abondAll_seuil",seuil_txt,sep="")
    } else {
        if(distance_contact == "100") {
            champ_seuil <- paste("abond100_seuil",seuil_txt,sep="")
        } else {
            if(distance_contact == "200") {
                champ_seuil <- paste("abond200_seuil",seuil_txt,sep="")
            } else {
                if(distance_contact == "inf") {
                    champ_seuil <- paste("abondAll_seuil",seuil_txt,sep="")
                } else {
                    stop("distance_contact non pris en charge")
                }}}}


    if(!is.null(sp)) {
        if(champSp != "code_sp") {

            sp <- getCode_sp(con,champSp,sp)

        }

        sp1 <- sp[!(sp %in% spExcluPassage1)]
        if(length(sp1) > 0){
            spList1 <- paste("('",paste(sp1,collapse="' , '"),"')",sep="")
            flag.query1 <- TRUE
        }

        sp2 <- sp[sp %in% spExcluPassage1]
        if(length(sp2) > 0){
            spList2 <- paste("('",paste(sp2,collapse="' , '"),"')",sep="")
            flag.query2 <- TRUE
        }

    } else {

        spListExclud <- paste("('",paste(spExcluPassage1,collapse="' , '"),"')",sep="")
        flag.query1 <- flag.query2 <- TRUE
    }

    if(!is.null(selectHabitat)) habList <- paste("('",paste(selectHabitat,collapse="' , '"),"')",sep="")
    if(!is.null(selectTypeHabitat)) queryTypeHab <- paste(" AND ( pa.",paste(selectTypeHabitat,collapse=" = TRUE OR pa.")," = TRUE) ",sep="") else queryTypeHab <- " "
    if(!is.null(departement)) depList <- paste("('",paste(departement,collapse="' , '"),"')",sep="")
    if(!is.null(insee)) inseeList <- paste("('",paste(insee,collapse="' , '"),"')",sep="")


    listChampsHabitat <- "pa.p_milieu as habitat_principal, pa.s_milieu as habitat_secondaire, pa.p_dernier_descri as temps_depuis_derniere_description_habitat ,
   pa.foret_p as foret_p, pa.agri_p as agricole_p, pa.urbain_p as urbain_p, pa.ouvert_p as ouvert_p, pa.foret_ps as foret_ps, pa.agri_ps as agricole_ps, pa.urbain_ps as urbain_ps, pa.ouvert_ps as ouvert_ps,
  nbp_foret_p  as carre_nb_pts_foret_p, nbp_ouvert_p as carre_nb_pts_ouvert_p, nbp_agri_p as carre_nb_pts_agricole_p, nbp_urbain_p as carre_nb_pts_urbain_p,
nbp_foret_ps as carre_nb_pts_foret_ps, nbp_ouvert_ps as carre_nb_pts_ouvert_ps, nbp_agri_ps as carre_nb_pts_agricole_ps, nbp_urbain_ps  as carre_nb_pts_urbain_ps, "

    selectQueryOp <- ""
    selectQueryOp1 <- "SELECT id_inventaire, code_sp, sum(abondance) as abond
				FROM
				observation as o, inventaire as i,point as p, point_annee as pa, carre as c
				WHERE
				o.id_inventaire = i.pk_inventaire and
				o.id_carre = c.pk_carre and
				o.id_point = p.pk_point and
				o.id_point = pa.id_point and o.annee=pa.annee and
				pa.qualite_inventaire_stoc > 0 and
                                "
    selectQueryOp2 <- "
			GROUP BY
			id_inventaire, code_sp"

    if(!is.null(departement)) depList <- paste("('",paste(departement,collapse="' , '"),"')",sep="")
    if(!is.null(id_carre)) carreList <- paste("('",paste(id_carre,collapse="' , '"),"')",sep="")

    selectQuery <- paste(distance_contact_txt," i.annee >= ",firstYear,"  and i.annee <= ",lastYear,
                         " and c.etude in ('STOC_EPS'",ifelse(onf,", 'STOC_ONF'",""),")  and  p.altitude <= ",altitude_max," and p.altitude >= ",altitude_min,"
",
ifelse(is.null(departement),"",paste(" and p.departement in ",depList," ")),"
",
ifelse(is.null(insee),"",paste(" and p.insee in ",inseeList," ")),"
",
ifelse(is.null(id_carre),"",paste(" and o.id_carre in ",carreList," ")),"
",
ifelse(!is.null(selectHabitat),paste(" and p_milieu in ",habList," ")," "),"
",
ifelse(!is.null(selectTypeHabitat),queryTypeHab," ")," ", sep="")



    if(flag.query1) {
        selectQueryOp <- paste(selectQueryOp,selectQueryOp1,
                               ifelse(is.null(sp),paste("code_sp not  in ",spListExclud," and
                                "),paste(" code_sp in ",spList1," and
                                ")),"
                                passage_stoc in (1,2) and",
                               selectQuery,selectQueryOp2)
        if(flag.query2) {
            selectQueryOp <- paste(selectQueryOp,"
                                union
                                ")
        }
    }

    if(flag.query2) {
        selectQueryOp <- paste(selectQueryOp," --  ajout des especes tardives dont on ne garde que le second passage
            ",
            selectQueryOp1,
            ifelse(is.null(sp),paste("code_sp in ",spListExclud," and "),paste(" code_sp in ",spList2," and ")),"  passage_stoc = 2 and",
            selectQuery,selectQueryOp2)
    }


    queryObs <- paste(
        "select om.id_point as point, p.id_carre as carre, om.annee as annee,
(om.annee::varchar(4)||om.id_point::varchar(100))::varchar(100) as id_point_annee,
c.etude as etude, p.commune,p.insee,p.departement as departement,
code_sp , e.scientific_name as nom_scientifique, e.french_name as nom_francais, e.english_name as nom_anglais, e.euring as code_espece_euring,e.taxref as code_espece_taxref,
abond_brut as abondance_brut, abond as abondance, pa.qualite_inventaire_stoc as qualite_inventaire_stoc,
p.altitude, longitude_wgs84,  latitude_wgs84, " , ifelse(champsCoordGrid," longitude_grid_wgs84,latitude_grid_wgs84, ",""),"
" , ifelse(champsHabitat,listChampsHabitat,""),
" p.db as data_base_name, ",
"'",dateExport,"'::varchar(10) as date_export,
'",operateur[1],"'::varchar(50) as operateur,
'",operateur[2],"'::varchar(50) as email_operateur

from(
	select id_point, annee,code_sp,max(abond_brut) as abond_brut,max(abond) as abond
		from -- ## begin ## correction abondance obs par seuil
			(select id_inventaire,id_point, passage_stoc, annee, code_sp,abond as abond_brut, ",champ_seuil," as seuil_abondance_sp,LEAST(abond,",champ_seuil,") as abond
			from -- ## begin ## selection classe de distance et different filtre
				( ",selectQueryOp,"
	                        ) --  ## end ## selection classe de distance et different filtre
			as opb, espece_abondance_point_seuil as s, inventaire as i
			WHERE
			opb.code_sp = s.pk_species and opb.id_inventaire = i.pk_inventaire

			) -- ## end ## correction abondance obs par seuil
		as op
		group by id_point,annee,code_sp
		 )-- ## end ## obs max par point sur 2 passages
		 as om , point as p, carre as c, species as e , point_annee as pa , carre_annee as ca
where
om.id_point = p.pk_point and p.id_carre = c.pk_carre and om.code_sp = e.pk_species and om.id_point = pa.id_point and om.annee = pa.annee and p.id_carre = ca.id_carre and om.annee = ca.annee
order by
om.id_point, annee,code_sp; ",sep="")



                                        # browser()
    cat("\nRequete principale:\n\n",queryObs,"\n\n")

                                        # browser()
    d <- dbGetQuery(con, queryObs)




    if(addAbscence) {
        cat("\n Ajout des absences: \n")
                                        #  browser()
        colSp <- c("code_sp","code_espece_euring","code_espece_taxref",colnames(d)[grep("nom",colnames(d))])
        colPointAn<- setdiff(colnames(d),c(colSp,"abondance_brut","abondance","qualite_inventaire_stoc"))
        colAbond <- c("code_sp","id_point_annee","abondance_brut","abondance","qualite_inventaire_stoc")

        dsp <- unique(subset(d,select=colSp))
        dPointAn <- unique(subset(d,select=colPointAn))
        dAbund <- subset(d,select=colAbond)

        tabInv <- unique(d$id_point_annee)

        tabInv <- expand.grid(dPointAn$id_point_annee,dsp$code_sp)
        colnames(tabInv) <- c("id_point_annee","code_sp")

        dAbund <- merge(dAbund,tabInv,by=c("code_sp","id_point_annee"),all=TRUE)

        dAbund$abondance_brut[is.na(dAbund$abondance_brut)] <- 0
        dAbund$abondance[is.na(dAbund$abondance)] <- 0

        dd <- merge(dAbund,dsp, by = "code_sp")
        dd <- merge(dd,dPointAn,by="id_point_annee")


        dd <- dd[,colnames(d)]

        if(!is.null(sp)) {
            queryPointAn <- paste("select pa.id_point as point, pa.id_carre as carre, pa.annee as annee, pk_point_annee as id_point_annee, ''::varchar(25) as etude,
 p.commune,p.insee,p.departement as departement,pa.qualite_inventaire_stoc as qualite_inventaire_stoc,p.altitude, longitude_wgs84,  latitude_wgs84,
 ",ifelse(champsCoordGrid," longitude_grid_wgs84,latitude_grid_wgs84, ",""),"
 ",ifelse(champsHabitat,listChampsHabitat,""),
 " p.db as data_base_name, ",
 "'",dateExport,"'::varchar(10) as date_export,
'",operateur[1],"'::varchar(50) as operateur,
'",operateur[2],"'::varchar(50) as email_operateur
from
point_annee as pa, point as p, carre as c ", ifelse(champsHabitat,", carre_annee as ca ",""), "
where
pa.id_point = p.pk_point and pa.id_carre = c.pk_carre and p.altitude <= ",altitude," and  pa.annee >= ",firstYear,"  and pa.annee <= ",lastYear,ifelse(champsHabitat," and pa.id_carre = ca.id_carre and pa.annee = ca.annee ",""),ifelse(is.null(departement),"",paste(" and p.departement in ",depList," ")),
ifelse(!is.null(selectHabitat),paste(" and p_milieu in ",habList," ")," "),ifelse(!is.null(selectTypeHabitat),queryTypeHab," "),"
order by
pa.id_point, annee;",sep="")



            cat("\nRequete inventaire: Recherche de tous les inventaires\n\n",queryPointAn,"\n\n")

            dToutPointAn <- dbGetQuery(con, queryPointAn)

            dPointAbs <- subset(dToutPointAn,!(id_point_annee %in% dd$id_point_annee))
            if(nrow(dPointAbs)>0) {
                nbSp <- nrow(dsp)
                nbPointAbs <- nrow(dPointAbs)

                dPointAbs2 <- as.data.frame(lapply(dPointAbs, rep,nbSp))
                dspAbs <- as.data.frame(lapply(dsp, rep,each= nbPointAbs))
                dPointAbs <- cbind(dPointAbs2,dspAbs)
                dPointAbs$abondance <- 0
                dPointAbs$abondance_brut <- 0
                                        #    browser()
                dPointAbs <- dPointAbs[,colnames(d)]

                d <- rbind(dd,dPointAbs)
            } else {
                d <- dd
            }
        }else {
            d <- dd

        }


        d <- d[order(d$point,d$annee,d$code_sp),]

    }


    if (formatTrend){
                                        #  browser()
        d <- subset(d,select=c("carre","annee","code_sp","abondance"))
        colnames(d)[3:4] <- c(nomChampSp,"abond")
    }

    if(isEnglish) {
        cat(" - Traduction des noms de colonnes\n")
        d <- trad_fr2eng(d)

    }



                                        #if(savePostgres) sqlCreateTable(con,"outcome.FrenchBBS_montaneOpen",d)
    if(is.null(sp)) suffSp <- "allSp" else if(length(sp)<4) suffSp <- paste(sp,collapse="-") else suffSp <- paste(length(sp),"sp",sep="")

    fileOut <- paste("export/data_FrenchBBS_point_",id_output,"_",suffSp,"_",firstYear,"_",lastYear,ifelse(isEnglish,"eng","fr"),".csv",sep="")
    write.csv2(d,fileOut,row.names=FALSE)
    cat(" --> ",fileOut,"\n")

    end <- Sys.time() ## heure de fin

    dbDisconnect(con)

    cat("\n     #      ==> Duree:",round(as.difftime(end - start,units="mins")),"minutes\n")
    if(output) return(d)
}












                                        # 2017-11-14 ajout champs nom sp en sortie nomChampSp= "espece"













makeTableTRIM <- function(con=NULL,user=NULL,mp=NULL,nomDB=NULL,savePostgres=FALSE,output=TRUE,
                          sp=NULL,champSp = "euring",
                          spExcluPassage1=c("MOTFLA","SAXRUB","ANTPRA","OENOEN","PHYTRO"),# (Prince et al. 2013 Env. Sc. and Pol.) + "OENOEN","PHYTRO" avis d'expert F. Jiguet,
                          seuilAbondance=.99,
                          onf=TRUE,
                          altitude_min=NULL,altitude_max=800,firstYear=NULL,lastYear=NULL,
                          departement=NULL,
                          id_carre=NULL,insee=NULL,distance_contact="inf",
                          id_output="",
                          operateur=c("Lorrilliere Romain",
                                      "lorrilliere@mnhn.fr"),
                          encodingSave="ISO-8859-1") {





    require(reshape2)
##############################
                                        #tabSpTrim <- read.csv("DB_import/tablesGeneriques/spTRIM_france.csv")
                                        # sps <- tabSpTrim$Code
    ##con=NULL;user=NULL;mp=NULL;nomDB=NULL;savePostgres=FALSE;output=TRUE;
    ##                         sp=NULL;champSp = "euring";
    ##  spExcluPassage1=c("MOTFLA","SAXRUB","ANTPRA","OENOEN","PHYTRO");# (Prince et al. 2013 Env. Sc. and Pol.) + "OENOEN","PHYTRO" avis d'expert F. Jiguet;
    ## seuilAbondance=.99
    ##                       onf=TRUE;
    ##                      altitude_min=NULL;altitude_max=800;firstYear=NULL;lastYear=NULL;
    ##                     departement=NULL;onf=TRUE;
    ##                      id_carre=NULL;insee=NULL;distance_contact="inf";
    ##                     id_output="2017-09-19";
    ##                     operateur=c("Lorrilliere Romain",
    ##                                "lorrilliere@mnhn.fr");
    ##                    encodingSave="ISO-8859-1"

##############################


    start <- Sys.time()
    dateExport <- format(start,"%Y-%m-%d")



    if(is.null(con)) con <- openDB.PSQL(user,mp,nomDB)
    if(is.null(firstYear)) firstYear <- 2001
    if(is.null(lastYear)) lastYear <- as.numeric(format(start,"%Y"))
    if(is.null(altitude_max)) altitude_max <- 8000
    if(is.null(altitude_min)) altitude_min <- 0
    champsHabitat <- FALSE
    selectTypeHabitat <- NULL



    if(is.null(distance_contact)) {
        distance_contact_txt <- ""
    } else {
        if(distance_contact == "100") {
            distance_contact_txt <- " distance_contact in ('LESS25','LESS100') and "
        } else {
            if(distance_contact == "200") {
                distance_contact_txt <- " distance_contact in ('LESS25','LESS100','MORE100','LESS200') and "
            } else {
                if(distance_contact == "inf") {
                    distance_contact_txt <- " distance_contact in ('U','LESS25','LESS100','MORE100','LESS200','MORE200') and "
                } else {
                    stop("distance_contact non pris en charge")
                }}}}

    seuil_txt <- as.character(trunc(seuilAbondance*100))


    if(is.null(distance_contact)) {
        champ_seuil <- paste("abondAll_seuil",seuil_txt,sep="")
    } else {
        if(distance_contact == "100") {
            champ_seuil <- paste("abond100_seuil",seuil_txt,sep="")
        } else {
            if(distance_contact == "200") {
                champ_seuil <- paste("abond200_seuil",seuil_txt,sep="")
            } else {
                if(distance_contact == "inf") {
                    champ_seuil <- paste("abondAll_seuil",seuil_txt,sep="")
                } else {
                    stop("distance_contact non pris en charge")
                }}}}

    flag.query1 <- flag.query2 <- FALSE
    if(!is.null(sp)) {
        if(champSp != "code_sp") {

            sp <- getCode_sp(con,champSp,sp)

        }

        sp1 <- sp[!(sp %in% spExcluPassage1)]
        if(length(sp1) > 0){
            spList1 <- paste("('",paste(sp1,collapse="' , '"),"')",sep="")
            flag.query1 <- TRUE
        }

        sp2 <- sp[sp %in% spExcluPassage1]
        if(length(sp2) > 0){
            spList2 <- paste("('",paste(sp2,collapse="' , '"),"')",sep="")
            flag.query2 <- TRUE
        }

    } else {

        spListExclud <- paste("('",paste(spExcluPassage1,collapse="' , '"),"')",sep="")
        flag.query1 <- flag.query2 <- TRUE
    }


    selectQueryOp <- ""
    selectQueryOp1 <- "SELECT id_inventaire, code_sp, sum(abondance) as abond
				FROM
				observation as o, inventaire as i,carre_annee as ca, carre as c, species_list_indicateur as s
				WHERE
				o.id_inventaire = i.pk_inventaire and
				o.id_carre = c.pk_carre and
				o.id_carre = ca.id_carre and
                                s.pk_species = o.code_sp and o.annee=ca.annee and
				ca.qualite_inventaire_stoc > 0 and
                                s.ebcc and
                                "
    selectQueryOp2 <- "
			GROUP BY
			id_inventaire, code_sp"

    if(!is.null(departement)) depList <- paste("('",paste(departement,collapse="' , '"),"')",sep="")
    if(!is.null(id_carre)) carreList <- paste("('",paste(id_carre,collapse="' , '"),"')",sep="")
    if(!is.null(selectTypeHabitat)) queryTypeHab <- paste(" AND ( ",paste(selectTypeHabitat,collapse=" = TRUE OR ")," = TRUE) ",sep="") else queryTypeHab <- " "

    selectQuery <- paste(distance_contact_txt," i.annee >= ",firstYear,"
and i.annee <= ",lastYear," and c.etude in ('STOC_EPS'",ifelse(onf,", 'STOC_ONF'",""),")  and  c.altitude <= ",altitude_max," and  c.altitude >= ",altitude_min," ",ifelse(is.null(departement),"",paste(" and departement in ",depList," ")),"
",
ifelse(is.null(id_carre),"",paste(" and o.id_carre in ",carreList," ")),"
",
ifelse(!is.null(selectTypeHabitat),queryTypeHab," ")," ", sep="")



    if(flag.query1) {
        selectQueryOp <- paste(selectQueryOp,selectQueryOp1,
                               ifelse(is.null(sp),paste("code_sp not  in ",spListExclud," and "),paste(" code_sp in ",spList1," and ")),"  passage_stoc in (1,2) and",
                               selectQuery,selectQueryOp2)
        if(flag.query2) {
            selectQueryOp <- paste(selectQueryOp,"
                                union
                                ")
        }
    }

    if(flag.query2) {
        selectQueryOp <- paste(selectQueryOp," --  ## begin ## ajout des especes tardives dont on ne garde que le second passage
            ",
            selectQueryOp1,
            ifelse(is.null(sp),paste("code_sp in ",spListExclud," and "),paste(" code_sp in ",spList2," and ")),"  passage_stoc = 2 and",
            selectQuery,selectQueryOp2)
    }










    queryObs <- paste("
select oc.id_carre as site, oc.annee as year, (oc.annee::varchar(4)||oc.id_carre::varchar(100))::varchar(100) as id_carre_annee, oc.id_carre || '_' || oc.annee as carre_annee, c.etude,
qualite_inventaire_stoc, commune,insee,departement,
code_sp, e.scientific_name, e.french_name, e.english_name as nom_anglais, e.euring,e.taxref,
abond_brut as abondance_brut, abond  as count,
altitude, longitude_grid_wgs84,latitude_grid_wgs84, ",
ifelse(champsHabitat," foret_p, ouvert_p, agri_p, urbain_p,
foret_ps, ouvert_ps, agri_ps, urbain_ps,
nbp_foret_p, nbp_ouvert_p, nbp_agri_p, nbp_urbain_p,
nbp_foret_ps, nbp_ouvert_ps, nbp_agri_ps, nbp_urbain_ps, ",""),
" c.db as data_base_name, ",
"'",dateExport,"'::varchar(10) as date_export,
'",operateur[1],"'::varchar(50) as operateur,
'",operateur[2],"'::varchar(50) as email_operateur

from( -- ## begin ## somme sur carre des max par points sur 2 passages
	select id_carre, annee,code_sp,sum(abond_brut) as abond_brut,sum(abond) as abond
	from -- ## begin ## obs max par point sur 2 passages
		(select id_point, annee,code_sp,max(abond_brut) as abond_brut,max(abond) as abond
		from -- ## begin ## correction abondance obs par seuil
			(select id_inventaire,id_point, passage_stoc, annee, code_sp,abond as abond_brut, ",champ_seuil," as seuil_abondance_sp,LEAST(abond, ",champ_seuil,") as abond
			from -- ## begin ## selection classe de distance et different filtre
				(",selectQueryOp,"
				) -- ## end ## selection classe de distance et different filtre
			as opb, espece_abondance_point_seuil as s, inventaire as i
			WHERE
			opb.code_sp = s.pk_species and opb.id_inventaire = i.pk_inventaire

			) -- ## end ## correction abondance obs par seuil
		as op
		group by id_point,annee,code_sp
		) -- ## end ## obs max par point sur 2 passages
	as omp, point as p
	where omp.id_point = p.pk_point
	group by id_carre, annee,code_sp) -- ## end ## somme sur carre des max par points sur 2 passages
as oc, carre as c, species as e, carre_annee as ca

oc.id_carre = c.pk_carre and oc.code_sp = e.pk_species and oc.id_carre = ca.id_carre and oc.annee = ca.annee
order by
oc.id_carre, year,code_sp;",sep="")



                                        # browser()
    cat("\nQUERY 1: Observations:\n\n",queryObs,"\n\n")

    dab <- dbGetQuery(con, queryObs)

    cat("\n --> DONE !\n")


    queryCarreAnnee <- paste("
select i.id_carre, i.annee
from inventaire as i, carre as c
where
i.id_carre = c.pk_carre and passage_stoc in (1,2) ",  ifelse(!onf," and etude = 'STOC_EPS' ",""), " and annee >= ",firstYear,"  and annee <= ",lastYear,"  and altitude <= ",altitude_max, "
group by id_carre, annee;",sep="")

                                        # browser()
    cat("\n QUERY 2: inventaires:\n--------------\n\n",queryCarreAnnee,"\n")

    dinv <- dbGetQuery(con, queryCarreAnnee)
    cat("\n --> DONE !\n")

    dinv$carre_annee <- paste(dinv$id_carre,dinv$annee,sep="_")
    vecSp <- unique(dab$code_sp)

    dinvSp <- expand.grid(dinv$carre_annee,vecSp)
    colnames(dinvSp) <- c("carre_annee","code_sp")

    dab_all <- merge(dab,dinvSp,by=c("carre_annee","code_sp"),all=TRUE)


    dab_all$site <- ifelse(is.na(dab_all$site),substr(dab_all$carre_annee,1,6),dab_all$site)
    dab_all$year <- ifelse(is.na(dab_all$year),substr(dab_all$carre_annee,8,11),dab_all$year)
    dab_all$count[is.na(dab_all$count)] <- 0

    dab_all <- subset(dab_all,select=c("site","year","code_sp","count"))

    tabTRIMw <- reshape(dab_all,idvar = c("site","code_sp"),timevar = "year",direction="wide")



    tabTRIM <- melt(tabTRIMw, id.vars=c("site", "code_sp"))
    colnames(tabTRIM)[3] <- "year"
    tabTRIM$year <- as.numeric(substr(tabTRIM$year,7,11))

    colnames(tabTRIM)[4] <- "count"
    tabTRIM$count[is.na(tabTRIM$count)] <- -1

    spList2 <- paste("('",paste(unique(dab$code_sp),collapse="' , '"),"')",sep="")
    querySp <- paste("select pk_species as code_sp, euring as euring , replace(english_name,' ','_') as english_name, replace(scientific_name,' ','_') as scientific_name from species where pk_species in ",spList2,";",sep="")
    cat("\n QUERY 3: especes:\n--------------\n\n",querySp,"\n")

    dsp <- dbGetQuery(con, querySp)
    cat("\n --> DONE !\n")
    tabTRIM <- merge(tabTRIM,dsp,by="code_sp")

    tabTRIM <- tabTRIM[,c("euring","english_name","scientific_name","site","year","count")]
    tabTRIM <- tabTRIM[order(tabTRIM$euring,tabTRIM$site,tabTRIM$year),]

    tabTRIM$weight <- 1

                                        #if(savePostgres) sqlCreateTable(con,"outcome.FrenchBBS_montaneOpen",d)
    if(is.null(sp)) suffSp <- "allSp" else if(length(sp)<4) suffSp <- paste(sp,collapse="-") else suffSp <- paste(length(sp),"sp",sep="")

    write.table(tabTRIM,paste("export/data_FrenchBBS_TRIM",id_output,"_",suffSp,".csv",sep=""),row.names=FALSE,sep=" ",quote=FALSE,fileEncoding = encodingSave)

    end <- Sys.time() ## heure de fin

    dbDisconnect(con)

    cat("     #      ==> Duree:",round(as.difftime(end - start,units="mins")),"minutes\n")
    if(output) return(tabTRIM)
}








makeTableBrut <- function(con=NULL,user=NULL,mp=NULL,nomDB=NULL,output=TRUE,sp=NULL,champSp = "code_sp",nomChampSp="espece",
                          altitude_min=NULL,altitude_max=NULL,firstYear=NULL,lastYear=NULL,
                          departement=NULL,onf=TRUE,
                          id_carre=NULL,insee=NULL,distance_contact="inf",
                          selectHabitat = NULL, selectTypeHabitat= NULL,champsHabitat=FALSE,
                          formatTrend = FALSE,isEnglish=FALSE,addAbscence=FALSE,
                          id_output="AlexR_2017-11-23", #"NicolasM",
                          operateur=c("Lorrilliere Romain",
                                      "lorrilliere@mnhn.fr"),
                          encodingSave="utf-8",test=FALSE) {


    ##    sp=c("DENMAJ","DENMED","DRYMAR")
    ##    nomDB=NULL;id_carre=c("10100");insee=NULL;
    ##    sp=NULL;champSp = "code_sp";nomChampSp="espece";
###    altitude=NULL;firstYear=NULL;lastYear=NULL;
    ##    departement=NULL;onf=TRUE;
    ##    selectHabitat = NULL; selectTypeHabitat= "urbain_p";
    ##    formatTrend = FALSE;isEnglish=FALSE;addAbscence=FALSE;
    ##    operateur=c("Lorrilliere Romain","lorrilliere@mnhn.fr")
    ##    test=FALSE


    depts <- paste("'",paste(departement,collapse="','"),"'",sep="")
    start <-  Sys.time()
    dateExport <- format(start,"%Y-%m-%d")



    if(!is.null(sp)) {
        if(champSp != "code_sp") {

            sp <- getCode_sp(con,champSp,sp)

        }

    }
    if(is.null(con)) con <- openDB.PSQL(user,mp,nomDB)
    if(is.null(firstYear)) firstYear <- 2001
    if(is.null(lastYear)) lastYear <- as.numeric(format(start,"%Y"))
    if(is.null(altitude_max)) altitude_max <- 8000
    if(is.null(altitude_min)) altitude_min <- 0


        listChampsHabitat <- "pa.p_milieu as habitat_principal, pa.s_milieu as habitat_secondaire, pa.p_dernier_descri as temps_depuis_derniere_description_habitat ,
   pa.foret_p as foret_p, pa.agri_p as agricole_p, pa.urbain_p as urbain_p, pa.ouvert_p as ouvert_p, pa.foret_ps as foret_ps, pa.agri_ps as agricole_ps, pa.urbain_ps as urbain_ps, pa.ouvert_ps as ouvert_ps,
  nbp_foret_p  as carre_nb_pts_foret_p, nbp_ouvert_p as carre_nb_pts_ouvert_p, nbp_agri_p as carre_nb_pts_agricole_p, nbp_urbain_p as carre_nb_pts_urbain_p,
nbp_foret_ps as carre_nb_pts_foret_ps, nbp_ouvert_ps as carre_nb_pts_ouvert_ps, nbp_agri_ps as carre_nb_pts_agricole_ps, nbp_urbain_ps  as carre_nb_pts_urbain_ps, "


        if(is.null(distance_contact)) {
            distance_contact_txt <- ""
        } else {
            if(distance_contact == "100") {
                distance_contact_txt <- " distance_contact in ('LESS25','LESS100') and "
            } else {
                if(distance_contact == "200") {
                    distance_contact_txt <- " distance_contact in ('LESS25','LESS100','MORE100','LESS200') and "
                } else {
                    if(distance_contact == "inf") {
                        distance_contact_txt <- " distance_contact in ('U','LESS25','LESS100','MORE100','LESS200','MORE200') and "
                    } else {
                        stop("distance_contact non pris en charge")
                    }}}}



        if(!is.null(sp)) {
            if(champSp != "code_sp") {

                sp <- getCode_sp(con,champSp,sp)

            }
            spList <- paste("('",paste(sp,collapse="' , '"),"')",sep="")

        }

        if(!is.null(id_carre)) carreList <- paste("('",paste(id_carre,collapse="' , '"),"')",sep="")


        if(!is.null(selectHabitat)) habList <- paste("('",paste(selectHabitat,collapse="' , '"),"')",sep="")
        if(!is.null(departement)) depList <- paste("('",paste(departement,collapse="' , '"),"')",sep="")

        if(!is.null(insee)) inseeList <- paste("('",paste(insee,collapse="' , '"),"')",sep="")

        selectQuery <- paste(distance_contact_txt,ifelse(is.null(sp),"",paste(" code_sp in ",spList," and
                                ")),"
"," i.annee >= ",firstYear,"  and i.annee <= ",lastYear,
" and c.etude in ('STOC_EPS'",ifelse(onf,", 'STOC_ONF'",""),")  and  c.altitude <= ",altitude_max," and  c.altitude >= ",altitude_min,"
",
ifelse(is.null(id_carre),"",paste(" and o.id_carre in ",carreList," ")),"
",
ifelse(is.null(departement),"",paste(" and p.departement in ",depList," ")),"
",
ifelse(is.null(insee),"",paste(" and p.insee in ",inseeList," ")),"
",
ifelse(!is.null(selectHabitat),paste(" and p_milieu in ",habList," ")," "),"
"," ",sep="")


        if(!is.null(selectTypeHabitat)) queryTypeHab <- paste(" AND ( pa.",paste(selectTypeHabitat,collapse=" = TRUE OR pa.")," = TRUE) ",sep="") else queryTypeHab <- ""

        selectQuery <- paste(selectQuery,queryTypeHab)



        query <- paste("
SELECT
  o.pk_observation as code_observation,  o.id_fnat_unique_citation as code_observation_fnat,
  o.id_inventaire as code_inventaire,  i.etude,   i.observateur,  i.email, p.site as nom_site,  p.commune,  p.insee,  p.departement,  o.id_carre as code_carre,    o.id_point as code_point,   o.num_point,     o.date,  o.annee,  i.heure_debut,  i.heure_fin,  i.duree_minute,   o.passage,  i.info_passage,  i.passage_stoc as numero_passage_stoc,  i.nombre_de_passage,  i.temps_entre_passage,  o.espece,   s.scientific_name as nom_scientifique,  s.french_name as nom_francais,s.english_name as nom_anglais,s.euring as code_espece_euring,s.taxref as code_espece_taxref,   o.abondance,  o.distance_contact, i.nuage,  i.pluie,  i.vent,  i.visibilite,  i.neige,  p.altitude,  p.longitude_wgs84,  p.latitude_wgs84,  c.longitude_grid_wgs84,  c.latitude_grid_wgs84,  h.p_milieu,  h.p_type,  h.p_cat1,  h.p_cat2,  h.s_milieu,  h.s_type,  h.s_cat1,  h.s_cat2," , ifelse(champsHabitat,listChampsHabitat,""),"   o.db,  o.date_export as date_import, '",dateExport,"'::varchar(10) as date_export,
'",operateur[1],"'::varchar(50) as operateur,
'",operateur[2],"'::varchar(50) as email_operateur
FROM
  public.point as p,   public.point_annee as pa,  public.carre as c, public.carre_annee as ca, public.inventaire as i,  public.observation as o,  public.species as s,  public.habitat as h
WHERE
  o.id_inventaire = i.pk_inventaire AND   o.id_point = p.pk_point AND  o.id_point = pa.id_point AND  o.annee = pa.annee AND  o.id_carre = ca.id_carre AND  o.annee = ca.annee AND  o.id_carre = c.pk_carre AND  o.espece = s.pk_species AND  o.id_inventaire = h.pk_habitat AND  ",selectQuery,";",sep="")
        if(test) paste(query," LIMIT 100;") else paste(query,";")

        cat("\n QUERY donnÃ©es BRUT:\n--------------\n\n",query,"\n")

                                        # browser()


        d <- dbGetQuery(con, query)

                                        #if(savePostgres) sqlCreateTable(con,"outcome.FrenchBBS_montaneOpen",d)


        if(is.null(sp)) suffSp <- "allSp" else if(length(sp)<4) suffSp <- paste(sp,collapse="-") else suffSp <- paste(length(sp),"sp",sep="")

        fileOut <- paste("export/data_FrenchBBS_BRUT_",id_output,"_",suffSp,"_",firstYear,"_",lastYear,ifelse(isEnglish,"eng","fr"),".csv",sep="")
        write.csv2(d,fileOut,row.names=FALSE)
        cat(" --> ",fileOut,"\n")

        end <- Sys.time() ## heure de fin

        dbDisconnect(con)

        cat("\n     #      ==> Duree:",round(as.difftime(end - start,units="mins")),"minutes\n")
        if(output) return(d)





    }






makeTableVP <- function(con=NULL,user=NULL,mp=NULL,nomDB=NULL,output=TRUE,
                          altitude_min=NULL,altitude_max=NULL,firstYear=NULL,lastYear=NULL,
                          departement=NULL,onf=TRUE,
                          id_carre=NULL,insee=NULL,distance_contact="inf",
                        id_output="AlexR_2017-11-23", #"NicolasM",
                          operateur=c("Lorrilliere Romain",
                                      "lorrilliere@mnhn.fr"),
                          encodingSave="utf-8",test=FALSE) {


    ##    sp=c("DENMAJ","DENMED","DRYMAR")
 ##       nomDB=NULL;id_carre=NULL;insee=NULL;
 ##       sp=NULL;champSp = "code_sp";nomChampSp="espece";
 ##   altitude_min=NULL;altitude_max=NULL;firstYear=NULL;lastYear=NULL;distance_contact=NULL
 ##       departement=NULL;onf=TRUE;champsHabitat=FALSE
 ##       selectHabitat = NULL; selectTypeHabitat= "urbain_p";
 ##       formatTrend = FALSE;isEnglish=FALSE;addAbscence=FALSE;
 ##       operateur=c("Lorrilliere Romain","lorrilliere@mnhn.fr")
 ##       test=FALSE


    depts <- paste("'",paste(departement,collapse="','"),"'",sep="")
    start <-  Sys.time()
    dateExport <- format(start,"%Y-%m-%d")


    if(is.null(con)) con <- openDB.PSQL(user,mp,nomDB)
    if(is.null(firstYear)) firstYear <- 2001
    if(is.null(lastYear)) lastYear <- as.numeric(format(start,"%Y"))
    if(is.null(altitude_max)) altitude_max <- 8000
    if(is.null(altitude_min)) altitude_min <- 0


    if(!is.null(id_carre)) carreList <- paste("('",paste(id_carre,collapse="' , '"),"')",sep="")


    if(!is.null(departement)) depList <- paste("('",paste(departement,collapse="' , '"),"')",sep="")
    if(!is.null(insee)) inseeList <- paste("('",paste(insee,collapse="' , '"),"')",sep="")

    selectQuery <- paste(" and i.annee >= ",firstYear,"  and i.annee <= ",lastYear,
" and c.etude in ('STOC_EPS'",ifelse(onf,", 'STOC_ONF'",""),")  and  c.altitude <= ",altitude_max," and  c.altitude >= ",altitude_min,"
",
ifelse(is.null(id_carre),"",paste(" and o.id_carre in ",carreList," ")),"
",
ifelse(is.null(departement),"",paste(" and p.departement in ",depList," ")),"
",
ifelse(is.null(insee),"",paste(" and p.insee in ",inseeList," ")),sep="")



     query <- paste(" SELECT
  o.id_inventaire as code_inventaire,  i.etude as Etude,
  p.site as Site, FALSE as Pays,
  p.departement as Département, p.insee as INSEE,
  p.commune as Commune, ('CARRE N°'||o.id_carre::varchar) as \"N°..Carré.EPS\",
  o.date as Date,i.heure_debut as Heure,
  i.heure_fin as \"Heure.fin\",  i.passage_stoc as \"N°..Passage\",
  i.observateur as Observateur,  i.email as Email,
  ('Point N°'||o.num_point::varchar) as EXPORT_STOC_TEXT_EPS, p.altitude as Altitude,
  '0'::varchar(1) as Classe, o.espece as Espèce,
  o.abondance as Nombre,o.distance_contact as \"Distance.de.contact\",
  p.longitude_wgs84 as Longitude, p.latitude_wgs84 as Latitude,
  '2' as \"Type.de.coodonnées\", 'WGS84' as \"Type.de.coordonnées.lambert\",
  i.nuage as \"EPS.Nuage\",  i.pluie as \"EPS.Pluie\",
  i.vent as \"EPS.Vent\",  i.visibilite as \"EPS.Visibilité\",
  i.neige as \"EPS.Neige\", 'NA' as \"EPS.Transport\",
  h.p_milieu as \"EPS.P.Milieu\",  h.p_type as \"EPS.P.Type\",
  h.p_cat1 as \"EPS.P.Cat1\", h.p_cat2 as \"EPS.P.Cat2\",
  h.s_milieu as \"EPS.S.Milieu\",  h.s_type as \"EPS.S.Type\",
  h.s_cat1 as \"EPS.S.Cat1\", h.s_cat2 as \"EPS.S.Cat2\",
  o.db,  o.date_export as date_import,
  '",dateExport,"'::varchar(10) as date_export,
  '",operateur[1],"'::varchar(50) as operateur,
  '",operateur[2],"'::varchar(50) as email_operateur
FROM
  public.point as p,   public.point_annee as pa,  public.carre as c, public.carre_annee as ca, public.inventaire as i,  public.observation as o,  public.species as s,  public.habitat as h
WHERE
  o.id_inventaire = i.pk_inventaire AND   o.id_point = p.pk_point AND  o.id_point = pa.id_point AND  o.annee = pa.annee AND  o.id_carre = ca.id_carre AND  o.annee = ca.annee AND  o.id_carre = c.pk_carre AND  o.espece = s.pk_species AND  o.id_inventaire = h.pk_habitat ",selectQuery,sep="")


    if(test) paste(query," LIMIT 100;") else paste(query,";")

    cat("\nQUERY: \n",query,"\n\n")

    d <- dbGetQuery(con, query)


    fileOut <- paste("export/data_FrenchBBS_VigiePlume_",id_output,"_",firstYear,"_",lastYear,".csv",sep="")
    write.csv2(d,fileOut,row.names=FALSE)
    cat(" --> ",fileOut,"\n")

    end <- Sys.time() ## heure de fin
    dbDisconnect(con)
    cat("\n     #      ==> Duree:",round(as.difftime(end - start,units="mins")),"minutes\n")
    if(output) return(d)
}
















    test <- function() {



    }



    historicCarre <- function(con=NULL,user=NULL,mp=NULL,nomDB=NULL,
                              firstYear = NULL,lastYear=NULL,altitude=NULL,
                              departement=NULL,id_carre=NULL,onf=TRUE,output=TRUE,
                              isEnglish=FALSE,addAbscence=FALSE,
                              id_output="",
                              operateur=c("Lorrilliere Romain",
                                          "lorrilliere@mnhn.fr"),
                              encodingSave="utf-8") {

        ## --------------------------
                                        #con=NULL;user=NULL;mp=NULL;nomDB=NULL;firstYear = NULL;lastYear=NULL;altitude=NULL;departement=NULL;id_carre=c("010100","010120");onf=TRUE;output=TRUE

        ## --------------------------



        start <-  Sys.time()
        dateExport <- format(start,"%Y-%m-%d")


        if(is.null(con)) con <- openDB.PSQL(user,mp,nomDB)
        if(is.null(firstYear)) firstYear <- 2001
        if(is.null(lastYear)) lastYear <- as.numeric(format(start,"%Y"))
        if(is.null(altitude)) altitude <- 8000

        if(!is.null(departement)) depList <- paste("('",paste(departement,collapse="' , '"),"')",sep="")

        if(!is.null(id_carre)) carreList <- paste("('",paste(id_carre,collapse="' , '"),"')",sep="")


        selectQuery <- paste(" i.annee >= ",firstYear,"  and i.annee <= ",lastYear,
                             " and i.etude in ('STOC_EPS'",ifelse(onf,", 'STOC_ONF'",""),")  and  c.altitude <= ",altitude,"
",
ifelse(is.null(departement),"",paste(" and c.departement in ",depList," ")),"
",
ifelse(!is.null(id_carre),paste(" and i.id_carre in ",carreList," ")," "),"
"," ", sep="")


        query <-paste("select i.id_carre, c.departement,c.altitude,
i.annee, i.etude,  i.observateur, i.email
from inventaire as i, carre as c
where i.id_carre = c.pk_carre and ",selectQuery,"
group by i.id_carre, i.etude,c.departement,c.altitude,i.annee,i.observateur,i.email
order by i.id_carre, i.annee;")

        cat("\n QUERY historique CARRE:\n--------------\n\n",query,"\n")

                                        # browser()
        d <- dbGetQuery(con, query)

        if(isEnglish) {
            cat(" - Traduction des noms de colonnes\n")
            d <- trad_fr2eng(d)

        }


        fileOut <- paste("export/Historic_carre_",id_output,"_",firstYear,"_",lastYear,ifelse(isEnglish,"eng","fr"),".csv",sep="")
        write.csv2(d,fileOut,row.names=FALSE)
        cat(" --> ",fileOut,"\n")


        end <- Sys.time() ## heure de fin

        dbDisconnect(con)

        cat("\n     #      ==> Duree:",round(as.difftime(end - start,units="mins")),"minutes\n")
        if(output) return(d)


    }




    historicToutCarre  <- function(con,anneeMax=2016) {
        require(ggplot2)
        require(reshape2)
        query <-paste("select id_carre, annee from inventaire where annee <= ",anneeMax," group by id_carre, annee order by id_carre, annee;")

                                        # browser()
        d <- dbGetQuery(con, query)
        d$PA <- 1

        dan <- aggregate(PA ~ annee, d, sum)

        dd <- cast(d,id_carre~annee,mean)
        rnames <- dd$id_carre
        cnames <- colnames(dd)[-1]
        dd <- as.matrix(dd[,-1])
        rownames(dd) <- rnames
        colnames(dd) <- cnames
        dd[is.nan(dd)] <- 0


        nb_carre_diff <- nrow(dd)

        colnames(dan)[2] <- "nbCarre"
        dan$Nouveaux <- NA
        dan$NonAjour <- NA
        dan$Arrete <- NA
        dan$Nouveaux[1] <- sum(dd[,1])
        dan$NonAjour[1] <- 0
        dan$Arrete[1] <- 0
        dan$Arrete[ncol(dd)] <- NA

        for(j in 2:ncol(dd)) {
            if(j==2)
                dan$Nouveaux[j] <- sum(dd[dd[,j]==1 & dd[,j-1]==0,j]) else dan$Nouveaux[j] <- sum((dd[dd[,j]==1 & rowSums(dd[,1:j-1])==0,j]))
        }
                                        #-as.numeric(rowSums(dd[dd[,j]==1 & dd[,j-1]==0,1:j-1])>0)))


        for(j in 2:ncol(dd))
            if(j<ncol(dd))
                dan$NonAjour[j] <- sum(as.numeric(rowSums(dd[(dd[,j]==0 & dd[,j-1]==1),j:ncol(dd)])>0)) else  dan$NonAjour[j] <- sum(dd[(dd[,j]==0 & dd[,j-1]==1),j-1])

        for(j in 2:(ncol(dd)-1))
            dan$Arrete[j] <- sum(as.numeric(rowSums(dd[(dd[,j]==0 & dd[,j-1]==1),j:ncol(dd)])==0))


        write.csv2(dan,"Output/carreSTOCactif.csv")

        ggAnnee <- melt(dan,"annee")

        gg <- ggplot(subset(ggAnnee,variable != "NonAjour"),aes(x=annee,y=value,colour=variable))+geom_line(size=1.5)+geom_point(size=2)
        gg <- gg + scale_colour_manual(values=c("nbCarre" = "#0d259f","Nouveaux"="#0d9f1b","Arrete" = "#9f0d0d" ),
                                       labels=c("nbCarre" = "CarrÃ©s actif","Nouveaux"="Nouveaux carrÃ©s","Arrete" = "CarrÃ©s arrÃªtÃ©s"),name="" )
        gg <- gg + labs(title="",x="",y="")
        ggsave("Output/carreSTOC.png",gg)



        birth <- apply(dd,1,FUN = function(x) min(which(x==1)))
        dage <- dd
        for(i in 1:nrow(dd)) {
            cc <- names(birth[i])
            b <- birth[i]
            dage[cc,b:ncol(dage)] <- 1:(ncol(dage)-b+1)
        }

        dage <- dage*dd
        dage <- as.data.frame(as.matrix(dage))
        dage2 <- data.frame(id_carre=row.names(dage),dage)

        dage2 <- melt(dage2,"id_carre")
        colnames(dage2) <- c("id_carre","annee","age")
        dage2$annee <- as.numeric(substring(as.character(dage2$annee),2,5))

        dage2 <- subset(dage2,age>0)
        ggAge <- aggregate(id_carre~annee+age,dage2,length)


        gg <- ggplot(ggAge,aes(age,id_carre))+ geom_col() + facet_wrap(~annee)
        gg <- gg + labs(title="Pyramide des ages des stations STOC EPS",x="Age",y="Nombre de carrÃ© STOC actifs")

        ggsave("Output/carreSTOC_pyramideAge.png",gg)

        write.csv2(dan,"Output/carreSTOCage.csv")


    }





    makeTableEBBA2 <- function(con=NULL,user=NULL,mp=NULL,nomDB=NULL,output=FALSE,encodingSave="utf-8") {
                                        #spExcluPassage1=c("MOTFLA","SAXRUB","ANTPRA","OENOEN","PHYTRO"),# (Prince et al. 2013 Env. Sc. and Pol.) + "OENOEN","PHYTRO" avis d'expert F. Jiguet

        if(is.null(con)) con <- openDB.PSQL(user,mp,nomDB)

        query <- paste("select sp.id_carre||to_char(to_date(sp.date,'YYYY-MM-DD'),'YYYYMMDD') as \"Survey number\",
to_char(to_date(sp.date,'YYYY-MM-DD'),'DD.MM.YYYY') as \"Date of survey\",nbp * 5 as \"Duration of survey\", 1 as \"Field Method\",
c.latitude_points_wgs84 as \"Latitude\",c.longitude_points_wgs84 as \"Longitude\", '' as \"Square code\",
lpad(euring::text, 5, '0') as \"EBBA2 species code\", s.scientific_name as \"EBBA2 scientific name\"
from
     (select o.date,o.id_carre,passage_stoc,code_sp, sum(abondance) as abondance
     from inventaire as i , observation as o
     where
     o.id_inventaire = i.pk_inventaire and
     code_sp not  in  ('MOTFLA' , 'SAXRUB' , 'ANTPRA','OENOEN','PHYTRO') and passage_stoc in (1,2) and
     o.annee >=2003 and o.annee <= 2017
     group by o.date, o.id_carre, passage_stoc,code_sp
     union
     select o.date,o.id_carre,passage_stoc,code_sp, sum(abondance) as abondance
     from inventaire as i , observation as o
     where
     o.id_inventaire = i.pk_inventaire and
     code_sp in  ('MOTFLA' , 'SAXRUB' , 'ANTPRA','OENOEN','PHYTRO') and passage_stoc = 2 and
     o.annee >=2003 and o.annee <= 2017
     group by o.date, o.id_carre, passage_stoc,code_sp
     ) as sp,
     (select p.date, p.id_carre, count(p.id_point) as nbp
     from (
        select o.date, o.id_carre, o.id_point
        from inventaire as i , observation as o
        where o.id_inventaire = i.pk_inventaire and passage_stoc in (1,2) and o.annee >=2003 and o.annee <= 2017
        group by o.date, o.id_carre, o.id_point ) as p
     group by p.date, p.id_carre) as cnbp, carre as c, species as s
where
sp.id_carre = cnbp.id_carre and sp.date = cnbp.date and sp.id_carre = c.pk_carre and sp.code_sp=s.pk_species and  c.etude in ('STOC_EPS', 'STOC_ONF');
")

        cat("\n QUERY EBBA2:\n--------------\n\n",query,"\n")

        d <- dbGetQuery(con, query)

        write.csv2(d,paste("export/data_FrenchBBS_EBBA2_2003_2017.csv",sep=""),row.names=FALSE,fileEncoding=encodingSave)

        dbDisconnect(con)
        return(d)

    }





    makeTableSampledCarre <- function(con=NULL,user=NULL,mp=NULL,nomDB=NULL,output=TRUE,sp=NULL,champSp = "code_sp",nomChampSp="espece",
                                      altitude=NULL,firstYear=NULL,lastYear=NULL,
                                      departement=NULL,carre = NULL,onf=TRUE,
                                      selectHabitat = NULL, selectTypeHabitat= NULL,
                                      formatTrend = FALSE,isEnglish=FALSE,addAbscence=FALSE,
                                      id_output="AlexR_2017-11-23", #"NicolasM",
                                      operateur=c("Lorrilliere Romain",
                                                  "lorrilliere@mnhn.fr"),
                                      encodingSave="utf-8",test=FALSE) {


        con=NULL;savePostgres=FALSE;output=TRUE;sp=NULL;champSp = "code_sp";
        spExcluPassage1=c("MOTFLA","SAXRUB","ANTPRA")  ;seuilAbondance=.99;
        champsHabitat=TRUE;champsCoordGrid=TRUE;altitude=NULL;firstYear=NULL;lastYear=NULL;
        departement="44";onf=TRUE;distance_contact="100";
        selectHabitat = NULL; selectTypeHabitat= NULL#c("urbain_ps","agri_ps");
        formatTrend = FALSE;anglais=FALSE;addAbscence=FALSE;
        id_output="VincentP_2017-10-16"; #"NicolasM";
        operateur=c("Lorrilliere Romain",
                    "lorrilliere@mnhn.fr");
        encodingSave="utf-8"



        depts <- paste("'",paste(departement,collapse="','"),"'",sep="")
        start <-  Sys.time()
        dateExport <- format(start,"%Y-%m-%d")


        if(is.null(con)) con <- openDB.PSQL(user,mp,nomDB)
        if(is.null(firstYear)) firstYear <- 2001
        if(is.null(lastYear))
            lastYear <- as.numeric(format(start,"%Y"))
        d<-if(is.null(altitude))
               altitude <- 8000



        if(!is.null(sp)) {
            if(champSp != "code_sp") {

                sp <- getCode_sp(con,champSp,sp)

            }
            spList <- paste("('",paste(sp,collapse="' , '"),"')",sep="")

        }


        if(!is.null(selectHabitat)) habList <- paste("('",paste(selectHabitat,collapse="' , '"),"')",sep="")
        if(!is.null(departement)) depList <- paste("('",paste(departement,collapse="' , '"),"')",sep="")

        selectQuery <- paste(ifelse(is.null(sp),"",paste(" code_sp in ",spList," and
                                ")),"
"," i.annee >= ",firstYear,"  and i.annee <= ",lastYear,
" and c.etude in ('STOC_EPS'",ifelse(onf,", 'STOC_ONF'",""),")  and  p.altitude <= ",altitude,"
",
ifelse(is.null(departement),"",paste(" and p.departement in ",depList," ")),"
",
ifelse(!is.null(selectHabitat),paste(" and p_milieu in ",habList," ")," "),"
"," ", sep="")




    }







