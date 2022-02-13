# choices for aggregation functions
agg_function_choices <- c("mean", "min", "max")

# given a data frame, return the names of numeric columns
cols_number <- function(df) {
  df_select <- dplyr::select(df, where(~is.numeric(.x) | is.integer(.x)) ) 
  names(df_select)
}

# given a data frame, return the names of string and factor columns
cols_category <- function(df) {
  df_select <- dplyr::select(df, where(~is.character(.x) | is.factor(.x)) ) 
  names(df_select)
}

# make the aggregation
group_aggregate <- function(df, str_group, str_agg, str_fn_agg, 
                            str_fn_choices = agg_function_choices) {
  
  # safeguard the aggregation function
  stopifnot(
    str_fn_agg %in% str_fn_choices
  )
  
  # get the aggregation function
  func <- get(str_fn_agg)
  
  df |>
    dplyr::group_by(dplyr::across(dplyr::all_of(str_group))) |>
    dplyr::summarise(
      dplyr::across(dplyr::all_of(str_agg), func, na.rm = TRUE)
    )
}
