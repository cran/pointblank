% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/object_ops.R
\name{x_read_disk}
\alias{x_read_disk}
\title{Read a \strong{pointblank} \emph{agent} or \emph{informant} from disk}
\usage{
x_read_disk(filename, path = NULL)
}
\arguments{
\item{filename}{The name of a file that was previously written by
\code{\link[=x_write_disk]{x_write_disk()}}.}

\item{path}{An optional path to the file (combined with \code{filename}).}
}
\description{
An \emph{agent} or \emph{informant} that has been written to disk (with
\code{\link[=x_write_disk]{x_write_disk()}}) can be read back into memory with the \code{x_read_disk()}
function. Once the \emph{agent} or \emph{informant} has been generated in this way, it
may not have a data table associated with it (depending on whether the
\code{keep_tbl} option was \code{TRUE} or \code{FALSE} when writing to disk) but it should
still be able to produce reporting (by printing the \emph{agent} or \emph{informant} to
the console or using \code{\link[=get_agent_report]{get_agent_report()}}/\code{\link[=get_informant_report]{get_informant_report()}}). An
\emph{agent} will return an x-list with \code{\link[=get_agent_x_list]{get_agent_x_list()}} and yield any
available data extracts with \code{\link[=get_data_extracts]{get_data_extracts()}}. Furthermore, all of an
\emph{agent}'s validation steps will still be present (along with results from the
last interrogation).
}
\details{
Should the \emph{agent} or \emph{informant} possess a table-prep formula (can be set
any time with \code{\link[=set_read_fn]{set_read_fn()}}) or a specific table (settable with
\code{\link[=set_tbl]{set_tbl()}}) we could use the \code{\link[=interrogate]{interrogate()}} or \code{\link[=incorporate]{incorporate()}} function
again. For a \emph{data quality reporting} workflow, it is useful to
\code{\link[=interrogate]{interrogate()}} target tables that evolve over time. While the same
validation steps will be used, more can be added before calling
\code{\link[=interrogate]{interrogate()}}. For an \emph{information management} workflow with an \emph{informant}
object, using \code{\link[=incorporate]{incorporate()}} will update aspects of the reporting such as
table dimensions, and info snippets/text will be regenerated.
}
\section{Function ID}{

9-2
}

\seealso{
Other Object Ops: 
\code{\link{activate_steps}()},
\code{\link{deactivate_steps}()},
\code{\link{remove_read_fn}()},
\code{\link{remove_steps}()},
\code{\link{remove_tbl}()},
\code{\link{set_read_fn}()},
\code{\link{set_tbl}()},
\code{\link{x_write_disk}()}
}
\concept{Object Ops}
