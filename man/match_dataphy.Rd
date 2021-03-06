% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/match_dataphy.R
\name{match_dataphy}
\alias{match_dataphy}
\title{Match data and phylogeny based on model formula}
\usage{
match_dataphy(formula, data, phy)
}
\arguments{
\item{formula}{The model formula}

\item{data}{Data frame containing species traits with row names matching tips
in \code{phy}.}

\item{phy}{A phylogeny (class 'phylo' or 'multiphylo')}
}
\value{
The function \code{match_dataphy} returns a list with the following
components:

\code{data}: Cropped dataset matching phylogeny

\code{phy}: Cropped phylogeny matching data

\code{dropped}: Species dropped from phylogeny and removed from data.
}
\description{
Combines phylogeny and data to ensure that tips in phylogeny match data and that observations
with missing values are removed. This function uses variables provided in the 
`formula` argument to:
\itemize{
 \item{Remove NA`s:   } {Check if there is any row with NA in the variables included in 
 the formula. All rows containing NA will be removed from the data}
 \item{Match data and phy:   } {Check if tips from phylogeny match rownames in
 data. Tips not present in data and phy will be removed from the phylogeny and
 data}
 \item{Return matched data and phy:   } {The returned data
 has no NA in the variables included in `formula` and only rows that match phylogeny
 tips. Returned phy has only tips that match data}
 }
 Used internally in \code{\link{samp_phylm}},\code{\link{samp_phyglm}},\code{\link{clade_phylm}},
 \code{\link{clade_phyglm}},\code{\link{intra_phylm}},\code{\link{intra_phyglm}} and \code{\link{tree_phylm}}.
 Users can also directly use this function to combine a phylogeny and a dataset.
}
\details{
This function uses all variables provided in the `formula` to match
data and phylogeny. To avoid cropping the full dataset, `match_dataphy` searches
for NA values only on variables provided by formula. Missing values on 
other variables, not included in `formula`, will not be removed from data. 

This ensures consistance between data and phylogeny only for the variables 
that are being used in the model (set by `formula`).

If phy is a 'multiphylo' object, all phylogenies will be cropped
to match data. The returned phyogeny will be a 'multiphylo' object.
}
\note{
If tips are removed from the phylogeny and data or if rows containing
missing values are removed from data, a message will be printed with the 
details. Further, the final number of species that match data and phy will
always be reported by a message.
}
\examples{
# Load data:
data(alien)
head(alien$data)
# Match data and phy based on model formula:
comp.data <- match_dataphy(gestaLen ~ homeRange, data = alien$data, alien$phy[[1]])
# Check data:
head(comp.data$data)
# Check phy:
comp.data$phy
# See species dropped from phy or data:
comp.data$dropped
# Example2:
# Match data and phy based on model formula:
comp.data2 <- match_dataphy(gestaLen ~ adultMass, data = alien$data, alien$phy)
# Check data (missing data on variables not included in the formula are preserved)
head(comp.data2$data)
# Check phy:
comp.data2$phy
# See species dropped from phy or data:
comp.data2$dropped
}
\author{
Caterina Penone & Gustavo Paterno
}
\references{
This function is largely inspired by the function \code{comparative.data} in caper package
David Orme, Rob Freckleton, Gavin Thomas, Thomas Petzoldt, Susanne Fritz, Nick Isaac and Will Pearse
(2013). caper: Comparative Analyses of Phylogenetics and Evolution in R. R package version 0.5.2.
http://CRAN.R-project.org/package=caper
}

