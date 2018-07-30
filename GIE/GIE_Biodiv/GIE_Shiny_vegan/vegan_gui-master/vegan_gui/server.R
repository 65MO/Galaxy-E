library(shiny)
library(vegan)


function(input, output) {


  getData <- reactive({

    inFile_1 <- input$file1

    if (is.null(input$file1))
      return(NULL)

    read.csv(inFile_1$datapath)

  })

  getData_2 <- reactive({

    inFile_2 <- input$file2

    if (is.null(input$file2))
      return(NULL)

    read.csv(inFile_2$datapath)

  })


  output$rawdata <- renderDataTable(getData())

  output$rawdata_2 <- renderDataTable(getData_2())

  output$rarecurve <- renderPlot({
    withProgress(message = 'Computing rarefaction curves', value = 0.45, {
      rarecurve(getData(), main = "Rarefaction Curves")
    })

  })

  output$diversity <- renderPlot({
    withProgress(message = 'Computing diversity', value = 0.40, {
      barplot(diversity(getData(), index = input$variable), main = "Diverstity across sites", names.arg = seq(1, dim(getData())[1]))
    })
  })

  output$ordination <- renderPlot({
    withProgress(message = 'Computing ordination', value = 0.45, {
      ord <- metaMDS(getData())
      plot(ord, type = "n")
      points(ord, display = "sites", cex = 0.8, pch = 21, col = "red", bg = "yellow")
      text(ord, display = "spec", cex = 0.7, col = "blue")
    })
  })

  output$ordination_stress <- renderPlot({
    withProgress(message = 'Computing stress', value = 0.55, {
      ord <- metaMDS(getData())
      stressplot(ord)
    })
  })

  output$ordination_env_fit <- renderPlot({
    withProgress(message = 'Computing CCA', value = 0.55, {
      ord <- cca(getData() ~ ., getData_2())
      plot(ord)
    })
  })

}
