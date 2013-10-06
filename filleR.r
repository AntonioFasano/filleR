##################################################################################
# main()  #Where necessary customise the vars, and run main()

CURR.DIR='.'                               #Main file directory
OVER='overlay.pdf'; WIDTH=8.3; HEIGHT=11.7 #Overlay PDF path and size (inches)
DATA='form.csv'; TEMP='temp.pdf'           #CSV data source and temp output
FORM='form.pdf'; FILLED='form-filled.pdf'  #Un/filled form
PDFBOX="java -jar pdfbox-app-1.8.2.jar"    #pdfbox-app-x.y.z.jar version/path.
MAGNI=0.7                                  #Magnification factor
FONT=1                                     #Font: 1 helvetica regular, 2 Helv. bold, ... 6 Times  
#####################################################################################
PAGE.COUNT=0                               #Total pages counter, do not modify




main=function(){

  setwd(CURR.DIR)
  PAGE.COUNT<<-0

  pdf(OVER, WIDTH, HEIGHT)        #Write next plot to the overlay PDF
  par(mar=c(0, 0, 0, 0))          #Set numbers of lateral blank lines to zero
  par(xaxs='i', yaxs='i')         #Does not extend axes by 4 percent for pretty labels
  new.page(WIDTH, HEIGHT)         #Create a new page 
   
  d=read.csv(DATA, as.is=TRUE)    #Read and print fill data one row per time
  for (i in 1:nrow(d)) {
    x=d[i,1]; y=d[i,2]; tx=d[i,3]; text.width=d[i,4]
   
    if(is.na(y)) new.page(WIDTH, HEIGHT)              #New page on -1 rows
    if(!is.na(text.width)) tx=justify(tx, text.width) #Justify left 
    ltext(x, y, tx)	
  }
   
  dev.off()                                           #Save overlay PDF


     
  ###Replicate PAGE.COUNT-times the single page FORM
  temp=FORM
  if(PAGE.COUNT>1){
    cmd=paste(rep(FORM, PAGE.COUNT), collapse=' ')
    cmd=paste(PDFBOX,  "PDFMerger",  cmd, TEMP)
    try(system(cmd, intern = TRUE))
    temp=TEMP
  }
  

  ###Overlay OVER over TEMP
  (cmd=paste(PDFBOX, "Overlay", OVER, temp, FILLED))
  try(system(cmd, intern = TRUE))
   
  ###Kindly show the results
  cmd=paste(PDFBOX,  "PDFReader", FILLED)
  #try(system(cmd))

}

###Print left aligned
ltext=function(x,y, s) text(x,y, s, pos=4, offset=0, cex=MAGNI, font=FONT)

###Left multiline justification at width
justify=function(string, width){

  str.len=nchar(string)
  sp=gregexpr(' ', string)[[1]]                            #Get text spaces
  l=seq(from=width, by=width, length=floor(str.len/width)) #Get limits for every row
  bsp=sapply(l, function(x) max(sp[sp<=x]))                #Breaking spaces
  rows=substring (string, c(1, bsp), c(bsp, str.len))      #Extract lines
  rows=sub("^ +", "", rows)                                #Remove leading spaces 
  paste(rows, '\n', collapse='')                           #Merge rows, with newlines
}

###Create a new overlay page and update the page counter 
new.page=function(page.width, page.height){
    plot.new()               #Create a blank plot, as we just want to write our text
    plot.window(xlim=c(0,page.width), ylim=c(0,page.height)) #Fit plot to paper size
    PAGE.COUNT<<-PAGE.COUNT+1
} 

