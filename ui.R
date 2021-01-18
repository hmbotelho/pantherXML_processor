library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(

    # Application title
    titlePanel("Convert Panther XML to XLSX"),

    # Sidebar with file  selection
    sidebarLayout(
        sidebarPanel(
            fileInput("xmlfile", label = h3("File input"), accept = ".xml"),
            # actionButton("exportbtn", label = "Export", class = "btn-success"),
            downloadButton("exportbtn", "Download"),
            verbatimTextOutput("saveTxt")
        ),

        # Show a plot of the generated distribution
        mainPanel(
            tableOutput("tbl")
        )
    )
))
