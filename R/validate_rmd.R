test_options <- new.env(parent = emptyenv())

#nocov start

#' Modify **pointblank** validation testing options within R Markdown documents
#' 
#' Using **pointblank** in an R Markdown workflow is enabled by default once the
#' **pointblank** library is loaded. The framework allows for validation testing
#' within specialized validation code chunks where the `validate = TRUE` option
#' is set. Using **pointblank** validation functions on data in these
#' marked code chunks will flag overall failure if the stop threshold is
#' exceeded anywhere. All errors are reported in the validation code chunk after
#' rendering the document to HTML, where green or red status buttons indicate
#' whether all validations succeeded or failures occurred. Clicking any such
#' button reveals the otherwise hidden validation statements and their error
#' messages (if any). While the framework for such testing is set up by default,
#' the `validate_rmd()` function offers an opportunity to set UI and logging
#' options.
#'
#' @param summary If `TRUE` (the default), then there will be a leading summary
#'   of all validations in the rendered R Markdown document. With `FALSE`, this
#'   element is not shown.
#' @param log_to_file An option to log errors to a text file. By default, no
#'   logging is done but `TRUE` will write log entries to
#'   `"validation_errors.log"` in the working directory. To both enable logging
#'   and to specify a file name, include a path to a log file of the desired
#'   name.
#'
#' @family Planning and Prep
#' @section Function ID:
#' 1-3
#' 
#' @export
validate_rmd <- function(summary = TRUE,
                         log_to_file = NULL) {
  
  # Store the `summary` value to `test_options`
  test_options$summary <- summary
  
  # Determine whether file logging with `log4r` is to be done and also
  # determine the filename of the logging file
  if (!is.null(log_to_file)) {
    
    if (isTRUE(log_to_file)) {
      
      # TODO: consider appending the date and time to the
      # generic `validation_errors.log` filename
      test_options$perform_logging <- TRUE
      test_options$log_to_file <- file.path(getwd(), "validation_errors.log")
      
    } else if (is.character(log_to_file)) {
      
      test_options$perform_logging <- TRUE
      test_options$log_to_file <- log_to_file
      
    } else if (!isTRUE(log_to_file) && is.logical(log_to_file)) {
      test_options$perform_logging <- FALSE
    }
  }
  
  if (test_options$perform_logging) {
    
    # Create a log4r `logger` object and store it in `test_options`
    test_options$logger <- 
      log4r::logger(
        threshold = "ERROR",
        appenders = log4r::file_appender(test_options$log_to_file)
      )
  }
}

validate_rmd_setup <- function() {
  
  knitr::opts_hooks$set(
    error = function(options) {
      if (isTRUE(options$validate)) {
        options$error = TRUE
      }
      options
    }
  )
  
  error <- knitr_error_hook(knitr::knit_hooks$get("error"))
  document <- knitr_document_hook(knitr::knit_hooks$get("document"))
  
  knitr::knit_hooks$set(
    chunk = knitr_chunk_hook,
    error = error,
    document = document
  )
  
  reset_doc_counts()
  
  # Store default logical values for the summary and logging options
  test_options$summary <- TRUE
  test_options$perform_logging <- FALSE
  
  validate_rmd_dependencies()
}

log4r_error <- function(message) {
  
  if (test_options$perform_logging) {
    log4r::error(logger = test_options$logger, message = message)
  }
}

increment_count <- function(type) {
  (current_chunk_counts[[type]] <- current_chunk_counts[[type]] + 1L)
  (current_doc_counts[[type]] <- current_doc_counts[[type]] + 1L)
}
reset_chunk_counts <- function() {
  current_chunk_counts$error <- 0
  current_chunk_counts$pass <- 0
}
reset_doc_counts <- function() {
  reset_chunk_counts()
  current_doc_counts$error <- 0
  current_doc_counts$pass <- 0
}
get_chunk_count <- function(type) {
  current_chunk_counts[[type]]
}
get_doc_count <- function(type) {
  current_doc_counts[[type]]
}

current_chunk_counts <- new.env(parent = emptyenv())
current_doc_counts <- new.env(parent = emptyenv())
reset_doc_counts()

validate_rmd_dependencies <- function() {
  
  htmltools::attachDependencies(
    htmltools::tagList(),
    htmltools::htmlDependency(
      name = "rmd_integration",
      version = utils::packageVersion("pointblank"),
      src = system.file("css", package = "pointblank"),
      stylesheet = "rmd_styles.css"
    )
  )
}

render_template <- function(template_name, data) {
  
  path <- 
    system.file(
      "templates", "default", paste0(template_name, ".html"),
      package = "pointblank"
    )
  
  if (!nzchar(path)) {
    stop("The template `", template_name, "` was not found.")
  }
  
  template <- paste(readLines(path, warn = FALSE), collapse = "\n")
  
  if (template_name == "chunk") {
    
    text <- pb_glue_data(data, "{error_count} {noun} failed")
    
    if (data$agent_report) {
      
      state <- "info"
      text <- "Agent Report"
      
    } else if (data$pass) {
      
      state <- "success"  
      text <- "All validations passed."
      
    } else {
      
      state <- "danger"
      text <- pb_glue_data(data, "{error_count} {noun} failed.")
    }
    
    rendered <- pb_glue_data(c(data, list(state = state, text = text)), template)
    
  } else if (template_name == "document") {
    
    if (!data$pass) {
      
      alert <- 
        pb_glue_data(
          data, 
          htmltools::htmlPreserve(
            htmltools::tags$div(
              class = "alert alert-danger",
              htmltools::tags$strong("Warning:"),
              "this document contains {error_count} failing {noun}."
            )
          )
        )
      
    } else {
      alert <- ""
    }
    
    rendered <- pb_glue_data(c(data, list(alert = alert)), template)
  }
  
  rendered
}

knitr_error_hook <- function(previous_hook) {
  force(previous_hook)
  
  function(x, options) {
    
    if (isTRUE(options$validate)) {

      increment_count("error")
      
      error_message <- x %>% tidy_gsub("##", "") %>% tidy_gsub("\n", "")
      log4r_error(message = error_message)
    }
    
    previous_hook(x, options)
  }
}

knitr_document_hook <- function(previous_hook) {
  force(previous_hook)
  
  function(x) {
    if (!isTRUE(test_options$summary)) {
      return(previous_hook(x))
    }
    
    content <- previous_hook(x)
    content <- paste(content, collapse = "\n")
    
    matches <- regexec("^(.*)\r?\n---\r?\n(.*)$", content)
    matches <- regmatches(content, matches)
    
    header <- matches[[1]][2]
    body <- matches[[1]][3]
    
    error_count <- get_doc_count("error")
    pass <- error_count == 0
    
    data <- 
      list(
        content = body,
        pass = pass,
        error_count = error_count,
        noun = if (error_count == 1) "validation" else "validations"
      )
    
    c(header, "---", render_template("document", data))
  }
}

knitr_evaluate_hook <- function(previous_hook) {
  force(previous_hook)
  
  function(...) {
    withCallingHandlers(
      previous_hook(...),
      expectation_success = function(e) {
        increment_count("pass")
      }
    )
  }
}

knitr_chunk_hook <- function(x, options) {
  
  if (!isTRUE(options$validate)) {
    return(x)
  }
  
  on.exit(reset_chunk_counts(), add = TRUE)
  
  if (options$eval == FALSE) {
    return("")
  }
  
  error_count <- get_chunk_count("error")
  pass <- error_count == 0
  agent_report <- FALSE
  
  extract_code <- function(x) {
    
    matches <- gregexpr(pattern = "```r(.|\n)*?```", x)
    
    regmatches(x = x, m = matches) %>%
      unlist() %>%
      tidy_gsub("(```r\\n|\\n```)", "")
  }
  
  extract_output <- function(x) {
    
    if (grepl("<!--html_preserve-->", x)) {
      
      matches <- gregexpr(pattern = "<!--html_preserve-->(.|\n)*?<!--/html_preserve-->", x)

      output <- regmatches(x = x, m = matches) %>% unlist()
      
    } else {
      
      matches <- gregexpr(pattern = "```\n##(.|\n)*?```", x)
      
      output <- 
        regmatches(x = x, m = matches) %>%
        unlist() %>%
        tidy_gsub("(```\\n|\\n```)", "")
    }
    
    output
  }
  
  is_error_output <- function(output_vec) {
    grepl("^## Error", output_vec)
  }
  
  is_agent_tbl_output <- function(output_vec) {
    grepl("<!--html_preserve-->", output_vec)
  }
  
  code_vec <- extract_code(x)
  output_vec <- extract_output(x)
  agent_tbl_vec <- is_agent_tbl_output(output_vec)
  error_vec <- is_error_output(output_vec = output_vec)
  
  agent_report <- any(agent_tbl_vec)
  
  for (i in seq_along(output_vec)) {
    
    if (agent_tbl_vec[i]) {
      next
    }
    
    if (!error_vec[i]) {
      output_vec[i] <- NA_character_
    }
  }
  
  remix_content <- function(code_vec, output_vec, error_vec, agent_tbl_vec) {
    
    pass_svg <- 
      htmltools::HTML(
        "<svg height=\"1.5em\" viewBox=\"0 0 32 32\" style=\"margin-top: 1px; fill: green;\"><path d=\"M 28.28125 6.28125 L 11 23.5625 L 3.71875 16.28125 L 2.28125 17.71875 L 10.28125 25.71875 L 11 26.40625 L 11.71875 25.71875 L 29.71875 7.71875 Z\"></path></svg>"
      )
    
    fail_svg <- 
      htmltools::HTML(
        "<svg height=\"1.5em\" viewBox=\"0 0 32 32\" style=\"margin-top: 3px; fill: red;\"><path d=\"M 16 3 C 8.832031 3 3 8.832031 3 16 C 3 23.167969 8.832031 29 16 29 C 23.167969 29 29 23.167969 29 16 C 29 8.832031 23.167969 3 16 3 Z M 16 5 C 22.085938 5 27 9.914063 27 16 C 27 22.085938 22.085938 27 16 27 C 9.914063 27 5 22.085938 5 16 C 5 9.914063 9.914063 5 16 5 Z M 12.21875 10.78125 L 10.78125 12.21875 L 14.5625 16 L 10.78125 19.78125 L 12.21875 21.21875 L 16 17.4375 L 19.78125 21.21875 L 21.21875 19.78125 L 17.4375 16 L 21.21875 12.21875 L 19.78125 10.78125 L 16 14.5625 Z\"/></svg>"
      )
    
    content <- c()
    
    for (i in seq_along(code_vec)) {
     
      if (agent_tbl_vec[i]) {
        
        # Agent Report Table Case
        output_content <-
          htmltools::tagList(
            htmltools::HTML(output_vec), htmltools::tags$br()
          )
        
      } else if (!error_vec[i]) {
        
        # Success Case
        output_content <- 
          htmltools::tagList(
            htmltools::tags$div(
              class = "panel panel-success",
              htmltools::tags$div(
                class = "panel-heading",
                style = "color: #333; border-color: transparent;",
                htmltools::tags$div(
                  style = "display: inline-flex; width: 100%",
                  htmltools::tags$div(
                    style = "margin-top: 2px; padding-left: 5px; background: #FAFAFA;",
                    pass_svg
                  ),
                  htmltools::tags$div(
                    style = "padding-left: 2px; padding-right: 2px; padding-top: 2px; padding-bottom: 4px; margin-top: 2px; background: #FAFAFA; width: 100%; overflow-x: scroll;",
                    htmltools::tags$code(
                      style = "background-color: #FAFAFA; padding-left: 0;",
                      code_vec[i]
                    )
                  )
                )
              )
            )
          )
        
      } else {
        
        # Failure Case
        output_content <- 
          htmltools::tagList(
            htmltools::tags$div(
              class = "panel panel-danger",
              htmltools::tags$div(
                class = "panel-heading",
                style = "color: #333; border-color: transparent;",
                htmltools::tags$div(
                  style = "display: inline-flex; width: 100%",
                  htmltools::tags$div(
                    style = "margin-top: 2px; padding-left: 5px; background: #FAFAFA;",
                    fail_svg
                  ),
                  htmltools::tags$div(
                    style = "padding-left: 2px; padding-right: 2px; padding-top: 2px; padding-bottom: 4px; margin-top: 2px; background: #FAFAFA; width: 100%; overflow-x: scroll;",
                    htmltools::tags$code(
                      style = "background-color: #FAFAFA; padding-left: 0;",
                      code_vec[i]
                    )
                  )
                ),
                htmltools::tags$hr(
                  style = "margin-top: 10px; margin-bottom: 0; border: 1px solid #EBCCD1;"
                ),
                htmltools::tags$div(
                  class = "panel-body",
                  style = "padding-left: 15px; padding-top: 15px; padding-right: 15px; padding-bottom: 15px; background: #FAFAFA; width: 100%; overflow-x: scroll;",
                  htmltools::tags$code(
                    style = "background-color: #FAFAFA; padding-left: 0; overflow-x: scroll;",
                    output_vec[i]
                  )
                ),
                htmltools::tags$hr(
                  style = "margin-top: 0; margin-bottom: 0; border: 1px solid #EBCCD1;"
                ),
              )
            )
          )
      }
      
      content <-  c(content, as.character(output_content)) %>% as.character()
        
    }
    
    content <- paste(content, collapse = "")
  }
  
  content <- 
    remix_content(
      code_vec = code_vec,
      output_vec = output_vec,
      error_vec = error_vec,
      agent_tbl_vec = agent_tbl_vec
    )
    
  # Prepare the data list
  data <- 
    list(
      chunk_id = sprintf("chunk-%07d", sample.int(9999999, 1)),
      button_class = "default",
      bootstrap_class = if (pass) "success" else "danger",
      status = if (pass) "pass" else "fail",
      pass = pass,
      agent_report = agent_report,
      pass_count = get_chunk_count("pass"),
      error_count = error_count,
      content = content,
      noun = if (error_count == 1) "validation" else "validations"
    )
  
  render_template("chunk", data)
}

#nocov end

#' The next generation of `stopifnot()`-type functions: `stop_if_not()`
#'
#' This is `stopifnot()` but with a twist: it works well as a standalone,
#' replacement for `stopifnot()` but is also customized for use in validation
#' checks in R Markdown documents where **pointblank** is loaded. Using
#' `stop_if_not()` in a code chunk where the `validate = TRUE` option is set
#' will yield the correct reporting of successes and failures whereas
#' `stopifnot()` *does not*.
#' 
#' @param ... R expressions that should each evaluate to (a logical vector of
#' all) `TRUE`.
#' 
#' @return `NULL` if all statements in `...` are `TRUE`.
#' 
#' @examples 
#' # This checks whether the number of
#' # rows in `small_table` is greater
#' # than `10`
#' stop_if_not(nrow(small_table) > 10)
#' 
#' # This will stop for sure: there
#' # isn't a `time` column in `small_table`
#' # (but there are the `date_time` and
#' # `date` columns)
#' # stop_if_not("time" %in% colnames(small_table))
#' 
#' # You're not bound to using tabular
#' # data here, any statements that
#' # evaluate to logical vectors will work
#' stop_if_not(1:5 < 20:25)
#' 
#' @export
stop_if_not <- function(...) {
  
  res <- list(...)
  
  n <- length(res)
  
  if (n == 0L) return()

  for (y in 1L:n) {
    
    res_y <- .subset2(res, y)
    
    if (length(res_y) != 1 || is.na(res_y) || !res_y) {
      
      if (all(res_y)) break
      
      matched_call <- match.call()
      
      deparsed_call <- deparse(matched_call[[y + 1]])
      
      if (length(deparsed_call) > 1) {
        deparsed_call <- paste(deparsed_call[1L], "...")
      }
      
      stop(
        sQuote(deparsed_call), " is not TRUE.",
        call. = FALSE, domain = NA
      )
    }
  }

  if ("knitr" %in% loadedNamespaces() &&
      "pointblank" %in% loadedNamespaces() &&
      exists("options$validate") && 
      isTRUE(options$validate)) {
    
    return(TRUE)
    
  } else {
    
    return()
  }
}