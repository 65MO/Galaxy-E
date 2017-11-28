library('getopt')

option_specification = matrix(c(
  'input_file', 'a', 2, 'character',
  'output_file', 'b', 2, 'character',
  'column1_id', 'c', 2, 'integer',
  'column2_id', 'd', 2, 'integer',
  'alternative','e',2,'character',
  'paired','f',2,'logical',
  'exact','g',2,'logical',
  'correct','h',2, 'logical',
  'mu','i',2,'integer',
  'header','y',2,'logical'
), byrow=TRUE, ncol=4);

options = getopt(option_specification);

header = TRUE
if(!is.null(options$header)) header = options$header

data = read.table(options$input_file, sep = '\t', h = header)

column1_id = 1
if(!is.null(options$column1_id)) column1_id = options$column1_id
x = data[,column1_id]
y = NULL
if(!is.null(options$column2_id)) y = data[,options$column2_id]

alternative = 'two.sided'
if(!is.null(options$alternative)) alternative = options$alternative

mu = 0
if(!is.null(options$mu)) mu = options$mu

paired = FALSE
if(!is.null(options$paired)) paired = options$paired

exact = NULL
if(!is.null(options$exact)) exact = options$exact

correct = TRUE
if(!is.null(options$correct)) correct = options$correct

test = wilcox.test(x = x, y = y, alternative = alternative, mu = mu, 
    paired = paired, exact = exact, correct = correct)

m = matrix(ncol = 2, nrow = 6)
m[1,] = c('statistic',test$statistic)
m[2,] = c('parameter',test$parameter)
m[3,] = c('p.value',test$p.value)
m[4,] = c('null.value',test$null.value)
m[5,] = c('alternative',test$alternative)
m[6,] = c('method',test$method)
write.table(m, file = options$output_file, sep = "\t", quote = FALSE, 
    row.names = FALSE, col.names = FALSE)
