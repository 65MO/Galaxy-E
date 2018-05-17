# server.R
function(input, output) {
    
    # build data with 2 places
    data=data.frame(x=inputstn$LONGITUDE, y=inputstn$LATITUDE, id=inputstn$GARDENNAME)
    
    # create a reactive value that will store the click position
    data_of_click <- reactiveValues(clickedMarker=NULL)

    # Leaflet map with 2 markers
    output$map <- renderLeaflet({
        leaflet() %>% 
          setView(lng=-3.916942 , lat =47.868303, zoom=18) %>%
          addTiles(options = providerTileOptions(noWrap = TRUE)) %>%
          addCircleMarkers(data=data, ~x , ~y, layerId=~id, popup=~id, radius=8 , color="black",  fillColor="red", stroke = TRUE, fillOpacity = 0.8)
    })

    # store the click
    observeEvent(input$map_marker_click,{
        data_of_click$clickedMarker <- input$map_marker_click
    })
    
    # Make a barplot or scatterplot depending of the selected point
    output$plot=renderPlot({
        my_place=data_of_click$clickedMarker$id
        if(is.null(my_place)){my_place="place1"}
        if(my_place=="place1"){
            plot(rnorm(1000), col=rgb(0.9,0.4,0.1,0.3), cex=3, pch=20)
        }else{
            barplot(rnorm(10), col=rgb(0.1,0.4,0.9,0.3))
        }    
    })
}
