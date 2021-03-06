#' @title Seasonally Decomposed Missing Value Imputation 
#' 
#' @description Removes the seasonal component from the time series, performs imputation on the deseasonalized series and afterwards adds the seasonal component again.
#'  
#' @param x Numeric Vector (\code{\link{vector}}) or Time Series (\code{\link{ts}}) object in which missing values shall be replaced
#' @param algorithm Algorithm to be used after decomposition. Accepts the following input:
#' \itemize{
#'    \item{"interpolation" - Imputation by Interpolation}
#'    \item{"locf" - Imputation by Last Observation Carried Forward}
#'    \item{"mean" - Imputation by Mean Value}
#'    \item{"random" - Imputation by Random Sample}
#'    \item{"kalman" - Imputation by Kalman Smoothing and State Space Models}
#'    \item{"ma" - Imputation by Weighted Moving Average}
#'    }
#'
#' @param ... Additional parameters for these algorithms that can be passed through. Look at \code{\link[imputeTS]{na.interpolation}}, \code{\link[imputeTS]{na.locf}},
#'  \code{\link[imputeTS]{na.random}}, \code{\link[imputeTS]{na.mean}} for parameter options.
#'  
#' @return Vector (\code{\link{vector}}) or Time Series (\code{\link{ts}}) object (dependent on given input at parameter x)
#' 
#' 
#' @author Steffen Moritz
#' @seealso  \code{\link[imputeTS]{na.interpolation}},
#' \code{\link[imputeTS]{na.kalman}}, \code{\link[imputeTS]{na.locf}},
#'  \code{\link[imputeTS]{na.ma}}, \code{\link[imputeTS]{na.mean}},
#'  \code{\link[imputeTS]{na.random}}, \code{\link[imputeTS]{na.replace}},
#'  \code{\link[imputeTS]{na.seasplit}}
#' 
#' @examples
#' #Example 1: Perform seasonal imputation using algorithm = "interpolation"
#' na.seadec(tsAirgap, algorithm = "interpolation")
#' 
#' #Example 2: Perform seasonal imputation using algorithm = "mean"
#' na.seadec(tsAirgap, algorithm = "mean")
#' 
#' @import stats
#' @export

na.seadec <- function(x, algorithm = "interpolation" , ...) { 
  
  
  data <- x
  
  # Multivariate Input Handling (loop through all columns)
  # No imputation code in this part. 
  if (!is.null( dim(data)[2]) && dim(data)[2] > 1 ) {
    for (i in 1:dim(data)[2]) {
      
      if (!anyNA(data[,i])) {next}
      
      #if imputing a column does not work (mostly because it is not numeric) the column is left unchanged
      tryCatch(data[,i] <- na.seadec(data[ ,i], algorithm, ...), error=function(cond) {
        warning(paste("imputeTS: No imputation performed for column",i,"because of this",cond), call. = FALSE)
      })
    }
    return(data)
  }
  
  # Univariate Input
  # All imputation code is within this part
  else {
    
    ##
    ## Input check
    ## 
    
    missindx <- is.na(data)
    
    #Nothing to impute in the data
    if(!anyNA(data)) {
      return(data)
    }
    
    #Input completly NA
    if (all(missindx)) {
      stop("Input data has only NAs")
    }
    
    if(!is.null(dim(data)[2])&&!dim(data)[2]==1)
    {stop("Wrong input type for parameter x")}
    
    # Altering multivariate objects with 1 column (which are essentially univariate) to be dim = NULL
    if (!is.null(dim(data)[2])) {
      data <- data[,1]
    }
    
    if(!is.numeric(data))
    {stop("Input x is not numeric")}
    
    if(frequency(data)==1) {
      warning("No seasonality information for dataset found, going on without decomposition")
      data <- apply.base.algorithm(data, algorithm = algorithm,...)
      return(data)
    }
    
    if(length(data)+1 < frequency(data)*2 ) {
      warning("There should more than 2 complete periods available to use saisonal decomposition. Algorithm will go on without decomposition")
      data <- apply.base.algorithm(data, algorithm = algorithm,...)
      return(data)
    }
    
    ## End Input Check
    
    
    ##
    ## Imputation Code
    ##
  
    
    #approx NAs, to get complete series, because stl does not work with NAs
    temp <- na.interpolation(data)
    
    stl <- stl(temp,robust=TRUE, s.window = 11)
    # just take trend component + irregular  (remove seasonality)
    ts.noSeasonality <- stl$time.series[,2]+stl$time.series[,3]
    
    #Fill in NAs again
    ts.noSeasonality[missindx] <- NA
    
    #Perform imputation
    ts.imputed <- apply.base.algorithm(ts.noSeasonality, algorithm = algorithm,...)
    
    # add seasonality 
    data <- ts.imputed + stl$time.series[,1]
    
    ## End Imputation Code
    
    
    ##
    ## Ouput Formatting
    ##
    
    # Give back the object originally supplied to the function (necessary for multivariate input with only 1 column)
    if (!is.null(dim(x)[2])) {
      x[,1] <- data
      return(x)
    }
    
    return(data)
  }
}
