
#' Plot a scatter plot of a binary variable.  xvar is the continuous independent variable and yvar is the dependent binary variable
#'
#' @param frame data frame to get values from
#' @param xvar name of the independent column in frame
#' @param yvar name of the dependent (output or result to be modeled) column in frame
#' @param title title to place on plot
#' @param ...  no unnamed argument, added to force named binding of later arguments.
#' @param se if TRUE, add error bars (defaults to FALSE). Ignored if useGLM is TRUE
#' @param use_glm if TRUE, "smooths" with a one-variable logistic regression (defaults to FALSE)
#' @examples
#'
#' set.seed(34903490)
#' x = rnorm(50)
#' y = 0.5*x^2 + 2*x + rnorm(length(x))
#' frm = data.frame(x=x,y=y,yC=y>=as.numeric(quantile(y,probs=0.8)))
#' frm$absY <- abs(frm$y)
#' frm$posY = frm$y > 0
#' frm$costX = 1
#' WVPlots::BinaryYScatterPlot(frm, "x", "posY",
#'    title="Example 'Probability of Y' Plot")
#'
#' @export
BinaryYScatterPlot = function(frame, xvar, yvar,  title, ...,
                              se=FALSE, use_glm=FALSE) {
  checkArgs(frame=frame,xvar=xvar,yvar=yvar,title=title,...)
  frame[[yvar]] = as.numeric(frame[[yvar]])
  if(length(unique(frame[[yvar]])) != 2) stop(paste("outcome column", yvar, "not a binary variable"))

  if(use_glm) {
    model = glm(frame[[yvar]] == max(frame[[yvar]]) ~ frame[[xvar]], family=binomial(link="logit"))
    frame$smooth = predict(model, type="response")
    ggplot2::ggplot(frame, ggplot2::aes_string(x=xvar)) +
      ggplot2::geom_point(ggplot2::aes_string(y=yvar), position=ggplot2::position_jitter(height=0.01), alpha=0.5) +
      ggplot2::geom_line(ggplot2::aes(y=smooth), color='blue') +
      ggplot2::ggtitle(title)
  } else {
    ggplot2::ggplot(frame, ggplot2::aes_string(x=xvar, y=yvar)) +
      ggplot2::geom_point(position=ggplot2::position_jitter(height=0.01), alpha=0.5) +
      ggplot2::geom_smooth(method="gam", formula=y~s(x), se=se) + ggplot2::ggtitle(title)
  }
}

# ggplot2::geom_smooth(method="gam") needs mgcv::gam.  Since ggplot2 doesn't seem
# to declare this, it errors out if we don't so declare.
#' @importFrom mgcv gam
NULL
