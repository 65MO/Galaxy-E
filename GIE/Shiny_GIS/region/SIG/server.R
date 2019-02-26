# server.R

# Insantiate leaflet map
map <- leaflet()
map <- addTiles(map)

shinyServer(
  function(input, output) {

    output$map <- renderLeaflet({
      stn <- subset(inputstn, REGION == input$REGION)
      map  <- addMarkers(map, stn$LONGITUDE, stn$LATITUDE, popup=stn$ID)
      map
    })
  }
)
