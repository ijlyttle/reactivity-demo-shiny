library("shiny")

# ------------------- 
# global functions
# ------------------- 
#
# created outside of reactive environment, making it easier:
#   - to test
#   - to migrate to a package
source("./R/aggregate-local.R")

# -------------
ui <- fluidPage(
  titlePanel("Aggregator"),
  fluidRow(
    column(
      width = 4,
      wellPanel(
        h3("Aggregation"),
        selectizeInput(
          inputId = "cols_group",
          label = "Grouping columns",
          choices = c(),
          multiple = TRUE
        ),        
        selectizeInput(
          inputId = "cols_agg",
          label = "Aggregation columns",
          choices = c(),
          multiple = TRUE
        ),
        selectizeInput(
          inputId = "func_agg",
          label = "Aggregation function",
          choices = agg_function_choices,
          multiple = FALSE
        ),
        actionButton(
          inputId = "button",
          label = "Submit"
        )
      )
    ),
    column(
      width = 8,
      h3("Input data"),
      DT::DTOutput(
        outputId = "table_inp"
      ),
      hr(),
      h3("Aggregated data"),
      DT::DTOutput(
        outputId = "table_agg"
      )      
    )
  )
)

# ------------------- 
server <- function(input, output, session) {
  
  # -------------------  
  # input observers
  # -------------------  
  observe({
    # this runs whenever the parsed input data changes
    updateSelectizeInput(
      session,
      inputId = "cols_group",
      choices = cols_category(inp())
    )
  }) 
  
  observe({  
    updateSelectizeInput(
      session,
      inputId = "cols_agg",
      choices = cols_number(inp())
    )
  })
  
  # -------------------  
  # reactive expressions
  # -------------------  
  inp <- 
    reactive({ 
      palmerpenguins::penguins
    }) 
  
  agg <- 
    reactive({
      
      req(input$func_agg %in% agg_function_choices)
      
      group_aggregate(
        inp(), 
        str_group = input$cols_group, 
        str_agg = input$cols_agg, 
        str_fn_agg = input$func_agg
      )
    }) |>
    bindEvent(input$button, ignoreNULL = TRUE, ignoreInit = TRUE)
  
  # -------------------   
  # outputs
  # -------------------   
  output$table_inp <- DT::renderDT(inp())
  
  output$table_agg <- DT::renderDT(agg())

}

# ------------------- 
shinyApp(ui = ui, server = server)
