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

group_aggregate_service <- function(df, str_group, str_agg, str_fn_agg) {
  
}