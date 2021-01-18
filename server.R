options(shiny.maxRequestSize=300*1024^2)

library(XML)
library(shiny)
library(openxlsx)
df<-data.frame()

# Define server logic required to draw a histogram
shinyServer(function(input, output) {


    output$tbl <- renderTable({

        # Load file
        data0 <- xmlParse(input$xmlfile$datapath, encoding = "UTF-8")
        # data0 <- xmlParse("C:/Users/Hugo/Downloads/analysis (1).xml", encoding = "UTF-8")
        
        # Get alll <group> nodes
        nodesListG <- getNodeSet(data0, "//*/group")

        df_out <- lapply(1:length(nodesListG), function(g){
        
            mapped_id <- if(is.null(nodesListG[[g]][["result"]][["input_list"]][["mapped_id_list"]])){
                ""
            }else{
                paste(xpathSApply(nodesListG[[g]][["result"]][["input_list"]][["mapped_id_list"]], "mapped_id", xmlValue), collapse = ", ")
            }
            
            data.frame(ontology  = xmlValue(getNodeSet(data0, "//overrepresentation/annotation_type")),
                       group     = as.integer(g),
                       
                       termID    = xmlValue(nodesListG[[g]][["result"]][["term"]][["id"]]),
                       termLevel = as.integer(xmlValue(nodesListG[[g]][["result"]][["term"]][["level"]])),
                       termLabel = xmlValue(nodesListG[[g]][["result"]][["term"]][["label"]]),
                       
                       n_ref     = as.integer(xmlValue(nodesListG[[g]][["result"]][["number_in_reference"]])),
                       
                       n_list    = as.integer(xmlValue(nodesListG[[g]][["result"]][["input_list"]][["number_in_list"]])), 
                       expected = as.numeric(xmlValue(nodesListG[[g]][["result"]][["input_list"]][["expected"]])), 
                       plus_minus = xmlValue(nodesListG[[g]][["result"]][["input_list"]][["plus_minus"]]), 
                       pValue = as.numeric(xmlValue(nodesListG[[g]][["result"]][["input_list"]][["pValue"]])), 
                       fold_enrichment = as.numeric(xmlValue(nodesListG[[g]][["result"]][["input_list"]][["fold_enrichment"]])), 
                       mapped_id = mapped_id, 
                       
                       stringsAsFactors=FALSE)
            
        })
        df_out <- do.call(rbind, df_out)
        df <<- df_out
        output$saveTxt <- renderText("Finished uploading")
        df_out[,2:12]
    })
    
    observeEvent(input$exportbtn, {
        
        outpath <- file.choose()
        if(!endsWith(outpath, ".xlsx")){
            outpath <- paste0(outpath, ".xlsx")
        }
        
        myWorkbook              <- openxlsx::createWorkbook()
        sheet_sumarea           <- openxlsx::addWorksheet(myWorkbook, "xmlexport")
        
        openxlsx::writeData(myWorkbook, sheet = sheet_sumarea,           rowNames = FALSE, colNames = FALSE, x = df[1,1], startCol = 1)
        openxlsx::writeData(myWorkbook, sheet = sheet_sumarea,           rowNames = FALSE, colNames = TRUE, x = df[,2:12], startRow = 3)
        
        openxlsx::saveWorkbook(myWorkbook, outpath, overwrite = F)
        
        output$saveTxt <- renderText(paste0("saved file ", outpath))
        
    })
    
})