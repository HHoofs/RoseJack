library(shiny)
library(ggplot2)
library(rpart)
library(stringr)
library(dplyr)
library(titanic)


# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  ## Read in data
  ## TODO: Should  be in server
  df_sel <- titanic_train
  
  colnames <- names(df_sel)
  
  cont_vars <- c("Age", "SibSp", "Parch", "Fare")
  first_var <- cont_vars[1]
  categorical_vars <- c("Pclass", "Sex", "Embarked")
  out_var <- "Survived"
  df_sel$Survived <- as.character(df_sel$Survived) 
  df_sel$Survived <- car::Recode(df_sel$Survived, "'0'='Jack'; '1'='Rose'")
  
  df_sel <- df_sel[,c(cont_vars, categorical_vars, out_var)]
  df_sel <- df_sel[complete.cases(df_sel),]
  ## ---

  output$select_tree <- renderUI({
    conditionalPanel("input.tree_options == true", sep="",
                     sliderInput("tree_min_split", "Minimal split size", min=1, max(nrow(df_sel)), value = 20, step = 1, round = TRUE),
                     sliderInput("tree_min_bucket", "Minimal bucket size", min=1, max(nrow(df_sel)), value = 5, step = 1, round = TRUE),
                     sliderInput("tree_cp", "Complexity", min=0, max=1, value = .01, step = .001, round = FALSE))
  })
  
  output$choose_columns <- renderUI({
    # Create dynamic UI for the continious variables
    lapply(cont_vars,function(sel_var){
      # make a nice box around each variable
      wellPanel(strong(sel_var),
                checkboxInput(paste(sel_var, "_options_include",sep=""), "Include", TRUE),
                checkboxInput(paste(sel_var, "_options_filter",sep=""), "Filter", FALSE),
                # if function is filter, than show slider in which range for filter can be selected
                conditionalPanel(condition = paste("input.", sel_var, "_options_filter == true", sep=""),
                                 # Slider doesn't use dynamic df but actual range for each var
                                 sliderInput(paste(sel_var, "_range", sep=""), "Range", 
                                             min = min(df_sel[,sel_var]), max = max(df_sel[,sel_var]), 
                                             value = c(min(df_sel[,sel_var]), max(df_sel[,sel_var])))
                )
      )
    })
  })
  
  output$choose_dich <- renderUI({
    # Create dynamic UI for the continious variables
    lapply(categorical_vars,function(sel_var){
      # make a nice box around each variable
      wellPanel(strong(sel_var),
                checkboxInput(paste(sel_var, "_options_include",sep=""), "Include", TRUE),
                checkboxInput(paste(sel_var, "_options_filter",sep=""), "Filter", FALSE),
                # if function is filter, than show boxes for values which should be in- or excluded
                conditionalPanel(condition = paste("input.", sel_var, "_options_filter == true", sep=""),
                                 # values are based on all values in de original df
                                 checkboxGroupInput(paste(sel_var, "_values", sep=""), "Values", 
                                                    choices = c(sort(unique(df_sel[,sel_var]))), 
                                                    selected = c(unique(df_sel[,sel_var])))
                                 
                                 
                )
      )
    })
  })
  
  form <- reactive({
    # Create start of formula with outcome variable
    form = paste(out_var, " ~ ", sep="")
    
    # Check if UI is loaded
    req(input[[paste(first_var, "_range", sep="")]] > 0)
    
    # Loopt over all continious variables to check if they should be included
    for(colname in cont_vars){
      if(input[[paste(colname, "options_include", sep="_")]]){
        # Ad var to formula if its included
        form = paste(form, colname, sep=" + ")
      }
    }
    
    # Loop over all categorical variables to check if they should be included
    for(colname in categorical_vars){
      if(input[[paste(colname,"options_include", sep="_")]]){
        # Add factor to make sure it is used as categorical factor in ML
        form = paste(form, paste("factor(", paste(colname, ")", sep=""), sep=""), sep=" + ")
      }
    }
    
    # Clean up some residues of the start and end of formula
    form = str_replace(form, '~[ ]*[+]', "~")
    form = str_replace(form, '[+] $', "")
    form = str_replace(form, '[+]$', "")
    
    # return formula as a dynamic element
    return(form)
  })
  
  df <- reactive({
    # load df
    df_fiter <- df_sel
    
    # Check if UI is loaded
    req(input[[paste(first_var, "_range", sep="")]] > 0)
    
    for(colname in cont_vars){
      # if sel var is used as filter, use range
      if(input[[paste(colname,"options_filter", sep="_")]]){
        # range as selected by user
        range = input[[paste(colname,"range", sep="_")]]
        # use range to apply filter
        df_fiter <- df_fiter[df_fiter[ ,colname] >= range[1] & df_fiter[ ,colname] <= range[2], ]
      }
    }
    
    for(colname in categorical_vars){
      # if sel var is used as filter, use values
      if(input[[paste(colname,"options_filter", sep="_")]]){
        for(value in c(unique(df_sel[, colname]))){
          # if value is not selected deselect rows with this value
          if(!any(value == input[[paste(colname, "_values", sep="")]])) df_fiter <- df_fiter[!(df_fiter[, colname] == value), ] 
        }
      }
    }
    
    return(df_fiter)
  })
  
  output$form <- renderText({
    # render formula as text
    form()
  })
  
  output$df <- renderDataTable({
    # render data frame as is
    df()
  })
  
  rpart_fit <- reactive({
    # set control parameters as specified by user (interface)
    set_control <- rpart.control(minsplit = input$tree_min_split, minbucket = input$tree_min_bucket,
                                 cp=input$tree_cp)
    
    # fit tree (rpart) object with formula and df as is 
    fit = rpart(as.formula(form()), data = df(), control = set_control)
    
    # return fit
    return(fit)
  })
  
  output$distPlot <- renderPlot({
    # render plot of tree
    # fancyRpartPlot(rpart_fit())
    rpart.plot::rpart.plot(rpart_fit(), type = 4)
  })
  
  output$plotDown <- downloadHandler( filename = "JackAndRose.pdf",
                                      content = function(file){
                                        pdf(file,paper = "a4r") # open the pdf device
                                        rpart.plot::rpart.plot(rpart_fit(), type = 4)
                                        dev.off()  # turn the device off
                                      })
  
  output$tree_out <- renderPrint({
    # render control parameters
    rpart_fit()['control']
  })
  
  output$sumplot <- renderPlot({
    # make simple ggplot which shows distribution of outcome in data frame as is
    df() %>% 
      group_by_(out_var) %>% 
      summarise(Aantal=n()) %>% 
      ggplot(aes_string(x=out_var, y="Aantal", fill=out_var)) +
      geom_bar(stat="identity", color="black") + 
      theme_gray(15)
  })
  
})
