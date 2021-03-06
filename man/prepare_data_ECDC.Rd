% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data_ECDC.R
\name{prepare_data_ECDC}
\alias{prepare_data_ECDC}
\title{Download and prepare the data from the European Centre for Diseases Prevention and Control}
\usage{
prepare_data_ECDC(date_of_report = Sys.Date(), path_save_data = NULL)
}
\arguments{
\item{date_of_report}{the date of the report to download and process (of format Date)}

\item{path_save_data}{the path where to save the data file (without trailing "/")}
}
\value{
a tidy ECDC dataset
}
\description{
Download and prepare the data from the European Centre for Diseases Prevention and Control
}
