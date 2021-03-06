#' Graphical diagnostics for class 'sensiInflu'
#'
#' \code{plot_influ_phylm} Plot results from \code{influ_phylm} and 
#' \code{influ_phyglm}
#' @param x output from \code{influ_phylm}
#' @param graphs choose which graph should be printed on the output ("all", 1,2,3 or 4)
#' @param param choose which parameter ("intercept" or "slope" should be printed)
#' @param ... further arguments to methods
#' @importFrom ggplot2 aes geom_histogram geom_density geom_vline 
#' xlab theme element_text geom_point scale_colour_gradient element_rect ylab xlab
#' ggtitle element_blank
#' @author Gustavo Paterno
#' @seealso \code{\link[ggplot2]{ggplot}}
#' @details For 'x' from influ_phylm or influ_phyglm:
#' 
#' Graph 1: Distribution of estimated slopes or intercepts for each 
#' simulation (leave-one-out deletion). Red vertical line represents the original
#' slope or intercept from the full model (with all species). 
#' 
#' Graph 2: Original regression plot (\eqn{trait~predictor}). Standardized 
#' difference in slope or intercept is represented by a continous size scale. 
#' The names of the most influential species (sDF > cutoff) are ploted in the
#' graph. 
#' 
#' Graph 3: Distribution of standardized difference in slope or intercept. Red 
#' colour indicates inbfluential species (with a standardised difference above 
#' the value of \code{cutoff}).
#' 
#' Graph 4: Distribution of the percentage of change in slope or intercept.
#' @importFrom grid unit 
#' @export

### Start:
sensi_plot.sensiInflu <- function(x, graphs="all", param="slope", ...){

# nulling variables:------------------------------------------------------------
slope <- ..density.. <- intercept <- sDFslope <- slope.perc <- NULL 
intercept.perc <- sDFintercept <- species <-  NULL
        
        ### Organizing values:
        result <- x$influ.model.estimates
        mappx <- x$formula[[3]]
        mappy <- x$formula[[2]]
        vars <- all.vars(x$formula)
        intercept.0 <-  as.numeric(x$full.model.estimates$coef[1])
        slope.0     <-  as.numeric(x$full.model.estimates$coef[2])
        cutoff      <-  x$cutoff

        ### Removing species with error:
        if (isTRUE(class(x$errors) != "character" )){
                x$data <- x$data[-as.numeric(x$errors),]
        }
        result.tab <- data.frame(x$influ.model.estimates,x$data[all.vars(x$formula)])

        ### Plots:
        # Distribution of estimated slopes:
        s1 <- ggplot2::ggplot(result,aes(x=slope))+
                geom_histogram(fill="yellow",colour="black", size=.2,
                               alpha = .3) +
                geom_vline(xintercept = slope.0,color="red",linetype=2,size=.7)+
                xlab("Estimated slopes")+
                ylab("Frequency")+
                theme(axis.title=element_text(size=12),
                    axis.text = element_text(size=12),
                    panel.background = element_rect(fill="white",
                                                  colour="black"))
        
        # Distribution of estimated intercepts:
        i1 <- ggplot2::ggplot(result,aes(x=intercept))+
                geom_histogram(fill="yellow",colour="black", size=.2,
                               alpha = .3) +
                geom_vline(xintercept = intercept.0,color="red",linetype=2,size=.7)+
                xlab("Estimated Intercepts")+
                ylab("Frequency")+
                theme(axis.title=element_text(size=12),
                    axis.text = element_text(size=12),
                    panel.background = element_rect(fill="white",
                                                  colour="black"))
        
        # Original plot with Standardized DFslope as colour gradient
        s2 <- ggplot2::ggplot(result.tab, aes_string(y = mappy, x = mappx),
                              environment = environment())+
            geom_point(data = result.tab,
                       aes(size = abs(sDFslope)), alpha = .8)+
            ggplot2::scale_size_continuous(name = "|sDF|", range = c(1, 6))+
            ggplot2::geom_text(aes(label =  ifelse(abs(sDFslope) > cutoff, 
                                  as.character(species), ""),
                        vjust = 0, hjust = 0,
                        color = "red", size = .7), show.legend = F,
                        fontface = "bold") + 
            theme(legend.key.width = unit(.2,"cm"),
                  panel.background=element_rect(fill="white", colour = "black"),
                  legend.text = element_text(size = 12),
                  panel.grid.major = element_blank(),
                  panel.grid.minor = element_blank())+
            scale_x_continuous(expand = c(.2, .2)) +
            ggtitle("Standardized Difference in slope")+
            theme(axis.title = element_text(size = 12),
                  axis.text = element_text(size = 12),
                  panel.background = element_rect(fill = "white",
                                                  colour = "black"))
             
        # Original plot with Standardized DFintercept as size gradient
        i2<-ggplot2::ggplot(result.tab,aes_string(y = mappy, x = mappx),
                            environment = environment())+
            geom_point(data = result.tab,
                       aes(size = abs(sDFintercept)), alpha = .8)+
            ggplot2::scale_size_continuous(name = "sDF", range = c(1, 6))+
            ggplot2::geom_text(aes(label = ifelse(abs(sDFintercept) > cutoff, 
                                                as.character(species), ""), 
                                 vjust = 0, hjust = 0, color = "red",
                                 size = .7), show.legend = F,  fontface = "bold") +
            theme(legend.key.width = unit(.2,"cm"),
                  panel.background=element_rect(fill="white",colour="black"),
                  legend.text = element_text(size=12),
                  panel.grid.major = element_blank(),
                  panel.grid.minor = element_blank())+
          scale_x_continuous(expand = c(.2, .2)) +
            ggtitle("Standardized Difference in Intercept")+
            theme(axis.title=element_text(size=12),
                  axis.text = element_text(size=12),
                  panel.background = element_rect(fill="white",
                                                  colour="black"))

        # Influential points for slope estimate
        s3 <- ggplot2::ggplot(result,aes(x=sDFslope))+
                geom_histogram(fill="red",color="black",binwidth=.5) +
                xlab("Standardized Difference in Slope")+
                ylab("Frequency")+
                geom_histogram(data=subset(result,sDFslope<cutoff&sDFslope>-cutoff),
                               colour="black", fill="white",binwidth=.5)+
                geom_vline(xintercept = -cutoff,color="red",linetype=2,size=.7)+
                geom_vline(xintercept = cutoff,color="red",linetype=2,size=.7)+
                theme(axis.title=element_text(size=12),
                    axis.text = element_text(size=12),
                    panel.background = element_rect(fill="white",
                                                  colour="black"))

        # Influential points for intercept estimate
        i3 <- ggplot2::ggplot(result,aes(x=sDFintercept))+
                geom_histogram(fill="red",color="black",binwidth=.5) +
                xlab("Standardized Difference in Intercept")+
                ylab("Frequency")+
                geom_histogram(data=subset(result,sDFslope<cutoff&sDFslope>-cutoff),
                               colour="black", fill="white",binwidth=.5)+
                geom_vline(xintercept = -cutoff,color="red",linetype=2,size=.7)+
                geom_vline(xintercept = cutoff,color="red",linetype=2,size=.7)+
                theme(axis.title=element_text(size=12),
                    axis.text = element_text(size=12),
                    panel.background = element_rect(fill="white",
                                              colour="black"))                

        # Distribution of slope.perc:

        s4 <- ggplot2::ggplot(result,aes(x=slope.perc,y=..density..))+
                geom_histogram(data = result,
                               colour="black", fill="yellow",
                               alpha = .3)+
                xlab("% of change in Slope")+
                ylab("Frequency") +
                theme(axis.title=element_text(size=12),
                       axis.text = element_text(size=12),
                       panel.background = element_rect(fill="white",
                                                       colour="black"))

        # Distribution of slope.perc:
        i4 <- ggplot2::ggplot(result,aes(x=intercept.perc,y=..density..))+
                geom_histogram(
                              colour="black", fill="yellow",
                              alpha = .3)+
                xlab("% of change in Intercept")+
                ylab("Frequency")+
                theme(axis.title=element_text(size=12),
                    axis.text = element_text(size=12),
                    panel.background = element_rect(fill="white",
                                                  colour="black"))

        ### Plotting:
        if (param == "slope" & graphs == "all")
            suppressMessages(return(multiplot(s1, s3, s2, s4, cols = 2)))
        if (param == "slope" & graphs == 1)
            suppressMessages(return(s1))
        if (param == "slope" & graphs == 2)
            suppressMessages(return(s2))
        if (param == "slope" & graphs == 3)
            suppressMessages(return(s3))
        if (param == "slope" & graphs == 4)
            suppressMessages(return(s4))
        if (param == "intercept" & graphs == "all")
            suppressMessages(return(multiplot(i1, i3, i2, i4, cols = 2)))
        if (param == "intercept" & graphs == 1)
            suppressMessages(return(i1))
        if (param == "intercept" & graphs == 2)
            suppressMessages(return(i2))
        if (param == "intercept" & graphs == 3)
            suppressMessages(return(i3))
        if (param == "intercept" & graphs == 4)
            suppressMessages(return(i4))

        ### Warnings
        if (isTRUE(class(x$errors) != "character" ))
                warnings("Deletion of some species caused error. These species were not ploted")

}

