##################################################################################
# makePdf()  #Where necessary customise the vars, and run makePdf()

#CURR.DIR='.'                               #File directory
PDFBOX=NULL   # Unless user sets path/to/pdfbox-app-x.y.z.jar,
	      # search pdfbox-app with search.pdfbox.app()
JAVABIN=NULL  # Unless user sets path/to/java (.exe),
	      # search Java executable with search.java.exe()
MAGNI=0.7     # Text magnification factor
FONT=1        # Font: 1 helvetica regular, 2 Helv. bold, ... 6 Times  
####################################################################################

## for git: makePdf: Test inputs, notemp opt


## Internal Globals -  Do not modify
FILLERDIR=NULL   # Script dir
PAGE.COUNT=0     # Total pages counter



## filleR invoked with standard source("path/to/filleR.R") 
FILLERDIR=sys.frame(1)$ofile
    
## filleR invoked with Emacs ESS "ess-load-file" or "C-c C-l"
if(is.null(FILLERDIR)) FILLERDIR=local({
    x=grep(".ess.source", sys.calls())[1]
    sys.call(x)[[2]]
})
    
## Get script directory  
if(!is.null(FILLERDIR)){
    FILLERDIR=normalizePath(dirname(FILLERDIR)) 
} else {
    stop("Unable to find script source. Please invoke with:\n  source(\"path/to/filleR.R\")")
}

nzstring=function(s){ # Safe version of nzchar
    ## TRUE if s is a non-NA and  non-zero char

    if(is.character(s) &&
       !is.na(s)       &&
       nzchar(s))
        TRUE else FALSE               
}

search.pdfbox.app=function(){
    ## If PDFBOX is NULL, search for pdfbox-app-x.y.z.jar else test it is a valid path
    ## Return absolute pdfbox-app path or stop with error 
    ## pdfbox-app-x.y.z.jar is sought in a) current dir, b) script dir, 
    ## c) in PATH env variable as pdfbox-app.jar (no version)
     
    if(!is.null(PDFBOX)) {        
        if(!file.exists(PDFBOX)) stop("\nCan't find:\n  ", PDFBOX)
    } else {
  
        p="^pdfbox-app.*\\.jar"
        PDFBOX=rev(list.files(patt=p))[1]                           # search in current dir 
        if(!nzstring(PDFBOX))                                       # search in script dir
            PDFBOX=rev(list.files(path=FILLERDIR, patt=p, full=TRUE))[1]
        
        if(!nzstring(PDFBOX)) PDFBOX=Sys.which("pdfbox-app.jar")[1] # search in PATH
  
    }
     
    if(!nzstring(PDFBOX)) stop("\nCan't find pdfbox-app-x.y.z.jar") 
    return(normalizePath(PDFBOX))
     
}


search.java.exe=function(){
    ## If JAVABIN is NULL, search for Java executable else test it is a valid path
    ## Return absolute Java executable path or stop with error 
    ## Java executable is sought a) through JAVA_HOME env variable, b) in PATH env variable

    javahome=Sys.getenv("JAVA_HOME")
   
    if(!is.null(JAVABIN)) {         # Try JAVABIN global
        if(!file.exists(JAVABIN)) stop("\nCan't find:\n  ", JAVABIN)
        
    } else if(nzstring(javahome)) {   # Try JAVA_HOME
        if(!dir.exists(javahome))
            stop("JAVA_HOME system variable is set to the non-existent path:\n ", javahome)
    
        javahome.bin=file.path(javahome, "bin")
        if(!dir.exists(javahome.bin))
            stop("Unable to find:\n  ", javahome.bin, "\nCheck JAVA_HOME system variable.")

        JAVABIN=list.files(javahome.bin, "^java$|^java.exe$", full=TRUE)[1]
        if(!nzstring(JAVABIN))
            stop("\nCan't find:\n ", normalizePath(file.path(javahome.bin, "java"), mustWork=FALSE))
        
    } else { # Try PATH

        JAVABIN=Sys.which("java")[1] 
    }
    
    if(!nzstring(JAVABIN)) stop("\nCan't find Java executable") 
    return(normalizePath(JAVABIN))
     
}



## makePdf("form.tpl.pdf", "form.csv", "form-filled.pdf")
makePdf=function(
    form.tpl,               # Input form to be filled (single page)
    pdfdata.csv,            # CSV data source 
    filled.form,            # The output filled form
    cover=NULL,             # Cover PDF, if any
    width=8.3, height=11.7, # Input form size in inches
    notemp=TRUE             # Remove temp files
    ){

    PAGE.COUNT<<-0

    ## Get pdfbox
    JAVABIN=search.java.exe()
    PDFBOX=search.pdfbox.app()        
    PDFBOX= paste0(dQuote(JAVABIN), " -jar ", dQuote(PDFBOX))

    ## Test inputs
    if(!file.exists(form.tpl)) stop("Unable to find:\n  ", form.tpl)
    if(!file.exists(pdfdata.csv)) stop("Unable to find:\n  ", pdfdata.csv)
    if(!is.null(cover) && !file.exists(cover)) stop("Unable to find:\n  ", cover)
    

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


    ## Remove temp files
    if(notemp) unlink(c(temp.nocov, temp1, temp2))  
    
    ## Kindly show the results
    cmd=paste(PDFBOX,  "PDFReader", dQuote(filled.form))
    ##try(system(cmd))

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

