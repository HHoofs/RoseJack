library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  # theme="https://bootswatch.com/4/sketchy/bootstrap.css",
  titlePanel("Rose & Jack"),
  
  # Sidebar with a slider input for number of bins 
  sidebarLayout(
    sidebarPanel(
      h3("Tree parameters"),
      checkboxInput("tree_options", "Show parameters", value=FALSE),
      uiOutput("select_tree"),
      fluidRow(
        column(6,
               h3("Continous features"),
               uiOutput("choose_columns")),
        column(6,
               h3("Categorical features"),
               uiOutput("choose_dich")))
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(
        tabPanel("Tree",
                 plotOutput("distPlot"),
                 downloadButton(outputId = "plotDown",label = "Download the plot"),
                 verbatimTextOutput("form")
        ),
        tabPanel("Data",
                 dataTableOutput("df")
        ),
        tabPanel("Distribution",
                 plotOutput("sumplot")
        ))
    ))
))
