#
# Home Range App
# This is the server logic of Shiny web application. 
#

library(shiny)
library(sp)
library(rgdal)
library(raster)
library(adehabitatHR)
library(leaflet)

# determine UTM zone from mean lon & lat
UTM_zone <- function(m) {
  meanLON <- mean(m[,'LON']) + 180
  meanLAT <- mean(m[,'LAT'])
  n_zone <- as.character(ceiling(meanLON / 6))
  hemi <- ifelse(meanLAT < 0,'S','N')
  c(n_zone, hemi)
}

shinyServer(function(input, output, clientData, session) {
  
  # reactive values :
  #   hr = HR polygon in UTM CRS (class SpatialPolygon)
  # init with NULL
  rv <- reactiveValues(hr=NULL)
  
  # session variables :
  #   crs_longlat = WGS84 CRS
  #   crs_utm = relocs UTM CRS
  #   kud = UD raster from relocs with h (class kernelUD)
  crs_longlat <- CRS("+proj=longlat +datum=WGS84 +no_defs")
  crs_utm <- NULL
  kud <- NULL
  # marker & polygon style 
  mk_rad <- 2
  mk_col <-"#C00"
  mk_opa <- 0.6
  pl_col <- "#303"
  pl_wgt <- 2
  pl_opa <- 0.8
  
  
  # sequence 1 : txt input file is provided
  
  # latlon matrix is reactive to input file
  #coord_mat <- read.table("/srv/shiny-server/data/inputdata.txt", header=T, sep="\t")
  #coord_mat <- reactive({
  #  in_file <- input$fichier1
  #  crs_utm <<- NULL
  #  kud <<- NULL
  #  rv$hr <- NULL
  #  if (is.null(in_file))
  #    return(NULL)
  #  try({
  #    df <- read.table(in_file$datapath, header=T, sep="\t")
  #    m <- as.matrix(df[,c("LON","LAT")])
  #    mfilter <- (-180 <= m[,'LON'] & m[,'LON'] <= 180 & -90 <= m[,'LAT'] & m[,'LAT'] <= 90)
  #    m[mfilter,]
  #  })
  #})

  coord_mat <- reactive({
    in_file <- read.table("/srv/shiny-server/data/inputdata.txt", header=T, sep="\t")
    crs_utm <<- NULL
    kud <<- NULL
    rv$hr <- NULL
    if (is.null(in_file))
      return(NULL)
    try({
      df <- read.table("/srv/shiny-server/data/inputdata.txt", header=T, sep="\t")
      m <- as.matrix(df[,c("LON","LAT")])
      mfilter <- (-180 <= m[,'LON'] & m[,'LON'] <= 180 & -90 <= m[,'LAT'] & m[,'LAT'] <= 90)
      m[mfilter,]
    })
  })

  # UTM SpatialPoints is reactive to latlon matrix
  coordutm_sp <- reactive({
    m <- coord_mat()
    if (is.null(m))
      return(NULL)
    try({
      relocs <- NULL
      if (dim(m)[1] > 0) {
        # transform points coordinates to UTM zone (derived from central location of the set)
        utmz <- UTM_zone(m)
        withProgress(message = 'Transforming coords to UTM', value=0, {
          crs_utm <<- paste0('+proj=utm +zone=', utmz[1], 
                             ifelse(utmz[2]=='S', ' +south', ''),
                             ' +datum=WGS84 +units=m +no_defs')
          relocs_wgs84 <- SpatialPoints(m, proj4string=crs_longlat)
          relocs <- spTransform(relocs_wgs84, crs_utm)
          setProgress(value=1)
        })
      }
      relocs
    })
  })

  # sequence 1 bis : leaflet output rendering is reactive to input matrix
  # check if input matrix is valid and not null
  output$carte <- renderLeaflet({
    m <- coord_mat()
    validate(need(!inherits(m, "try-error"), "Parsing error. Please check input file."),
             need(try(!is.null(m) && dim(m)[1] > 0), "Empty data. Please select input file.")
    )
    #lid_m <- paste0("m_",seq_len(dim(m)[1]))
    
    leaflet() %>%
      addTiles(group = "OSM Mapnik") %>%
      addProviderTiles("OpenTopoMap", group = "OSM OpenTopoMap") %>%      
      addProviderTiles("Esri.WorldImagery", group = "ESRI Sat") %>%      
      addMarkers(data=m, clusterOptions = markerClusterOptions(), group="data (clustered)") %>%
      addCircleMarkers(data=m, radius=mk_rad, stroke=F, fillOpacity=mk_opa, fillColor=mk_col, group="data (individual)") %>%
      addLayersControl(
          baseGroups = c("OSM Mapnik", "OSM OpenTopoMap", "ESRI Satellite"),
          overlayGroups = c("data (individual)", "data (clustered)"),
          options = layersControlOptions(collapsed = FALSE)
        ) %>%
      hideGroup("data (individual)")
  })
  output$cartenote <- renderUI({
    m <- coord_mat()
    notify <- ""
    validate(need(!inherits(m, "try-error"), notify),
             need(!is.null(m), notify)
    )
    if (dim(m)[1] > 1000) {
      notify <- p("",br(),"NOTE : layer",strong("data(individual)"),"may be slow to render for large datasets")
    }
    notify
  })
  
  # checkbox to swith between clustered / individual points
  # observeEvent(input$checkmap, {
  #   m <- coord_mat()
  #   validate(need(!inherits(m, "try-error"), "Parsing error. Please check input file."),
  #            need(try(!is.null(m) && dim(m)[1] > 0), "Empty data. Please select input file.")
  #   )
  #   #lid_m <- paste0("m_",seq_len(dim(m)[1]))
  #   if (input$checkmap) {
  #     proxy <- leafletProxy("carte")
  #     proxy %>% clearMarkers()
  #     proxy %>% addMarkers(data=m, clusterOptions = markerClusterOptions())
  #   }
  #   else {
  #     proxy <- leafletProxy("carte")
  #     # ?? marche pas # proxy %>% removeMarker(layerId=lid_m)
  #     proxy %>% clearMarkerClusters()
  #     proxy %>% addCircleMarkers(data=m, radius=2, stroke=F, fillOpacity=0.5, fillColor="#909")
  #   }
  # })
  
  # sequence 1 ter : nbpoints + href rendering and h input filling is reactive to input matrix
  # check if input matrix is valid and not null
  # [nbpoints rendering make 'Estimate' button visible]
  output$nbpoints <- renderText({
    m <- coord_mat()
    validate(need(!inherits(m, "try-error"), "NA"),
             need(!is.null(m), "NA")
    )
    dim(m)[1]
  })
  
  # sequence 1 ter ... end
  # display href (+ update h input)
  output$href <- renderText({
    relocs <- coordutm_sp()
    validate(need(!inherits(relocs, "try-error"), "NA"),
             need(!is.null(relocs), "NA")
    )
    coords_UTM <- slot(relocs,"coords")
    n <- dim(coords_UTM)[1]
    if (n > 0) {
      sigma <- sqrt(0.5 * (var(coords_UTM[,1]) + var(coords_UTM[,2])))
      href <- sigma * n ^ (-1/6)
      updateNumericInput(session, 'h', label='h = ', value=round(href,0))
      paste("href", "=", round(href,1))
    } else {
      updateNumericInput(session, 'h', label='h = ', value=NA)
      "href = NA"
    }
  })

  # sequence 2 : KUD raster + HR polygon + leaflet output updating
  #   is reactive to 'Estimate' button clicking. 
  # we assume that relocs SpatialPoints is not null
  # (since 'Estimate' button is visible)
  observeEvent(input$go, {
    withProgress(message = 'Estimating UD', value=0, {
      kud <<- kernelUD(coordutm_sp(), grid=200, h=input$h)
      setProgress(value=0.8, message=paste0('Getting HR from ',input$pud,'% UD'))
      plyg_utm <- getverticeshr(kud, percent=input$pud, unout='km2')
      proj4string(plyg_utm) <- crs_utm
      plyg_longlat <- spTransform(plyg_utm, crs_longlat)
      setProgress(1)
    })
    rv$hr <- plyg_utm
    proxy <- leafletProxy("carte")
    proxy %>% addPolygons(layerId="HR", data=plyg_longlat, color=pl_col, opacity=pl_opa, weight=pl_wgt, fillColor=pl_col)
  })
   
  
  # sequence 3 : HR polygon + leaflet output updating
  #   is reactive to '% UD' slider change
  #   ...ONLY IF kud is not null !!
  observeEvent (input$pud, {
    if (!is.null(kud)) {
      withProgress(value=0, message=paste0('Getting HR from ',input$pud,'% UD'), {
        plyg_utm <- getverticeshr(kud, percent=input$pud, unout='km2')
        proj4string(plyg_utm) <- crs_utm
        plyg_longlat <- spTransform(plyg_utm, crs_longlat)
        setProgress(1)
      })
      rv$hr <- plyg_utm
      proxy <- leafletProxy("carte")
      proxy %>% addPolygons(layerId="HR", data=plyg_longlat, color=pl_col, opacity=pl_opa, weight=pl_wgt, fillColor=pl_col)
    }
  })
  
  # sequence 2/3 bis : HR area rendering
  #   is reactive to HR polygon computing
  # ['size' rendering make 'Download' button visible]
  output$size <- renderText({
    validate(need(!inherits(rv$hr, "try-error"), "NA"),
             need(!is.null(rv$hr), "NA")
    )
    hr <- rv$hr
    hr$area
  })  

  # sequence 4 : shapefile creation & transfer 
  #   is reactive to 'Download' button clicking
  output$downloadSHP <- downloadHandler(
    filename = function() { 
      paste('export_shiny_UD',input$pud,'.zip', sep='') 
    },
    content = function(fname) {
      tmpdir <- tempdir()
      shpbasename <- paste0('export_shiny_UD',input$pud)
      setwd(tempdir())
      hr <- rv$hr
      writeOGR(hr, tmpdir, shpbasename,'ESRI Shapefile',overwrite_layer=T)
      zip(zipfile=fname, files=list.files(tmpdir,pattern=paste0("^",shpbasename,"\\.")))
    },
    contentType = "application/zip"
  )

})
