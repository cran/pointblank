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


#' Define a store of tables with table-prep formulas: a table store
#' 
#' @description 
#' It can be useful to set up all the data sources you need and just draw from
#' them when necessary. This upfront configuration with `tbl_store()` lets us
#' define the methods for obtaining tabular data from mixed sources (e.g.,
#' database tables, tables generated from flat files, etc.) and provide names
#' for these data preparation procedures. Then we have a convenient way to
#' access the materialized tables with [tbl_get()], or, the table-prep formulas
#' with [tbl_source()]. Table-prep formulas can be as simple as getting a table
#' from a location, or, it can involve as much mutation as is necessary (imagine
#' procuring several mutated variations of the same source table, generating a
#' table from multiple sources, or pre-filtering a database table according to
#' the system time). Another nice aspect of organizing table-prep formulas in a
#' single object is supplying it to the `read_fn` argument of [create_agent()]
#' or [create_informant()] via `$` notation (e.g, `create_agent(read_fn =
#' <tbl_store>$<name>)`) or with [tbl_source()] (e.g., `create_agent(read_fn = ~
#' tbl_source("<name>", <tbl_store>))`).
#' 
#' @section YAML:
#' A **pointblank** table store can be written to YAML with [yaml_write()] and
#' the resulting YAML can be used in several ways. The ideal scenario is to have
#' pointblank agents and informants also in YAML form. This way the agent and
#' informant can refer to the table store YAML (via [tbl_source()]), and, the
#' processing of both agents and informants can be performed with
#' [yaml_agent_interrogate()] and [yaml_informant_incorporate()]. With the
#' following R code, a table store with two table-prep formulas is generated and
#' written to YAML (if no filename is given then the YAML is written to
#' `"tbl_store.yml"`).
#' 
#' ```
#' # R statement for generating the "tbl_store.yml" file
#' tbl_store(
#'   tbl_duckdb ~ db_tbl(small_table, dbname = ":memory:", dbtype = "duckdb"),
#'   sml_table_high ~ small_table %>% dplyr::filter(f == "high")
#' ) %>%
#'   yaml_write()
#' 
#' # YAML representation ("tbl_store.yml")
#' tbls:
#'   tbl_duckdb: ~ db_tbl(small_table, dbname = ":memory:", dbtype = "duckdb")
#'   sml_table_high: ~ small_table %>% dplyr::filter(f == "high")
#' ```
#' 
#' This is useful when you want to get fresh pulls of prepared data from a
#' source materialized in an R session (with the [tbl_get()] function. For
#' example, the `sml_table_high` table can be obtained by using
#' `tbl_get("sml_table_high", "tbl_store.yml")`. To get an agent to check this
#' prepared data periodically, then the following example with [tbl_source()]
#' will be useful:
#' 
#' ```
#' # Generate agent that checks `sml_table_high`, write it to YAML
#' create_agent(
#'   read_fn = ~ tbl_source("sml_table_high", "tbl_store.yml"),
#'   label = "An example that uses a table store.",
#'   actions = action_levels(warn_at = 0.10)
#' ) %>% 
#'   col_exists(vars(date, date_time)) %>%
#'   write_yaml()
#'   
#' # YAML representation ("agent-sml_table_high.yml")
#' read_fn: ~ tbl_source("sml_table_high", "tbl_store.yml")
#' tbl_name: sml_table_high
#' label: An example that uses a table store.
#' actions:
#'   warn_fraction: 0.1
#' locale: en
#' steps:
#'   - col_exists:
#'     columns: vars(date, date_time)
#' ```
#' 
#' Now, whenever the `sml_table_high` table needs to be validated, it can be
#' done with [yaml_agent_interrogate()] (e.g., 
#' `yaml_agent_interrogate("agent-sml_table_high.yml")`).
#' 
#' @param ... Expressions that contain table-prep formulas and table names for
#'   data retrieval. Two-sided formulas (e.g, `<LHS> ~ <RHS>`) are to be used,
#'   where the left-hand side is a given name and the right-hand is the portion
#'   that is is used to obtain the table.
#' @param .list Allows for the use of a list as an input alternative to `...`.
#' 
#' @return A `tbl_store` object that contains table-prep formulas.
#' 
#' @examples 
#' if (interactive()) {
#' 
#' # Define a `tbl_store` object by adding
#' # table-prep formulas inside the
#' # `tbl_store()` call
#' tbls <- 
#'   tbl_store(
#'     small_table_duck ~ db_tbl(
#'       table = small_table,
#'       dbname = ":memory:",
#'       dbtype = "duckdb"
#'     ),
#'     ~ db_tbl(
#'       table = "rna",
#'       dbname = "pfmegrnargs",
#'       dbtype = "postgres",
#'       host = "hh-pgsql-public.ebi.ac.uk",
#'       port = 5432,
#'       user = I("reader"),
#'       password = I("NWDMCE5xdipIjRrp")
#'     ),
#'     all_revenue ~ db_tbl(
#'       table = file_tbl(
#'         file = from_github(
#'           file = "all_revenue_large.rds",
#'           repo = "rich-iannone/intendo",
#'           subdir = "data-large"
#'         )
#'       ),
#'       dbname = ":memory:",
#'       dbtype = "duckdb"
#'     ),
#'     sml_table ~ pointblank::small_table
#'   )
#' 
#' # Once this object is available, you
#' # can check that the table of interest
#' # is produced to your specification with
#' # the `tbl_get()` function
#' tbl_get(
#'   tbl = "small_table_duck",
#'   store = tbls
#' )
#' 
#' # Another simpler way to get the same
#' # table materialized is by using `$` to
#' # get the entry of choice for `tbl_get()`
#' tbls$small_table_duck %>% tbl_get()
#' 
#' # Creating an agent is easy when all
#' # table-prep formulas are encapsulated
#' # in a `tbl_store` object; use `$` 
#' # notation to pass the appropriate
#' # procedure for reading a table to the
#' # `read_fn` argument
#' agent_1 <-
#'   create_agent(
#'     read_fn = tbls$small_table_duck
#'   )
#'   
#' # There are other ways to use the
#' # table store to assign a target table
#' # to an agent, like using the
#' # `tbl_source()` function
#' agent_2 <-
#'   create_agent(
#'     read_fn = ~ tbl_source(
#'       tbl = "small_table_duck",
#'       store = tbls
#'       )
#'   )
#' 
#' # The table store can be moved to
#' # YAML with `yaml_write` and the
#' # `tbl_source()` call could then
#' # refer to that on-disk table store;
#' # let's do that YAML conversion
#' yaml_write(tbls)
#' 
#' # The above writes the `tbl_store.yml`
#' # file (by not providing a `filename`
#' # this default filename is chosen);
#' # next, modify the `tbl_source()`
#' # so that `store` refer to the YAML
#' # file
#' agent_3 <-
#'   create_agent(
#'     read_fn = ~ tbl_source(
#'       tbl = "small_table_duck",
#'       store = "tbl_store.yml"
#'     )
#'   )
#' 
#' }
#' 
#' @family Planning and Prep
#' @section Function ID:
#' 1-8
#' 
#' @export
tbl_store <- function(...,
                      .list = list2(...)) {
  
  # Collect a fully or partially named list of tables
  tbl_list <- .list
  
  # Check that every list element is a formula
  for (i in seq_along(tbl_list)) {
    
    if (!inherits(tbl_list[[i]], "formula")) {
      stop(
        "Each entry to `tbl_store()` must be a formula.",
        call. = FALSE
      )
    }
  }
  
  # Get names for every entry in the list
  name_list <- c()
  has_given_name <- c()
  for (i in seq_along(tbl_list)) {
    
    if (is.null(rlang::f_lhs(tbl_list[[i]]))) {
      
      # Get RHS of formula and attempt to get the table name if there
      # is only a single `db_tbl()` or `file_tbl()` call
      rhs <- capture_formula(tbl_list[[i]])[2]
      
      if (grepl("~\\s*?(db_tbl|file_tbl)\\(", rhs) &&
          grepl("table\\s*?=\\s*?\".*?\"", rhs)) {
        
        tbl_name <- gsub(".*table\\s*?=\\s*?\"(.*?)\".*$", "\\1", rhs)
        
        if (!is.null(tbl_name) && length(tbl_name) == 1 && nzchar(tbl_name)) {
          name_list <- add_to_name_list(name_list, tbl_name, "stop")
          has_given_name <- c(has_given_name, TRUE)
        } else {
          tbl_name <- paste0("tbl_", formatC(i, width = 3, flag = "0"))
          name_list <- add_to_name_list(name_list, tbl_name, "rename")
          has_given_name <- c(has_given_name, FALSE)
        }
        
      } else {
        
        # If the table name isn't provided and isn't recoverable, 
        # use the index number formatted as string
        tbl_name <- paste0("tbl_", formatC(i, width = 3, flag = "0"))
        name_list <- add_to_name_list(name_list, tbl_name, "rename")
        has_given_name <- c(has_given_name, FALSE)
      }
      
    } else if (inherits(rlang::f_lhs(tbl_list[[i]]), "name")) {
      name_list <- 
        add_to_name_list(name_list, as.character(rlang::f_lhs(tbl_list[[i]])))
      has_given_name <- c(has_given_name, TRUE)
    }
  }
  
  tbl_list <- rlang::set_names(tbl_list, name_list)
  
  for (i in seq_along(tbl_list)) {
    if (has_given_name[i]) {
      class(tbl_list[[i]]) <- c("with_tbl_name", "read_fn")
    } else {
      class(tbl_list[[i]]) <- "read_fn"  
    }
  }
  
  class(tbl_list) <- "tbl_store"
  
  tbl_list
}

add_to_name_list <- function(name_list,
                             tbl_name,
                             duplicate_strategy = c("stop", "rename")) {

  duplicate_strategy <- match.arg(duplicate_strategy)
  
  # Determine if name is a duplicate in the `name_list` and employ
  # the chosen strategy
  if (tbl_name %in% name_list) {
    
    if (duplicate_strategy == "stop") {
      # Stop function if duplicate `tbl_name` seen
      stop(
        "The table name `", tbl_name, "` is a duplicate name:\n",
        "* Please choose another name since all table names must be unique",
        call. = FALSE 
      )
      
    } else {
      # Rename `tbl_name` with suffix of random numbers
      tbl_name <- paste0(tbl_name, paste(sample(0:9, 2), collapse = ""))
    }
  }
  
  c(name_list, tbl_name)
}

#' Obtain a table-prep formula from a table store
#' 
#' @description
#' The `tbl_source()` function provides a convenient means to access a
#' table-prep formula from either a `tbl_store` object or a table store YAML
#' file (which can be created with the [yaml_write()] function). A call to
#' `tbl_source()` is most useful as an input to the `read_fn` argument of
#' [create_agent()], [create_informant()], or [set_read_fn()].
#'
#' Should you need to obtain the table itself (that is generated via the
#' table-prep formula), then the [tbl_get()] function should be used for that.
#' 
#' @param tbl The table name associated with a table-prep formula. This is part
#'   of the table `store`. This table could be identified by its name (e.g.,
#'   `tbl = "large_table"`) or by supplying a reference using a subset (with
#'   `$`) of the `tbl_store` object (e.g., `tbl = store$large_table`). If using
#'   the latter method then nothing needs to be supplied to `store`.
#' @param store Either a table store object created by the [tbl_store()]
#'   function or a path to a table store YAML file created by [yaml_write()].
#' 
#' @return A table-prep formula.
#' 
#' @examples 
#' if (interactive()) {
#' 
#' # Let's create a `tbl_store` object by
#' # giving two table-prep formulas to
#' # `tbl_store()`
#' tbls <- 
#'   tbl_store(
#'     small_table_duck ~ db_tbl(
#'       table = small_table,
#'       dbname = ":memory:",
#'       dbtype = "duckdb"
#'     ),
#'     sml_table ~ pointblank::small_table
#'   )
#' 
#' # We can pass a table-prep formula
#' # to `create_agent()` and interrogate
#' # the table shortly thereafter
#' agent <- 
#'   create_agent(
#'     read_fn = ~ tbl_source("sml_table", tbls),
#'     label = "An example that uses a table store.",
#'     actions = action_levels(warn_at = 0.10)
#'   ) %>% 
#'   col_exists(vars(date, date_time)) %>%
#'   interrogate()
#'
#' # Both the `tbl_store` object and the
#' # `agent` can be transformed to YAML with
#' # the `yaml_write()` function
#' 
#' # This writes the `tbl_store.yml` file
#' # by default (but a different name
#' # could be used)
#' yaml_write(tbls)
#' 
#' # Let's modify the agent's `read_fn` to point
#' # to the YAML representation of the `tbl_store`
#' agent <-
#'   agent %>% 
#'   set_read_fn(
#'     ~ tbl_source(
#'         tbl = "sml_table",
#'         store = "tbl_store.yml"
#'       )
#'   )
#' 
#' # Then we can write agent to a YAML
#' # file (writes to `agent-sml_table.yml`
#' # by default)
#' yaml_write(agent)
#' 
#' # Now that both are in this on-disk format
#' # an interrogation can be done by accessing
#' # the agent YAML
#' agent <-
#'   yaml_agent_interrogate(
#'     filename = "agent-sml_table.yml"
#'   )
#' 
#' }
#' 
#' @family Planning and Prep
#' @section Function ID:
#' 1-9
#' 
#' @export
tbl_source <- function(tbl,
                       store = NULL) {
  
  # If `store` is supplied as a character vector,
  # assume it is a file path to a YAML file
  if (is.character(store)) {
    store <- yaml_read_tbl_store(filename = store)
  }
  
  if (is.character(tbl) && tbl %in% names(store)) {
    tbl_entry <- store[[tbl]]
  } else if (inherits(tbl, "read_fn")) {
    tbl_entry <- tbl
  }
  
  tbl_entry
}

#' Obtain a materialized table via a table store
#' 
#' @description 
#' The `tbl_get()` function gives us the means to materialize a table that has
#' an entry in a table store (i.e., has a table-prep formula with a unique
#' name). The table store that is used for this can be in the form of a
#' `tbl_store` object (created with the [tbl_store()] function) or an on-disk
#' YAML representation of a table store (created by using [yaml_write()] with a
#' `tbl_store` object).
#'
#' Should you want a table-prep formula from a table store to use as a value for
#' `read_fn` (in [create_agent()], [create_informant()], or [set_read_fn()]),
#' then have a look at the [tbl_source()] function.
#'
#' @param tbl The table to retrieve from a table `store`. This table could be
#'   identified by its name (e.g., `tbl = "large_table"`) or by supplying a
#'   reference using a subset (with `$`) of the `tbl_store` object (e.g., `tbl =
#'   store$large_table`). If using the latter method then nothing needs to be
#'   supplied to `store`.
#' @param store Either a table store object created by the [tbl_store()]
#'   function or a path to a table store YAML file created by [yaml_write()].
#' 
#' @return A table object.
#' 
#' @examples 
#' if (interactive()) {
#' 
#' # Define a `tbl_store` object by adding
#' # table-prep formulas in `tbl_store()`
#' tbls <- 
#'   tbl_store(
#'     small_table_duck ~ db_tbl(
#'       table = small_table,
#'       dbname = ":memory:",
#'       dbtype = "duckdb"
#'     ),
#'     ~ db_tbl(
#'       table = "rna",
#'       dbname = "pfmegrnargs",
#'       dbtype = "postgres",
#'       host = "hh-pgsql-public.ebi.ac.uk",
#'       port = 5432,
#'       user = I("reader"),
#'       password = I("NWDMCE5xdipIjRrp")
#'     ),
#'     all_revenue ~ db_tbl(
#'       table = file_tbl(
#'         file = from_github(
#'           file = "all_revenue_large.rds",
#'           repo = "rich-iannone/intendo",
#'           subdir = "data-large"
#'         )
#'       ),
#'       dbname = ":memory:",
#'       dbtype = "duckdb"
#'     ),
#'     sml_table ~ pointblank::small_table
#'   )
#' 
#' # Once this object is available, you can
#' # check that the table of interest is
#' # produced to your specification
#' tbl_get(
#'   tbl = "small_table_duck",
#'   store = tbls
#' )
#' 
#' # An alternative method for getting the
#' # same table materialized is by using `$`
#' # to get the formula of choice from `tbls`
#' tbls$small_table_duck %>% tbl_get()
#' 
#' }
#' 
#' @family Planning and Prep
#' @section Function ID:
#' 1-10
#' 
#' @export
tbl_get <- function(tbl,
                    store = NULL) {
  
  # Get the table-prep formula with the `tbl_source()` function
  tbl_entry <- tbl_source(tbl = tbl, store = store)
  
  # Obtain the table object
  tbl_obj <- 
    rlang::f_rhs(tbl_entry) %>%
    rlang::eval_tidy()
  
  # Add the in-store table name to the `pb_tbl_name` attribute
  # of the retrieved table
  if (
    !is.null(rlang::f_lhs(tbl_entry)) &&
    is.null(attr(tbl, "pb_tbl_name", exact = TRUE))
  ) {
    table_name <- as.character(rlang::f_lhs(tbl_entry))
    attr(tbl_obj, "pb_tbl_name") <- table_name
  }
  
  # Add the retrieval time to the `pb_tbl_name` attribute
  # of the table if it isn't present
  if (is.null(attr(tbl, "pb_access_time", exact = TRUE))) {
    
    access_time <- Sys.time()
    attr(tbl_obj, "pb_access_time") <- access_time
  }
  
  suppressWarnings(tbl_obj)
}

yaml_read_tbl_store <- function(filename) {
  
  # Read the YAML file with `yaml::read_yaml()`
  y <- yaml::read_yaml(file = filename)
  
  table_names <- names(y$tbls)
  table_formulas <- unlist(y$tbls, recursive = FALSE, use.names = FALSE)
  
  statements <- paste(table_names, table_formulas)
  
  # Generate the expression string
  expr_str <-
    paste0(
      "tbl_store(\n",
      paste(paste0("  ", statements), collapse = ",\n"), "\n",
      ")"
    )

  tbl_store <- 
    expr_str %>%
    rlang::parse_expr() %>%
    rlang::eval_tidy()
    
  tbl_store
}
