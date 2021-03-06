% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/getDEE2.R
\name{getDEE2}
\alias{getDEE2}
\title{Get DEE2 Gene Expression Data}
\usage{
getDEE2(
  species,
  SRRvec,
  outfile = NULL,
  metadata = NULL,
  baseURL = "http://dee2.io/cgi-bin/request.sh?",
  ...
)
}
\arguments{
\item{species}{A character string matching the species of interest.}

\item{SRRvec}{A character string or vector of SRA run accession numbers}

\item{outfile}{An optional file name for the downloaded dataset.}

\item{metadata}{An optional file name for the meta data}

\item{baseURL}{The base URL of the service. Leave this as the default URL
unless you want to download from a 3rd party mirror.}

\item{...}{Additional parameters to be passed to download.file.}
}
\value{
a getDEE2 object.
}
\description{
This function fetches gene expression data from the DEE2 database of RNA
sequencing data.
}
\examples{
x<-getDEE2("ecoli",c("SRR1613487","SRR1613488"))
}
\keyword{DEE2}
\keyword{RNA-seq}
\keyword{database}
