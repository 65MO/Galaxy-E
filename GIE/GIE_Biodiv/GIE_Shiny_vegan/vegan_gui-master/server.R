library(shiny)
library(vegan)


  # load modules
for (f in list.files('./modules')) {
    source(file.path('modules', f), local=TRUE)
}

function(input, output) {
File_1<-NULL
File_2<-NULL

  getData <- reactive({

    inFile_1 <- input$file1
    
    if (is.null(input$file1))
      return(NULL)

    File_1<<-read.csv(inFile_1$datapath)

  })


galaxyOccs<- callModule(galaxyOccs_MOD, 'c1_galaxyOccs', rvs)
  observeEvent(input$galaxyfile1,{
   File_1 <<- galaxyOccs()
   output$rawdata<- renderDataTable(File_1)
})

   observeEvent(input$galaxyfile2,{
   File_2 <<- galaxyOccs()
    output$rawdata_2<- renderDataTable(File_2)
})
   getData_2 <- reactive({

    inFile_2 <- input$file2

    if (is.null(input$file2))
      return(NULL)

    File_2 <<-read.csv(inFile_2$datapath)

  })


  output$rawdata <- renderDataTable(getData())

  output$rawdata_2 <- renderDataTable(getData_2())

  output$rarecurve <- renderPlot({
    withProgress(message = 'Computing rarefaction curves', value = 0.45, {
      rarecurve(File_1, main = "Rarefaction Curves")
    })

  })

  output$diversity <- renderPlot({
    withProgress(message = 'Computing diversity', value = 0.40, {
      barplot(diversity(File_1, index = input$variable), main = "Diverstity across sites", names.arg = seq(1, dim(File_1)[1]))
    })
  })

  output$ordination <- renderPlot({
    withProgress(message = 'Computing ordination', value = 0.45, {
      ord <- metaMDS(File_1)
      plot(ord, type = "n")
      points(ord, display = "sites", cex = 0.8, pch = 21, col = "red", bg = "yellow")
      text(ord, display = "spec", cex = 0.7, col = "blue")
    })
  })

  output$ordination_stress <- renderPlot({
    withProgress(message = 'Computing stress', value = 0.55, {
      ord <- metaMDS(File_1)
      stressplot(ord)
    })
  })

  output$ordination_env_fit <- renderPlot({
    withProgress(message = 'Computing CCA', value = 0.55, {
      ord <- cca(File_1 ~ ., File_2)
      plot(ord)
    })
  })

}
