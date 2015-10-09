library(ggplot2)
library(ggthemes)
library(grid)
library(gridExtra)
library(scales)

args <- commandArgs(trailingOnly = TRUE)
pathfile <- args[1]
oldpathfile <- args[2]

# two side-by-side plots with a shared legend
twoPlot <- function(p1, p2, title, cols=2) {
  g_legend<-function(p){
    tmp <- ggplotGrob(p)
    leg <- which(sapply(tmp$grobs, function(x) x$name) == "guide-box")
    legend <- tmp$grobs[[leg]]
    return(legend)
  }
  legend <- g_legend(p1)
  lheight <- sum(legend$height)
  
  grid.arrange(arrangeGrob(p1 + theme(legend.position="none"),
                           p2 + theme(legend.position="none"),
                           main = title, nrow=1), legend, 
                heights=unit.c(unit(1, "npc") - lheight, lheight), nrow=2)
}

# set a new theme
plot_theme <- theme(panel.grid.major = element_blank(),
                    panel.background = element_blank(),
                    axis.line = element_line(size=.3, color = "black"),
                    axis.title.x = element_text(color="forestgreen", vjust=-0.35),
                    axis.title.y = element_text(color="cadetblue" , vjust=0.8),
                    plot.title = element_text(size=10, face="bold", vjust=1),
                    legend.background = element_rect(fill="transparent"),
                    legend.title=element_blank(),
                    legend.key=element_rect(fill=NA),
                    legend.text = element_text(size=10),
                    legend.position = "bottom",
                    text = element_text(size=10))

# read the data
read_data <- function(file) {
  data <- read.table(file, comment.char="#", header=FALSE, fill=TRUE)
  names(data)[names(data)=="V1"]  <- "Name"
  names(data)[names(data)=="V2"]  <- "Input"
  names(data)[names(data)=="V3"]  <- "Variant"
  names(data)[names(data)=="V4"]  <- "Cores"
  names(data)[names(data)=="V5"]  <- "Min"
  names(data)[names(data)=="V6"]  <- "Median"
  names(data)[names(data)=="V7"]  <- "Max"
  return(data)
}

sanitizeData <- function(data, n) {
  # concatenate strings together
  j <- function(..., sep='') {paste(..., sep=sep, collapse=sep)}

  d <- subset(data, grepl(n, Name))
  levels(d$Variant)[levels(d$Variant)=="cilk"] <- "Cilk"
  levels(d$Variant)[levels(d$Variant)=="hpx"] <- "HPX-5 1.3"
  levels(d$Variant)[levels(d$Variant)=="omp"] <- "Open MP"
  levels(d$Variant)[levels(d$Variant)=="qthreads"] <- "Qthreads"
  levels(d$Variant)[levels(d$Variant)=="tbb"] <- "TBB"
  return(d)
}

oldsanitizeData <- function(data, n) {
  # concatenate strings together
  j <- function(..., sep='') {paste(..., sep=sep, collapse=sep)}

  d <- subset(data, grepl(n, Name))
  levels(d$Variant)[levels(d$Variant)=="cilk"] <- "Cilk"
  levels(d$Variant)[levels(d$Variant)=="hpx"] <- "HPX-5 1.0"
  levels(d$Variant)[levels(d$Variant)=="omp"] <- "Open MP"
  levels(d$Variant)[levels(d$Variant)=="qthreads"] <- "Qthreads"
  levels(d$Variant)[levels(d$Variant)=="tbb"] <- "TBB"
  return(d)
}

# do a single strong-scaling plot
doPlotSS <- function(data, title) {
  fp <- ggplot(data, aes(x=Cores,y=Median,group=Variant)) + guides(col=guide_legend(nrow=2,byrow=TRUE))
  fp <- fp + geom_errorbar(aes(x=Cores,ymin=Min, ymax=Max,color=Variant), width=0.1)
  fp <- fp + geom_line(aes(color=Variant),size=0.6) + geom_point(aes(shape=Variant,color=Variant),size=2)
#  fp <- fp + scale_x_continuous(trans=log2_trans(),breaks=trans_breaks("log2", function(x) 2^x))
  fp <- fp + ggtitle(title)
  fp <- fp + xlab("Cores") + ylab("Time taken (s)")
  fp <- fp + plot_theme + scale_colour_tableau()
  return(fp)
}

# a faceted strong-scaling plot
doPlotSSFacet <- function(data) {
  fp <- doPlotSS(data)
  fp <- fp + facet_wrap(~Input, scales="free")
  return(fp)
}

# a weak-scaling plot with increasing Input sizes
doPlotWS <- function(data) {
  fp <- ggplot(data, aes(x=Input,y=Median,group=Variant))
  fp <- fp + geom_errorbar(aes(x=Cores,ymin=Min, ymax=Max,color=Variant), width=0.2)
  fp <- fp + geom_line(aes(color=Variant),size=0.6) + geom_point(aes(shape=Variant,color=Variant),size=2)
  fp <- fp + scale_y_log10()
  fp <- fp + ylab("Time taken (s)")
  fp <- fp + plot_theme + scale_colour_tableau()
  return(fp)
}

# a faceted weak-scaling plot
doPlotWSFacet <- function(data) {
  fp <- doPlotWS(data)
  fp <- fp + facet_wrap(~Cores, scales="free")
  return(fp)
}

# Read the data first
data <- read_data(pathfile)
olddata <- read_data(oldpathfile)

# Plot fibonacci results
#fibdata <- sanitizeData(subset(data, (Input == 30) | (Input == 35) | (Input == 37)), "fib")
#fp1 <- doPlotSSFacet(fibdata)

fibdata <- sanitizeData(subset(data, (Input == 37) & (Cores <= 16) & (Variant != 'cilk')), "parfib")
oldfibdata <- oldsanitizeData(subset(olddata, (Input == 37) & (Cores <= 16) & (Variant == 'hpx')), "parfib")
fibdata <- rbind(oldfibdata, fibdata)
fp1 <- doPlotSS(fibdata, "fib(37)") + scale_y_log10()
ggsave(fp1, file="fib.pdf", width=4, height=3.75)


# Plot seqspawn results
#seqdata <- sanitizeData(subset(data, (Cores == 16)), "seqspawn")
#sp1 <- doPlotWS(seqdata) + xlab("Number of Tasks")

seqdata <- sanitizeData(subset(data, (Input == 10000000) & (Cores <= 16) & (Variant != 'cilk')), "seqspawn")
oldseqdata <- oldsanitizeData(subset(olddata, (Input == 10000000) & (Cores <= 16) & (Variant == 'hpx')), "seqspawn")
seqdata <- rbind(oldseqdata, seqdata)
sp2 <- doPlotSS(seqdata, "seqspawn(10000000)")
ggsave(sp2, file="seq.pdf", width=4, height=3.75)

#pdf(file="seq.pdf", width=8, height=3.5, onefile=FALSE)
#twoPlot(sp1, sp2, "Sequential Spawn", cols=2)
#dev.off()

# Plot parspawn results
#pardata <- sanitizeData(subset(data, (Cores == 16)), "parspawn")
#pp1 <- doPlotWS(pardata)+ xlab("Number of Tasks")

pardata <- sanitizeData(subset(data, (Input == 10000000) & (Cores <= 16) & (Variant != 'cilk')), "parspawn")
oldpardata <- oldsanitizeData(subset(olddata, (Input == 10000000) & (Cores <= 16) & (Variant == 'hpx')), "parspawn")
pardata <- rbind(oldpardata, pardata)
pp2 <- doPlotSS(pardata, "parspawn(10000000)") + scale_y_log10()
ggsave(pp2, file="par.pdf", width=4, height=3.75)

#pdf(file="par.pdf", width=8, height=3.5, onefile=FALSE)
#twoPlot(pp1, pp2, "Parallel Spawn", cols=2)
#dev.off()

