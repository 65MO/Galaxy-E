galaxyOccs_UI <- function(id) {
  ns <- NS(id)
  python.load("/import_list_history.py")
  x <- python.call("x")
  v<-list()
  # This one is a tricky one, if history contain many dataset, x is gonna be a list of list
  # But in the case where there is only one dataset, x will be just a list.
  # So I test the first element of the list, if it's a another list it will be a lenght more than 1
  # else it's an element of the list, and length will be 1

  l<-length(x[[1]])
  if(l == 1) {
     if(x$'extension' == 'csv'){
            name<-paste(x$'hid',x$'name')
            id<-unname(x$'hid')
            v[[name]]<-id
        }

  }else{
  l<-length(x)
  for (y in 1:l) {
        if(x[[y]]$'extension' == 'csv'){
            name<-paste(x[[y]]$'hid',x[[y]]$'name')
            id<-unname(x[[y]]$'hid')
            v[[name]]<-id
        }
  }
  }
  tagList(
    tags$div(title='Galaxy portal.',
             selectInput(ns("userCSV"), label = "Select from your Galaxy History User csv file",
                choices = v))
         )

  
}





galaxyOccs_MOD <- function(input, output, session, rvs) {

  readOccsCSV <- reactive({
  print(input$userCSV)
  command=paste('python /import_csv_user.py',input$userCSV)
   system(command)
    path=paste('/import/',input$userCSV,sep="")
    csv <- read.csv(path)


  return(csv)
})} 
