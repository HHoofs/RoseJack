library(shiny)
library(titanic)
library(car)

## Read in data
## TODO: Should  be in server
df_sel <- titanic_train

colnames <- names(df_sel)

cont_vars <- c("Age", "SibSp", "Parch", "Fare")
first_var <- cont_vars[1]
categorical_vars <- c("Pclass", "Sex", "Embarked")
out_var <- "Survived"
df_sel$Survived <- as.character(df_sel$Survived)
df_sel$Survived <- Recode(df_sel$Survived, "'0'='Jack'; '1'='Rose'")

df_sel <- df_sel[,c(cont_vars, categorical_vars, out_var)]
df_sel <- df_sel[complete.cases(df_sel),]
## ---

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  # theme="https://bootswatch.com/4/sketchy/bootstrap.css",
  titlePanel("Treenamic"),
  
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
                 downloadButton(outputId = "plotDown", label = "Download the plot"),
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
