% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data_tools.R
\name{merge_datasets}
\alias{merge_datasets}
\title{Merge the dataset from ECDC with that of WB}
\usage{
merge_datasets(
  data_ECDC,
  data_WB,
  type = c("daily", "cumul"),
  baseline = c("country", "world"),
  select = c("worst_day", "last_day")
)
}
\arguments{
\item{data_ECDC}{the dataset built with \code{\link{prepare_data_ECDC}}}

\item{data_WB}{the dataset built with \code{\link{prepare_data_WB}}}

\item{type}{either \code{"daily"} (for daily deaths) or \code{"cumul"} (for cumulative deaths)}

\item{baseline}{either \code{"country"} (for correcting by the baseline mortality in the country), or \code{"world"} (for correcting all countries by the same baseline mortality)}

\item{select}{either \code{"worst_day"} (for measuring mortality at its worst) or \code{"last_day"} (for measuring mortality at the last day in the report considered)}
}
\value{
a \code{tibble} with all the raw data
}
\description{
Merge the dataset from ECDC with that of WB
}
