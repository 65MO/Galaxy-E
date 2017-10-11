library('getopt')

option_specification = matrix(c(
  'input_file', 'a', 2, 'character',
  'output_pdf_file', 'b', 2, 'character',
  'output_png_file', 'c', 2, 'character',
  'output_svg_file', 'd', 2, 'character',
  'x_column_id', 'e', 2, 'integer',
  'y_column_id', 'f', 2, 'integer',
  'xlog', 'g', 2, 'logical',
  'ylog', 'h', 2, 'logical',
  'xlab', 'i', 2, 'character',
  'ylab', 'j', 2, 'character',
  'col', 'k', 2, 'character',
  'pch', 'l', 2, 'integer',
  'lim', 'm', 2, 'logical',
  'abline', 'n', 2, 'logical',
  'bottom_margin', 'o', 2, 'integer',
  'left_margin', 'p', 2, 'integer',
  'top_margin', 'q', 2, 'integer',
  'right_margin', 'r', 2, 'integer',
  'header','s',2,'logical'
), byrow=TRUE, ncol=4);

options = getopt(option_specification);

header = TRUE
if(!is.null(options$header)) header = options$header

data = read.table(options$input_file, sep = '\t', h = header)

x_column_id = 2
if(!is.null(options$x_column_id)) x_column_id = options$x_column_id
x_axis = data[,x_column_id]

y_column_id = 3
if(!is.null(options$y_column_id)) y_column_id = options$y_column_id
y_axis = data[,y_column_id]

xlim = c(min(x_axis),max(x_axis))
ylim = c(min(y_axis),max(y_axis))
if(!is.null(options$lim) && options$lim){
  xlim = c(min(xlim,ylim), max(xlim,ylim))
  ylim = xlim
}


xlab = ""
if(!is.null(options$xlab)) xlab = options$xlab
ylab = ""
if(!is.null(options$ylab)) ylab = options$ylab

col = 'grey25'
if(!is.null(options$col)) col = options$col

pch = 21
if(!is.null(options$pch)) pch = options$pch

log = ""
if(!is.null(options$xlog) && options$xlog) log = paste(log,"x",sep = '')
if(!is.null(options$ylog) && options$ylog) log = paste(log,"y",sep = '')

margin = c(5,5,1,1)
if(!is.null(options$bottom_margin)) margin[1] = options$bottom_margin
if(!is.null(options$left_margin)) margin[2] = options$left_margin
if(!is.null(options$top_margin)) margin[3] = options$top_margin
if(!is.null(options$right_margin)) margin[4] = options$right_margin

plot_generic_x_y_plot <- function(){
    par(mar=margin)
    plot(x_axis, y_axis, xlab = xlab, ylab = ylab, 
      col = col, log = log, xlim = xlim, ylim = ylim, pch = pch)
    if(!is.null(options$abline) && options$abline) abline(a = 0, b = 1, col = 'grey50')
}

if(!is.null(options$output_pdf_file)){
    pdf(options$output_pdf_file)
    plot_generic_x_y_plot()
    dev.off()
}

if(!is.null(options$output_svg_file)){
    svg(options$output_svg_file)
    plot_generic_x_y_plot()
    dev.off()
}