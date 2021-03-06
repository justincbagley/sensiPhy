#' Influential clade detection - Phylogenetic Logistic Regression
#'
#' Estimate the impact on model estimates of phylogenetic logistic regression after 
#' removing clades from the analysis. 
#'
#' @param formula The model formula
#' @param data Data frame containing species traits with row names matching tips
#' in \code{phy}.
#' @param phy A phylogeny (class 'phylo') matching \code{data}.
#' @param btol Bound on searching space. For details see \code{phyloglm}
#' @param track Print a report tracking function progress (default = TRUE)
#' @param clade.col The name of a column in the provided data frame with clades 
#' specification (a character vector with clade names).
#' @param n.species Minimum number of species in the clade in order to include
#' this clade in the leave-one-out deletion analyis. Default is \code{5}.
#' @param times Number of simulations for the randomization test.
#' @param ... Further arguments to be passed to \code{phyloglm}
#' 
#' @details
#' Currently only logistic regression using the "logistic_MPLE"-method from
#' \code{phyloglm} is implemented.
#'
#' \code{clade_phyglm} detects influential clades based on
#' difference in intercept and/or slope when removing a given clade compared
#' to the full model including all species.
#' 
#' #' Additionally, to account for the influence of the number of species on each 
#' clade (clade sample size), this function also estimate a null distribution of slopes
#' expected for the number of species in a given clade. This is done by fitting
#'  models without the same number of species in the given clade. 
#'  The number of simulations to be performed is set by 'times'. To test if the 
#'  clade influence differs from the null expectation, a randomization test can
#'  be performed using 'summary(x)'. 
#' 
#' Currently, this function can only implement simple linear models (i.e. 
#' \eqn{y = a + bx}). In the future we will implement more complex models.
#'
#' Output can be visualised using \code{sensi_plot}.
#'
#' @return The function \code{clade_phyglm} returns a list with the following
#' components:
#' @return \code{formula}: The formula
#' @return \code{full.model.estimates}: Coefficients, aic and the optimised
#' value of the phylogenetic parameter (e.g. \code{alpha}) for the full model
#' without deleted species.
#' @return \code{clade.model.estimates}: A data frame with all simulation
#' estimates. Each row represents a deleted clade. Columns report the calculated
#' regression intercept (\code{intercept}), difference between simulation
#' intercept and full model intercept (\code{DFintercept}), the percentage of change
#' in intercept compared to the full model (\code{intercept.perc}) and intercept
#' p-value (\code{pval.intercept}). All these parameters are also reported for the regression
#' slope (\code{DFslope} etc.). Additionally, model aic value (\code{AIC}) and
#' the optimised value (\code{optpar}) of the phylogenetic parameter are
#' reported.
#' @return \code{data}: Original full dataset.
#' @return \code{errors}: Clades where deletion resulted in errors.
#' @author Gustavo Paterno & Gijsbert Werner
#' @seealso \code{\link[phylolm]{phyloglm}}, \code{\link[sensiPhy]{clade_phylm}},
#'  \code{\link{influ_phyglm}}, \code{\link{sensi_plot}}
#' @references Ho, L. S. T. and Ane, C. 2014. "A linear-time algorithm for 
#' Gaussian and non-Gaussian trait evolution models". Systematic Biology 63(3):397-408.
#' @examples 
#' \dontrun{
#'# Simulate Data:
#'set.seed(6987)
#'phy = rtree(150)
#'x = rTrait(n=1,phy=phy)
#'X = cbind(rep(1,150),x)
#'y = rbinTrait(n=1,phy=phy, beta=c(-1,0.5), alpha=.7 ,X=X)
#'cla <- rep(c("A","B","C","D","E"), each = 30)
#'dat = data.frame(y, x, cla)
#'# Run sensitivity analysis:
#'clade <- clade_phyglm(y ~ x, phy = phy, data = dat, times = 30, clade.col = "cla")
#'# To check summary results and most influential clades:
#'summary(clade)
#'# Visual diagnostics for clade removal:
#'sensi_plot(clade)
#'# Specify which clade removal to plot:
#'sensi_plot(clade, "B")
#'sensi_plot(clade, "C")
#'sensi_plot(clade, "D") #The clade with the largest effect on slope and intercept
#'}
#' @export

clade_phyglm <- function(formula, data, phy, btol=50, track = TRUE,
                         clade.col, n.species = 5, times = 100,  ...){
  # To check summary results and most influential clades:
  
  
  # Error checking:
  if(!is.data.frame(data)) stop("data must be class 'data.frame'")
  if(missing(clade.col)) stop("clade.col not defined. Please, define the",
                              " column with clade names.")
  if(class(phy)!="phylo") stop("phy must be class 'phylo'")
  
  #Calculates the full model, extracts model parameters
  data_phy <- match_dataphy(formula, data, phy)
  phy <- data_phy$phy
  full.data <- data_phy$data
  if (is.na(match(clade.col, names(full.data)))) {
    stop("Names column '", clade.col, "' not found in data frame'")
  }
  
  # Identify CLADES to use and their sample size 
  all.clades <- levels(full.data[ ,clade.col])
  wc <- table(full.data[ ,clade.col]) > n.species
  uc <- table(full.data[ , clade.col])[wc]
  
  #k <- names(which(table(full.data[,clade.col]) > n.species ))
  if (length(uc) == 0) stop(paste("There is no clade with more than ",
                                  n.species," species. Change 'n.species' to fix this
                                  problem",sep=""))
  
  # FULL MODEL PARAMETERS:
  N               <- nrow(full.data)
  mod.0           <- phylolm::phyloglm(formula, data = full.data, 
                                       phy = phy, method = "logistic_MPLE",
                                       btol = btol)
  intercept.0      <- mod.0$coefficients[[1]]
  slope.0          <- mod.0$coefficients[[2]]
  pval.intercept.0 <- phylolm::summary.phylolm(mod.0)$coefficients[[1,4]]
  pval.slope.0     <- phylolm::summary.phylolm(mod.0)$coefficients[[2,4]]
  optpar.0 <- mod.0$optpar
  
  if(isTRUE(mod.0$convergence!=0)) stop("Full model failed to converge,
                                        consider changing btol. See ?phyloglm")
  
  #Create dataframe to store estmates for each clade
  clade.model.estimates <-
    data.frame("clade" =I(as.character()), 
               "N.species" = numeric(),"intercept"=numeric(),
               "DFintercept"=numeric(),"intercept.perc"=numeric(),
               "pval.intercept"=numeric(),"slope"=numeric(),
               "DFslope"=numeric(),"slope.perc"=numeric(),
               "pval.slope"=numeric(),"AIC"=numeric(),
               "optpar" = numeric())
  
  # Create dataframe store simulations (null distribution)
  null.dist <- data.frame("clade" = rep(names(uc), each = times),
                          "intercept"= numeric(length(uc)*times),
                          "slope" = numeric(length(uc)*times),
                          "DFintercept"=numeric(length(uc)*times),
                          "DFslope"=numeric(length(uc)*times))
  
  
  ### START LOOP between CLADES:
  # counters:
  aa <- 1; bb <- 1
  errors <- NULL
  
  pb <- utils::txtProgressBar(min = 0, max = length(uc)*times,
                              style = 1)
  for (A in names(uc)){
    
    ### Number of species in clade A
    cN  <- as.numeric(uc[names(uc) == A])
    
    ### Fit reduced model (without clade)
    crop.data <- full.data[!full.data[ ,clade.col] %in% A,]
    crop.sp <-   which(full.data[ ,clade.col] %in% A)
    crop.phy <-  ape::drop.tip(phy,phy$tip.label[crop.sp])
    mod=try(phylolm::phyloglm(formula, data = crop.data, 
                              phy = crop.phy, method = "logistic_MPLE",
                              btol = btol), TRUE)
    intercept            <- mod$coefficients[[1]]
    slope                <- mod$coefficients[[2]]
    DFintercept          <- intercept - intercept.0
    DFslope              <- slope - slope.0
    intercept.perc       <- round((abs(DFintercept / intercept.0)) * 100,
                                  digits = 1)
    slope.perc           <- round((abs(DFslope / slope.0)) * 100,
                                  digits = 1)
    pval.intercept       <- phylolm::summary.phylolm(mod)$coefficients[[1,4]]
    pval.slope           <- phylolm::summary.phylolm(mod)$coefficients[[2,4]]
    aic.mod              <- mod$aic
    optpar          <- mod$alpha
    
    
    # Store reduced model parameters: 
    estim.simu <- data.frame(A, cN, intercept, DFintercept, intercept.perc,
                             pval.intercept, slope, DFslope, slope.perc,
                             pval.slope, aic.mod, optpar,
                             stringsAsFactors = F)
    clade.model.estimates[aa, ]  <- estim.simu
    
    ### START LOOP FOR NULL DIST:
    # number of species in clade A:
    for (i in 1:times) {
      exclude <- sample(1:N, cN)
      crop.data <- full.data[-exclude,]
      crop.phy <-  ape::drop.tip(phy,phy$tip.label[exclude])
      mod=try(phylolm::phyloglm(formula, data = crop.data, 
                                phy = crop.phy, method = "logistic_MPLE",
                                btol = btol), TRUE)
      intercept      <- mod$coefficients[[1]]
      slope          <- mod$coefficients[[2]]
      DFintercept          <- intercept - intercept.0
      DFslope              <- slope - slope.0
      
      null.dist[bb, ]  <- data.frame(clade = as.character(A), 
                                     intercept,
                                     slope,
                                     DFintercept,
                                     DFslope)
      
      if(track==TRUE) utils::setTxtProgressBar(pb, bb)
      bb <- bb + 1
    }
    aa <- aa + 1
  }
  on.exit(close(pb))
  
  #OUTPUT
  #full model estimates:
  param0 <- list(coef=phylolm::summary.phylolm(mod.0)$coefficients,
                 aic=phylolm::summary.phylolm(mod.0)$aic,
                 optpar=mod.0$optpar)
  
  #Generates output:
  res <- list(call = match.call(),
              formula = formula,
              full.model.estimates = param0,
              clade.model.estimates = clade.model.estimates,
              null.dist = null.dist, 
              data = full.data,
              errors = errors,
              clade.col = clade.col)
  class(res) <- c("sensiClade","sensiCladeL")
  ### Warnings:
  if (length(res$errors) >0){
    warning("Some clades deletion presented errors, please check: output$errors")}
  else {
    res$errors <- "No errors found."
  }
  return(res)
}

