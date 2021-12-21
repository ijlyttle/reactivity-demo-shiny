library("shiny")

# ------------------- 
# global functions
# ------------------- 
#
# created outside of reactive environment, making it easier:
#   - to test
#   - to migrate to a package

source("./aggregate-local.R")

# -------------
ui <- fluidPage(
  titlePanel("Aggregator"),
  fluidRow(
    column(
      width = 4, 
      wellPanel(
        h3("Input data"),
        fileInput(
          inputId = "upload_inp",
          label = "Upload CSV file",
          placeholder = "No file selected: using Palmer Penguins"
        ),
        downloadButton(
          outputId = "download_inp",
          label = "Download CSV file"
        )
      ),
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
      ),
      wellPanel(
        h3("Aggregated data"),
        downloadButton(
          outputId = "download_agg",
          label = "Download CSV file"
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
  # inputs
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
  # reactive values
  # -------------------  
  inp <- 
    reactive({
     
      # use palmer penguins as default
      if (is.null(input$upload_inp)) {
        return(palmerpenguins::penguins)
      }
     
      readr::read_csv(input$upload_inp$datapath, show_col_types = FALSE)
    }) |>
    bindEvent(input$upload_inp, ignoreNULL = FALSE, ignoreInit = FALSE)

  agg <- 
    reactive({
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
  
  output$download_inp <- downloadHandler(
    filename = \() glue::glue("data-input-{Sys.Date()}.csv"),
    content = \(file) readr::write_csv(inp(), file)
  )
  
  output$table_agg <- DT::renderDT(agg())
  
  output$download_agg <- downloadHandler(
    filename = \() glue::glue("data-aggregated-{Sys.Date()}.csv"),
    content = \(file) readr::write_csv(agg(), file)
  )
 
}

# ------------------- 
shinyApp(ui = ui, server = server)
