options(shiny.maxRequestSize=300*1024^2)

library(XML)
library(shiny)
library(shinyjs)
library(openxlsx)
myWorkbook <- openxlsx::createWorkbook()

# Define server logic required to draw a histogram
shinyServer(function(input, output) {


    output$tbl <- renderTable({

        # Load file
        html("info", "Processing xml.")
        data0 <- xmlParse(input$xmlfile$datapath, encoding = "UTF-8")
        # data0 <- xmlParse("C:/Users/Hugo/Downloads/analysis (1).xml", encoding = "UTF-8")
        
        # Get alll <group> nodes
        nodesListG <- getNodeSet(data0, "//*/group")
    
        withProgress(message = 'Processing xml', value = 0, {
            df_out <- lapply(1:length(nodesListG), function(g){
                
                incProgress(1/length(nodesListG), detail = paste(round(g/length(nodesListG)*100,2), "% complete."))
                
                
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
        })
            
        df_out <- do.call(rbind, df_out)
        
        myWorkbook    <- openxlsx::createWorkbook()
        sheet_sumarea <- openxlsx::addWorksheet(myWorkbook, "xmlexport")
        openxlsx::writeData(myWorkbook, sheet = sheet_sumarea, rowNames = FALSE, colNames = FALSE, x = df_out[1,1], startCol = 1)
        openxlsx::writeData(myWorkbook, sheet = sheet_sumarea, rowNames = FALSE, colNames = TRUE, x = df_out[,2:12], startRow = 3)
        myWorkbook <<- myWorkbook
        
        html("info", "Finished uploading. You may now export the file")
        df_out[,2:12]
    })
    
    
    
    output$dl <- downloadHandler(
        filename = function() {"output.xlsx"},
        content = function(file) {openxlsx::saveWorkbook(myWorkbook, file, overwrite = F)}
    )
    
})