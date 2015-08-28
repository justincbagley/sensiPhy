#' Match data and phylogeny based on model formula
#'
#' Combine phylogeny and data to ensure that tips in phylogeny match data and that variables
#' with missing values are removed. This function uses variables provided in the 
#' `formula` argument to:
#' \itemize{
#'  \item{Remove NA`s:   } {Check if there is any row with NA in the variables included in 
#'  the formula. All rows containing NA will be removed from the data}
#'  \item{Match data and phy:   } {Check if tips from phylogeny matches rownames in
#'  data. Tips not present in data and phy will be removed from the phylogeny and
#'  data}
#'  \item{Return matched data and phy:   } {The returned data
#'  has no NA in the variables included in `formula` and only rows that match phylogeny
#'  tips. Returned phy has only tips that match data}
#'  }
#'
#' @param formula The model formula
#' @param data Data frame containing species traits with row names matching tips
#' in \code{phy}.
#' @param phy A phylogeny (class 'phylo' or 'multiphylo')
#' @return The function \code{match_dataphy} returns a list with the following
#' components:
#' @return \code{data}: Croped dataset matching phylogeny
#' @return \code{phy}: Croped phylogeny matching data
#' @details This function uses all variables provided in the `formula` to match
#' data and phylogeny. To avoid croping the full dataset, `match_dataphy` searches
#' for NA values only on variables provided by formula. Missing values on 
#' other variables, not included in `formula`, wont be removed from data. 
#' 
#' This ensures consistance between data and phylogeny only for the variables 
#' that are being used in the model (set by `formula`).
#' 
#' If phy is a 'multiphylo' object, all phylogenies will be croped
#' to match data. The returned phyogeny will be a 'multiphylo' object.
#' @note If tips are removed from the phylogeny and data or if rows containing
#' missing values are removed from data, a message will be printed with the 
#' details. Further, the final number of species that match data and phy will
#' always be informed by a message.
#' 
#' @author Caterina Penoni
#' @export
match_dataphy <- function(formula, data, phy){
    
    # original data set:
    data.0 <- data
    # Croping data frame by formula variables:
    mf <- stats::model.frame(formula = formula, data = data.0, na.action = stats::na.exclude)
    if (nrow(data.0) > nrow(mf)) warning("NA's in response or predictor,", 
                                         " rows with NA's were removed")
    
    #Match data and phylogeny in comparative.data style
    if(inherits(phy, "multiPhylo")){  
        phy1 <- phy[[1]]}
    else
        phy1<-phy
    
    tiplabl <- phy1$tip.label
    taxa.nam <- as.character(rownames(mf))
    
    in.both <- intersect(taxa.nam, tiplabl)
    
    if (length(in.both) == 0)
        stop("No tips are common to the dataset and phylogeny")
    
    mismatch <- union(setdiff(tiplabl,taxa.nam),setdiff(taxa.nam,tiplabl))
    if (length(mismatch) != 0)   warning("Some phylogeny tips do not match species in data,",
                                         "species were dropped from phylogeny",
                                         " or data")
    
    #Drop species from tree
    if(inherits(phy, "multiPhylo")){ 
        phy <- lapply(phy, ape::drop.tip,tip = mismatch)
        class(phy)<-"multiPhylo"
        tip.order <- match(phy[[1]]$tip.label, rownames(data))
    }
    if(inherits(phy, "phylo")){ 
        phy <- ape::drop.tip(phy,tip = mismatch)
        class(phy)<-"phylo"
        tip.order <- match(phy$tip.label, rownames(data))
    }
    
    if (any(is.na(tip.order)))
        stop("Problem with sorting data frame: mismatch between tip labels and data frame labels")
    data <- data[tip.order, , drop = FALSE]
    data.out <- data.0[rownames(data),]
    
    message(paste("Used dataset has ",nrow(data.out)," species that match data and phylogeny"))
    return(list(data = data.out, phy = phy))
}