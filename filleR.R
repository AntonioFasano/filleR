##################################################################################
# makePdf()  #Where necessary customise the vars, and run makePdf()

#CURR.DIR='.'                               #File directory
PDFBOX="pdfbox-app-1.8.7.jar"    #pdfbox-app-x.y.z.jar version/path.
MAGNI=0.7                                  #Text magnification factor
FONT=1                                     #Font: 1 helvetica regular, 2 Helv. bold, ... 6 Times  
####################################################################################
PAGE.COUNT=0                               #Total pages counter, do not modify




## Make PDFBOX java cmd template
x=rev(grep("source", sys.calls()))[1] # Get last source call
x=sys.call(x)[[2]]                    # Extract path
script.dir=dirname(normalizePath(x))
PDFBOX= paste0(script.dir, "/", PDFBOX)
if(!file.exists(PDFBOX)) stop("Can't find", PDFBOX)
PDFBOX= dQuote(PDFBOX)
PDFBOX= paste0("java -jar ", PDFBOX)


## makePdf("form.tpl.pdf", "form.csv", "form-filled.pdf")
makePdf=function(
    form.tpl,              # Input form to be filled (single page)
    pdfdata.csv,           # CSV data source 
    filled.form,           # The output filled form
    cover=NULL,            # Cover PDF, if any
    width=8.3, height=11.7 # Input form size in inches
    ){


    PAGE.COUNT<<-0

    ## Temp files
    bpath=sub("(.+)\\..*", "\\1", filled.form)  
    temp1=paste0(bpath, '.tmp1.pdf')            # Text PDF to be overlayed on the form  
    temp2=paste0(bpath, '.tmp2.pdf')            # Multipage version of the form template         
    temp.nocov=paste0(bpath, '.tmp.nocov.pdf')  # No cover version of the output         

  
    pdf(temp1, width, height)     # Write next plot to the overlay PDF
    par(mar=c(0, 0, 0, 0))        # Set numbers of lateral blank lines to zero
    par(xaxs='i', yaxs='i')       # Does not extend axes by 4 percent for pretty labels
    new.page(width, height)       # Create a new page 
   
    d=read.csv(pdfdata.csv, as.is=TRUE)    # Read and print fill data one row per time
    for (i in 1:nrow(d)) {
        x=d[i,1]; y=d[i,2]; tx=d[i,3]; text.width=d[i,4]
        
        if(is.na(y)) new.page(width, height)              # New page on -1 rows
        if(!is.na(text.width)) tx=justify(tx, text.width) # Justify left 
        ltext(x, y, tx)	
    }
  
    dev.off()                                             # Save overlay PDF
   

    ## Replicate PAGE.COUNT-times the single page form template
    temp=form.tpl
    if(PAGE.COUNT>1){
        cmd=paste(rep(dQuote(form.tpl), PAGE.COUNT), collapse=' ')
        cmd=paste(PDFBOX, "PDFMerger",  cmd, dQuote(temp2))
        try(system(cmd, intern = TRUE))
        temp=temp2
    }
  

    ## Overlay temp1 over temp2
    (cmd = paste(PDFBOX, "Overlay", dQuote(temp1), dQuote(temp), dQuote(temp.nocov)))
    try(system(cmd, intern = TRUE))

    ## Add cover if any
    if(is.null(cover)){
        file.copy(temp.nocov, filled.form)
    } else {
        (cmd=paste(PDFBOX, "PDFMerger", dQuote(cover), dQuote(temp.nocov), dQuote(filled.form)))
        try(system(cmd, intern = TRUE))
    } 
    
    ## Kindly show the results
    cmd=paste(PDFBOX,  "PDFReader", dQuote(filled.form))
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

