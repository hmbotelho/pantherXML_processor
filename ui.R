library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(

    useShinyjs(),
    
    # Application title
    titlePanel("Convert Panther XML to XLSX"),

    # Sidebar with file  selection
    sidebarLayout(
        sidebarPanel(
            fileInput("xmlfile", label = h3("File input"), accept = ".xml"),
            downloadButton("dl", "Download"),
            p(id="info", "Hello! Please upload xml file")
        ),

        # Show a plot of the generated distribution
        mainPanel(
            tableOutput("tbl")
        )
    )
))
