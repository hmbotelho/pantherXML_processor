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
        # data0 <- xmlParse("C:/Users/Hugo/Desktop/analysis.xml", encoding = "UTF-8")
        
        # Get alll <group> nodes
        nodesListG <- getNodeSet(data0, "//*/group")
    
        withProgress(message = 'Processing xml', value = 0, {
            df_out1 <- lapply(1:length(nodesListG), function(g){
                
                incProgress(1/length(nodesListG), detail = paste(round(g/length(nodesListG)*100,2), "% complete."))
                
                # Get all <result> nodes
                nodesListR <- xmlChildren(nodesListG[[g]])
                df_out2    <- lapply(1:length(nodesListR), function(r){
                    
                    
                    mapped_id <- if(is.null(nodesListR[[r]][["input_list"]][["mapped_id_list"]])){
                        ""
                    }else{
                        paste(xpathSApply(nodesListR[[r]][["input_list"]][["mapped_id_list"]], "mapped_id", xmlValue), collapse = ", ")
                    }
                    
                    data.frame(ontology  = xmlValue(getNodeSet(data0, "//overrepresentation/annotation_type")),
                               group     = as.integer(g),
                               
                               termID    = xmlValue(nodesListR[[r]][["term"]][["id"]]),
                               termLevel = as.integer(xmlValue(nodesListR[[r]][["term"]][["level"]])),
                               termLabel = xmlValue(nodesListR[[r]][["term"]][["label"]]),
                               
                               n_ref     = as.integer(xmlValue(nodesListR[[r]][["number_in_reference"]])),
                               
                               n_list    = as.integer(xmlValue(nodesListR[[r]][["input_list"]][["number_in_list"]])), 
                               expected = as.numeric(xmlValue(nodesListR[[r]][["input_list"]][["expected"]])), 
                               plus_minus = xmlValue(nodesListR[[r]][["input_list"]][["plus_minus"]]), 
                               pValue = as.numeric(xmlValue(nodesListR[[r]][["input_list"]][["pValue"]])), 
                               fold_enrichment = as.numeric(xmlValue(nodesListR[[r]][["input_list"]][["fold_enrichment"]])), 
                               mapped_id = mapped_id, 
                               
                               stringsAsFactors=FALSE)
                })
                df_out2    <- do.call(rbind, df_out2)
                df_out2
                
            })
            df_out1 <- do.call(rbind, df_out1)
        })
            
        
        myWorkbook    <- openxlsx::createWorkbook()
        sheet_sumarea <- openxlsx::addWorksheet(myWorkbook, "xmlexport")
        openxlsx::writeData(myWorkbook, sheet = sheet_sumarea, rowNames = FALSE, colNames = FALSE, x = df_out1[1,1], startCol = 1)
        openxlsx::writeData(myWorkbook, sheet = sheet_sumarea, rowNames = FALSE, colNames = TRUE, x = df_out1[,2:12], startRow = 3)
        myWorkbook <<- myWorkbook
        
        html("info", "Finished uploading. You may now export the file")
        df_out1[,2:12]
    })
    
    
    
    output$dl <- downloadHandler(
        filename = function() {"output.xlsx"},
        content = function(file) {openxlsx::saveWorkbook(myWorkbook, file, overwrite = F)}
    )
    
})