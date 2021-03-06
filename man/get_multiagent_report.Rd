% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/get_multiagent_report.R
\name{get_multiagent_report}
\alias{get_multiagent_report}
\title{Get a summary report using multiple agents}
\usage{
get_multiagent_report(multiagent, display_table = TRUE, title = ":default:")
}
\arguments{
\item{multiagent}{A multiagent object of class \code{ptblank_multiagent}.}

\item{display_table}{Should a display table be generated? If \code{TRUE} (the
default) a display table for the report will be shown in the Viewer. If
\code{FALSE} then a tibble will be returned.}

\item{title}{Options for customizing the title of the report. The default is
the keyword \code{":default:"} which produces generic title text. If no title is
wanted, then the \code{":none:"} keyword option can be used. Aside from keyword
options, text can be provided for the title and \code{glue::glue()} calls can be
used to construct the text string. If providing text, it will be
interpreted as Markdown text and transformed internally to HTML. To
circumvent such a transformation, use text in \code{\link[=I]{I()}} to explicitly state
that the supplied text should not be transformed.}
}
\value{
A \strong{gt} table object if \code{display_table = TRUE} or a tibble if
\code{display_table = FALSE}.
}
\description{
We can get an informative summary table from a collective of agents by using
the \code{get_multiagent_report()} function. The table can be provided in either
of two very different forms: as a \strong{gt} based display table (the default),
or, as a tibble with packed columns. The display table variant of the
multiagent report, the default form, will have the following columns:

\itemize{
\item STEP: the SHA1 hash for the validation step, possibly shared among
several interrogations.
\item \emph{subsequent columns}: each column beyond \code{STEP} represents a separate
interrogation from an \emph{agent} object. The time stamp for the completion of
each interrogation is shown as the column label.
}

Each step is represented with an icon standing in for the name of the
validation function and the associated SHA1 hash. This is a highly
trustworthy way for ascertaining which validation steps are effectively
identical across interrogations. This way of organizing the report is
beneficial because different agents may have used different steps and we want
to track the validation results where the validation step doesn't change but
the target table does.
}
\section{Function ID}{

10-3
}

\examples{
if (interactive()) {

# Let's walk through several theoretical
# data quality analyses of an extremely
# small table; that table is called
# `small_table` and we can find it as a
# dataset in this package
small_table

# To set failure limits and signal
# conditions, we designate proportional
# failure thresholds to the `warn`, `stop`,
# and `notify` states using `action_levels()`
al <- 
  action_levels(
    warn_at = 0.05,
    stop_at = 0.10,
    notify_at = 0.20
  )

# We will create four different agents
# and have slightly different validation
# steps in each of them; in the first,
# `agent_1`, eight different validation
# steps are created and the agent will
# interrogate the `small_table`
agent_1 <-
  create_agent(
    read_fn = ~ small_table,
    label = "An example.",
    actions = al
  ) \%>\%
  col_vals_gt(
    vars(date_time),
    value = vars(date),
    na_pass = TRUE
  ) \%>\%
  col_vals_gt(
    vars(b), 
    value = vars(g),
    na_pass = TRUE
  ) \%>\%
  rows_distinct() \%>\%
  col_vals_equal(
    vars(d), 
    value = vars(d),
    na_pass = TRUE
  ) \%>\%
  col_vals_between(
    vars(c), 
    left = vars(a), right = vars(d)
  ) \%>\%
  col_vals_not_between(
    vars(c),
    left = 10, right = 20,
    na_pass = TRUE
  ) \%>\%
  rows_distinct(vars(d, e, f)) \%>\%
  col_is_integer(vars(a)) \%>\%
  interrogate()

# The second agent, `agent_2`, retains
# all of the steps of `agent_1` and adds
# two more (the last of which is inactive)
agent_2 <- 
  agent_1 \%>\%
  col_exists(vars(date, date_time)) \%>\%
  col_vals_regex(
    vars(b), 
    regex = "[0-9]-[a-z]{3}-[0-9]{3}",
    active = FALSE
  ) \%>\%
  interrogate()

# The third agent, `agent_3`, adds a single
# validation step, removes the fifth one,
# and deactivates the first
agent_3 <- 
  agent_2 \%>\%
  col_vals_in_set(
    vars(f),
    set = c("low", "mid", "high")
  ) \%>\%
  remove_steps(i = 5) \%>\%
  deactivate_steps(i = 1) \%>\%
  interrogate()

# The fourth and final agent, `agent_4`,
# reactivates steps 1 and 10, and removes
# the sixth step
agent_4 <-
  agent_3 \%>\%
  activate_steps(i = 1) \%>\%
  activate_steps(i = 10) \%>\%
  remove_steps(i = 6) \%>\%
  interrogate()

# While all the agents are slightly
# different from each other, we can still
# get a combined report of them by
# creating a 'multiagent'
multiagent <-
  create_multiagent(
    agent_1, agent_2, agent_3, agent_4
  )

# Calling `multiagent` in the console
# prints the multiagent report; but we
# can get a `gt_tbl` object with the
# `get_multiagent_report(agent)` function
report <- get_multiagent_report(multiagent)

class(report)

}

}
\seealso{
Other The multiagent: 
\code{\link{create_multiagent}()},
\code{\link{read_disk_multiagent}()}
}
\concept{The multiagent}
