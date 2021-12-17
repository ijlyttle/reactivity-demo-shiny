library("shiny")

# ------------------- 
# global functions
# ------------------- 

agg_function_choices <- c("mean", "min", "max")

# Functions created outside of reactive environment, making it easier:
#   - to test
#   - to migrate to a package

# given a data frame, return the names of numeric columns
cols_number <- function(df) {
  df_select <- dplyr::select_if(df, ~is.numeric(.x) | is.integer(.x) ) 
  
  names(df_select)
}

# given a data frame, return the names of string and factor columns
cols_category <- function(df) {
  df_select <- dplyr::select_if(df, ~is.character(.x) | is.factor(.x) ) 
  
  names(df_select)
}

# make the aggregation
group_aggregate <- function(df, str_group, str_agg, str_fn_agg) {

  # safeguard the aggregation function
  stopifnot(
    str_fn_agg %in% agg_function_choices
  )
  
  # get the aggregation function
  func <- get(str_fn_agg)
  
  df |>
    dplyr::group_by(dplyr::across(dplyr::all_of(str_group))) |>
    dplyr::summarise(
      dplyr::across(dplyr::all_of(str_agg), func, na.rm = TRUE)
    )
}

# build an expression
aq_expr <- function(str_agg, str_fn_agg) {
  glue::glue('(d) => op.{str_fn_agg}(d["{str_agg}"])')
}

# build the query
aq_query <- function(str_group, str_agg, str_fn_agg) {
  
  names(str_agg) <- str_agg
  
  aq_expr_local <- \(x) aq_expr(x, str_fn_agg) 
  
  list(
    verbs = list(
      list(
        verb = "groupby",
        keys = I(str_group)        
      ),
      list(
        verb = "rollup",
        values = purrr::map(
          str_agg, 
          ~list(expr = aq_expr_local(.x), func = TRUE)
        ) 
      )
    )
  )
}

# given a list for a request body, return JSON string
aq_serialize <- function(x, ...) {
  jsonlite::toJSON(x, dataframe = "columns", auto_unbox = TRUE, ...)
}

# given a body, return a response

# given a 
aq_parse <- function(x, ...) {
  jsonlite::fromJSON(x, ...)
}

group_aggregate_api <- function(df, str_group, str_agg, str_fn_agg) {
  
}

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
      choices = cols_category(parse_inp())
    )
  }) 
  
  observe({  
    updateSelectizeInput(
      session,
      inputId = "cols_agg",
      choices = cols_number(parse_inp())
    )
  })

  # -------------------  
  # reactive values
  # -------------------  
  parse_inp <- 
    reactive({
     
      # use palmer penguins as default
      if (is.null(input$upload_inp)) {
        return(palmerpenguins::penguins)
      }
     
      readr::read_csv(input$upload_inp$datapath, show_col_types = FALSE)
    }) |>
    bindEvent(input$upload_inp, ignoreNULL = FALSE, ignoreInit = FALSE)

  aggregate <- 
    reactive({
      group_aggregate(
        parse_inp(), 
        str_group = input$cols_group, 
        str_agg = input$cols_agg, 
        str_fn_agg = input$func_agg
      )
    }) |>
    bindEvent(input$button, ignoreNULL = TRUE, ignoreInit = TRUE)

  # -------------------   
  # outputs
  # -------------------   
  output$table_inp <- DT::renderDT(parse_inp())
  
  output$download_inp <- downloadHandler(
    filename = \() glue::glue("data-input-{Sys.Date()}.csv"),
    content = \(file) readr::write_csv(parse_inp(), file)
  )
  
  output$table_agg <- DT::renderDT(aggregate())
  
  output$download_agg <- downloadHandler(
    filename = \() glue::glue("data-aggregated-{Sys.Date()}.csv"),
    content = \(file) readr::write_csv(aggregate(), file)
  )
 
}

# ------------------- 
shinyApp(ui = ui, server = server)
