#
#                _         _    _      _                _    
#               (_)       | |  | |    | |              | |   
#  _ __    ___   _  _ __  | |_ | |__  | |  __ _  _ __  | | __
# | '_ \  / _ \ | || '_ \ | __|| '_ \ | | / _` || '_ \ | |/ /
# | |_) || (_) || || | | || |_ | |_) || || (_| || | | ||   < 
# | .__/  \___/ |_||_| |_| \__||_.__/ |_| \__,_||_| |_||_|\_\
# | |                                                        
# |_|                                                        
# 
# This file is part of the 'rich-iannone/pointblank' package.
# 
# (c) Richard Iannone <riannone@me.com>
# 
# For full copyright and license information, please look at
# https://rich-iannone.github.io/pointblank/LICENSE.html
#


#' Do column data lie outside of two specified values or data in other columns?
#' 
#' @description
#' The `col_vals_not_between()` validation function, the
#' `expect_col_vals_not_between()` expectation function, and the
#' `test_col_vals_not_between()` test function all check whether column values
#' in a table *do not* fall within a range. The range specified with three
#' arguments: `left`, `right`, and `inclusive`. The `left` and `right` values
#' specify the lower and upper bounds. The bounds can be specified as single,
#' literal values or as column names given in `vars()`. The `inclusive`
#' argument, as a vector of two logical values relating to `left` and `right`,
#' states whether each bound is inclusive or not. The default is `c(TRUE,
#' TRUE)`, where both endpoints are inclusive (i.e., `[left, right]`). For
#' partially-unbounded versions of this function, we can use the
#' [col_vals_lt()], [col_vals_lte()], [col_vals_gt()], or [col_vals_gte()]
#' validation functions. The validation function can be used directly on a data
#' table or with an *agent* object (technically, a `ptblank_agent` object)
#' whereas the expectation and test functions can only be used with a data
#' table. The types of data tables that can be used include data frames,
#' tibbles, database tables (`tbl_dbi`), and Spark DataFrames (`tbl_spark`).
#' Each validation step or expectation will operate over the number of test
#' units that is equal to the number of rows in the table (after any
#' `preconditions` have been applied).
#'
#' @section Column Names:
#' If providing multiple column names to `columns`, the result will be an
#' expansion of validation steps to that number of column names (e.g.,
#' `vars(col_a, col_b)` will result in the entry of two validation steps). Aside
#' from column names in quotes and in `vars()`, **tidyselect** helper functions
#' are available for specifying columns. They are: `starts_with()`,
#' `ends_with()`, `contains()`, `matches()`, and `everything()`.
#'
#' @section Missing Values:
#' This validation function supports special handling of `NA` values. The
#' `na_pass` argument will determine whether an `NA` value appearing in a test
#' unit should be counted as a *pass* or a *fail*. The default of `na_pass =
#' FALSE` means that any `NA`s encountered will accumulate failing test units.
#' 
#' @section Preconditions:
#' Having table `preconditions` means **pointblank** will mutate the table just
#' before interrogation. Such a table mutation is isolated in scope to the
#' validation step(s) produced by the validation function call. Using
#' **dplyr** code is suggested here since the statements can be translated to
#' SQL if necessary. The code is most easily supplied as a one-sided **R**
#' formula (using a leading `~`). In the formula representation, the `.` serves
#' as the input data table to be transformed (e.g., 
#' `~ . %>% dplyr::mutate(col_a = col_b + 10)`). Alternatively, a function could
#' instead be supplied (e.g., 
#' `function(x) dplyr::mutate(x, col_a = col_b + 10)`).
#' 
#' @section Actions:
#' Often, we will want to specify `actions` for the validation. This argument,
#' present in every validation function, takes a specially-crafted list
#' object that is best produced by the [action_levels()] function. Read that
#' function's documentation for the lowdown on how to create reactions to
#' above-threshold failure levels in validation. The basic gist is that you'll
#' want at least a single threshold level (specified as either the fraction of
#' test units failed, or, an absolute value), often using the `warn_at`
#' argument. This is especially true when `x` is a table object because,
#' otherwise, nothing happens. For the `col_vals_*()`-type functions, using 
#' `action_levels(warn_at = 0.25)` or `action_levels(stop_at = 0.25)` are good
#' choices depending on the situation (the first produces a warning when a
#' quarter of the total test units fails, the other `stop()`s at the same
#' threshold level).
#' 
#' @section Briefs:
#' Want to describe this validation step in some detail? Keep in mind that this
#' is only useful if `x` is an *agent*. If that's the case, `brief` the agent
#' with some text that fits. Don't worry if you don't want to do it. The
#' *autobrief* protocol is kicked in when `brief = NULL` and a simple brief will
#' then be automatically generated.
#' 
#' @section YAML:
#' A **pointblank** agent can be written to YAML with [yaml_write()] and the
#' resulting YAML can be used to regenerate an agent (with [yaml_read_agent()])
#' or interrogate the target table (via [yaml_agent_interrogate()]). When
#' `col_vals_not_between()` is represented in YAML (under the top-level `steps`
#' key as a list member), the syntax closely follows the signature of the
#' validation function. Here is an example of how a complex call of
#' `col_vals_not_between()` as a validation step is expressed in R code and in
#' the corresponding YAML representation.
#' 
#' ```
#' # R statement
#' agent %>% 
#'   col_vals_not_between(
#'     columns = vars(a),
#'     left = 1,
#'     right = 2,
#'     inclusive = c(TRUE, FALSE),
#'     na_pass = TRUE,
#'     preconditions = ~ . %>% dplyr::filter(a < 10),
#'     actions = action_levels(warn_at = 0.1, stop_at = 0.2),
#'     label = "The `col_vals_not_between()` step.",
#'     active = FALSE
#'   )
#' 
#' # YAML representation
#' steps:
#' - col_vals_not_between:
#'     columns: vars(a)
#'     left: 1.0
#'     right: 2.0
#'     inclusive:
#'     - true
#'     - false
#'     na_pass: true
#'     preconditions: ~. %>% dplyr::filter(a < 10)
#'     actions:
#'       warn_fraction: 0.1
#'       stop_fraction: 0.2
#'     label: The `col_vals_not_between()` step.
#'     active: false
#' ```
#' 
#' In practice, both of these will often be shorter as only the `columns`,
#' `left`, and `right` arguments require values. Arguments with default values
#' won't be written to YAML when using [yaml_write()] (though it is acceptable
#' to include them with their default when generating the YAML by other means).
#' It is also possible to preview the transformation of an agent to YAML without
#' any writing to disk by using the [yaml_agent_string()] function.
#'
#' @inheritParams col_vals_gt
#' @param left,right The lower (or left) and upper (or right) boundary values
#'   for the range. These can be expressed as single values, compatible columns
#'   given in `vars()`, or a combination of both. By default, any column values
#'   greater than or equal to `left` *and* less than or equal to `right` will
#'   fail validation. The inclusivity of the bounds can be modified by the
#'   `inclusive` option.
#'   
#' @inheritParams col_vals_between
#' 
#' @return For the validation function, the return value is either a
#'   `ptblank_agent` object or a table object (depending on whether an agent
#'   object or a table was passed to `x`). The expectation function invisibly
#'   returns its input but, in the context of testing data, the function is
#'   called primarily for its potential side-effects (e.g., signaling failure).
#'   The test function returns a logical value.
#'   
#' @examples
#' # The `small_table` dataset in the
#' # package has a column of numeric
#' # values in `c` (there are a few NAs
#' # in that column); the following
#' # examples will validate the values
#' # in that numeric column
#' 
#' # A: Using an `agent` with validation
#' #    functions and then `interrogate()`
#' 
#' # Validate that values in column `c`
#' # are all between `10` and `20`; because
#' # there are NA values, we'll choose to
#' # let those pass validation by setting
#' # `na_pass = TRUE`
#' agent <-
#'   create_agent(small_table) %>%
#'   col_vals_not_between(
#'     vars(c), 10, 20, na_pass = TRUE
#'   ) %>%
#'   interrogate()
#'   
#' # Determine if this validation
#' # had no failing test units (there
#' # are 13 test units, one for each row)
#' all_passed(agent)
#' 
#' # Calling `agent` in the console
#' # prints the agent's report; but we
#' # can get a `gt_tbl` object directly
#' # with `get_agent_report(agent)`
#' 
#' # B: Using the validation function
#' #    directly on the data (no `agent`)
#' 
#' # This way of using validation functions
#' # acts as a data filter: data is passed
#' # through but should `stop()` if there
#' # is a single test unit failing; the
#' # behavior of side effects can be
#' # customized with the `actions` option
#' small_table %>%
#'   col_vals_not_between(
#'     vars(c), 10, 20, na_pass = TRUE
#'   ) %>%
#'   dplyr::pull(c)
#'
#' # C: Using the expectation function
#' 
#' # With the `expect_*()` form, we would
#' # typically perform one validation at a
#' # time; this is primarily used in
#' # testthat tests
#' expect_col_vals_not_between(
#'   small_table, vars(c), 10, 20,
#'   na_pass = TRUE
#' )
#' 
#' # D: Using the test function
#' 
#' # With the `test_*()` form, we should
#' # get a single logical value returned
#' # to us
#' small_table %>%
#'   test_col_vals_not_between(
#'     vars(c), 10, 20,
#'     na_pass = TRUE
#'   )
#'
#' # An additional note on the bounds for
#' # this function: they are inclusive by
#' # default; we can modify the
#' # inclusiveness of the upper and lower
#' # bounds with the `inclusive` option,
#' # which is a length-2 logical vector
#' 
#' # In changing the lower bound to be
#' # `9` and making it non-inclusive, we
#' # get `TRUE` since although two values
#' # are `9` and they fall outside of the
#' # lower (or left) bound (and any values
#' # 'not between' count as passing test
#' # units)
#' small_table %>%
#'   test_col_vals_not_between(
#'     vars(c), 9, 20,
#'     inclusive = c(FALSE, TRUE),
#'     na_pass = TRUE
#'   )
#' 
#' @family validation functions
#' @section Function ID:
#' 2-8
#' 
#' @seealso The analogue to this function: [col_vals_between()].
#' 
#' @name col_vals_not_between
NULL

#' @rdname col_vals_not_between
#' @import rlang
#' @export
col_vals_not_between <- function(x,
                                 columns,
                                 left,
                                 right,
                                 inclusive = c(TRUE, TRUE),
                                 na_pass = FALSE,
                                 preconditions = NULL,
                                 actions = NULL,
                                 step_id = NULL,
                                 label = NULL,
                                 brief = NULL,
                                 active = TRUE) {
  
  # Get `columns` as a label
  columns_expr <- 
    rlang::as_label(rlang::quo(!!enquo(columns))) %>%
    gsub("^\"|\"$", "", .)
  
  # Capture the `columns` expression
  columns <- rlang::enquo(columns)
  
  # Resolve the columns based on the expression
  columns <- resolve_columns(x = x, var_expr = columns, preconditions)
  
  left <- stats::setNames(left, inclusive[1])
  right <- stats::setNames(right, inclusive[2])
  
  if (is_a_table_object(x)) {
    
    secret_agent <-
      create_agent(x, label = "::QUIET::") %>%
      col_vals_not_between(
        columns = columns,
        left = left,
        right = right,
        inclusive = inclusive,
        na_pass = na_pass,
        preconditions = preconditions,
        label = label,
        brief = brief,
        actions = prime_actions(actions),
        active = active
      ) %>%
      interrogate()
    
    return(x)
  }
  
  agent <- x
  
  if (is.null(brief)) {
    brief <- 
      generate_autobriefs(
        agent,
        columns,
        preconditions,
        values = c(left, right),
        "col_vals_not_between"
      )
  }
  
  # Normalize any provided `step_id` value(s)
  step_id <- normalize_step_id(step_id, columns, agent)
  
  # Get the next step number for the `validation_set` tibble
  i_o <- get_next_validation_set_row(agent)
  
  # Check `step_id` value(s) against all other `step_id`
  # values in earlier validation steps
  check_step_id_duplicates(step_id, agent)
  
  # Add one or more validation steps based on the
  # length of the `columns` variable
  for (i in seq(columns)) {
    
    agent <-
      create_validation_step(
        agent = agent,
        assertion_type = "col_vals_not_between",
        i_o = i_o,
        columns_expr = columns_expr,
        column = columns[i],
        values = c(left, right),
        na_pass = na_pass,
        preconditions = preconditions,
        actions = covert_actions(actions, agent),
        step_id = step_id[i],
        label = label,
        brief = brief[i],
        active = active
      )
  }

  agent
}

#' @rdname col_vals_not_between
#' @import rlang
#' @export
expect_col_vals_not_between <- function(object,
                                        columns,
                                        left,
                                        right,
                                        inclusive = c(TRUE, TRUE),
                                        na_pass = FALSE,
                                        preconditions = NULL,
                                        threshold = 1) {
  
  fn_name <- "expect_col_vals_not_between"
  
  vs <- 
    create_agent(tbl = object, label = "::QUIET::") %>%
    col_vals_not_between(
      columns = {{ columns }},
      left = {{ left }}, 
      right = {{ right }},
      inclusive = inclusive,
      na_pass = na_pass,
      preconditions = {{ preconditions }},
      actions = action_levels(notify_at = threshold)
    ) %>%
    interrogate() %>%
    .$validation_set
  
  x <- vs$notify %>% all()
  
  threshold_type <- get_threshold_type(threshold = threshold)
  
  if (threshold_type == "proportional") {
    failed_amount <- vs$f_failed
  } else {
    failed_amount <- vs$n_failed
  }
  
  if (inherits(vs$capture_stack[[1]]$warning, "simpleWarning")) {
    warning(conditionMessage(vs$capture_stack[[1]]$warning))
  }
  if (inherits(vs$capture_stack[[1]]$error, "simpleError")) {
    stop(conditionMessage(vs$capture_stack[[1]]$error))
  }
  
  act <- testthat::quasi_label(enquo(x), arg = "object")
  
  column_text <- prep_column_text(vs$column[[1]])
  value_1 <- 
    prep_values_text(values = vs$values[[1]][[1]], limit = 3, lang = "en")
  value_2 <- 
    prep_values_text(values = vs$values[[1]][[2]], limit = 3, lang = "en")
  
  testthat::expect(
    ok = identical(!as.vector(act$val), TRUE),
    failure_message = glue::glue(
      failure_message_gluestring(
        fn_name = fn_name, lang = "en"
      )
    )
  )
  
  act$val <- object
  
  invisible(act$val)
}

#' @rdname col_vals_not_between
#' @import rlang
#' @export
test_col_vals_not_between <- function(object,
                                      columns,
                                      left,
                                      right,
                                      inclusive = c(TRUE, TRUE),
                                      na_pass = FALSE,
                                      preconditions = NULL,
                                      threshold = 1) {
  
  vs <- 
    create_agent(tbl = object, label = "::QUIET::") %>%
    col_vals_not_between(
      columns = {{ columns }},
      left = {{ left }}, 
      right = {{ right }},
      inclusive = inclusive,
      na_pass = na_pass,
      preconditions = {{ preconditions }},
      actions = action_levels(notify_at = threshold)
    ) %>%
    interrogate() %>%
    .$validation_set
  
  if (inherits(vs$capture_stack[[1]]$warning, "simpleWarning")) {
    warning(conditionMessage(vs$capture_stack[[1]]$warning))
  }
  if (inherits(vs$capture_stack[[1]]$error, "simpleError")) {
    stop(conditionMessage(vs$capture_stack[[1]]$error))
  }
  
  all(!vs$notify)
}
