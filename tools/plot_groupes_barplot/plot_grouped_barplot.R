library('getopt')

option_specification = matrix(c(
  'input_file', 'i', 2, 'character',
  'output_pdf_file', 'p', 2, 'character',
  'output_png_file', 'o', 2, 'character',
  'output_svg_file', 's', 2, 'character',
  'data_columns', 'd', 2, 'list',
  'names', 'a', 2, 'character',
  'names_column', 'n', 2, 'integer',
  'xlab', 'x', 2, 'character',
  'log', 'g', 2, 'logical',
  'col', 'c', 2, 'list',
  'bottom_margin', 'b', 2, 'integer',
  'left_margin', 'l', 2, 'integer',
  'top_margin', 't', 2, 'integer',
  'right_margin', 'r', 2, 'integer',
  'legend_pos','e',2,'character',
  'replace_null','u',2,'logical',
  'order','w',2,'logical',
  'header','y',2,'logical'
), byrow=TRUE, ncol=4);

options = getopt(option_specification);

header = TRUE
if(!is.null(options$header)) header = options$header

data = read.table(options$input_file, sep = '\t', h = header)
if(!is.null(options$replace_null) && options$replace_null){
  data[data == 0] = NA
}
if(!is.null(options$order) && options$order){
  order = order(data[,2])
  data = data[order,]
}


data_columns = c(2,3)
if(!is.null(options$data_columns)){
  data_columns = unlist(strsplit(options$data_columns, split=","))
  data_columns = sapply(data_columns,as.integer)
  } 
names_column = 1
if(!is.null(options$names_column)) names_column = options$names_column

margin = c(5,19,1,1)
if(!is.null(options$bottom_margin)) margin[1] = options$bottom_margin
if(!is.null(options$left_margin)) margin[2] = options$left_margin
if(!is.null(options$top_margin)) margin[3] = options$top_margin
if(!is.null(options$right_margin)) margin[4] = options$right_margin

xlab = ""
if(!is.null(options$xlab)) xlab = options$xlab

col = c('blue','red')
if(!is.null(options$col)) col = unlist(strsplit(options$col, split=","))

log = ""
if(!is.null(options$log) && options$log) log = "x"

legend_pos="topright"
if(!is.null(options$legend_pos)) legend_pos = options$legend_pos

names = c('Sample1','Sample2')

if(!is.null(options$names)) names = unlist(strsplit(options$names, split=","))
plot_barplot <- function(){
    par(las=2)
    par(mar=margin)
    barplot(t(data[, data_columns]), horiz = T, xlab = xlab, beside=TRUE,
        names.arg = data[, names_column], col = col, cex.names=0.7, 
        cex.axis = 0.8, log = log)
    legend(legend_pos, legend = names, fill = col, cex = 0.7)
}

if(!is.null(options$output_pdf_file)){
    pdf(options$output_pdf_file)
    plot_barplot()
    dev.off()
}

if(!is.null(options$output_svg_file)){
    svg(options$output_svg_file)
    plot_barplot()
    dev.off()
}