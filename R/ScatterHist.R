

#' Plot a scatter plot with marginals.  xvar is the independent variable (input or model) and yvar is the dependent variable
#'
#' @param frame data frame to get values from
#' @param xvar name of the independent (input or model) column in frame
#' @param yvar name of the dependent (output or result to be modeled) column in frame
#' @param title title to place on plot
#' @param ...  no unnamed argument, added to force named binding of later arguments.
#' @param smoothmethod (optional) one of 'auto' (the default), 'lm', or 'identity'.  If smoothmethod is 'auto' or 'lm' a smoothing curve or line (respectively) is added and R-squared of the best linear fit of xvar to yvar is reported.  If smoothmethod is 'identity' then the y=x line is added and the R-squared of xvar to yvar (without the linear transform used in the other smoothmethod modes) is reported.
#' @param annot_size numeric scale annotation text (if present)
#' @param minimal_labels logical drop some annotations
#' @param binwidth_x  numeric binwidth for x histogram
#' @param binwidth_y  numeric binwidth for y histogram
#' @param adjust_x  numeric adjust x density plot
#' @param adjust_y  numeric adjust y density plot
#' @examples
#'
#' set.seed(34903490)
#' x = rnorm(50)
#' y = 0.5*x^2 + 2*x + rnorm(length(x))
#' frm = data.frame(x=x,y=y)
#' WVPlots::ScatterHist(frm, "x", "y", title="Example Fit")
#'
#' @export
ScatterHist = function(frame, xvar, yvar,title, ...,
                       smoothmethod="auto", # only works for 'auto', 'lm', and 'identity'
                       annot_size=5,
                       minimal_labels = TRUE,
                       binwidth_x = NULL,
                       binwidth_y = NULL,
                       adjust_x = 1,
                       adjust_y = 1) {
  checkArgs(frame=frame,xvar=xvar,yvar=yvar,title=title,...)
  if(!(smoothmethod %in% c('auto','lm','identity'))) {
    stop("smoothed method must be one of 'auto','lm', or 'identity'")
  }

  # placeholder plot - prints nothing at all
  empty =  ggplot2::ggplot() +
    ggplot2::geom_point(ggplot2::aes(c(0,1), c(0,1)), colour = "white") +
    ggplot2::theme(plot.background = ggplot2::element_blank(),
          panel.grid.major = ggplot2::element_blank(),
          panel.grid.minor = ggplot2::element_blank(),
          panel.border = ggplot2::element_blank(),
          panel.background = ggplot2::element_blank(),
          axis.title.x = ggplot2::element_blank(),
          axis.title.y = ggplot2::element_blank(),
          axis.text.x = ggplot2::element_blank(),
          axis.text.y = ggplot2::element_blank(),
          axis.ticks = ggplot2::element_blank(),
          plot.margin = grid::unit(c(1, 1, 0, 0), "lines"))

  # if we are showing a linear fit, print the fit's parameters
  gSmooth = NULL
  if(smoothmethod=='auto') {
    gSmooth = ggplot2::geom_smooth(method=smoothmethod)
  } else if(smoothmethod=="lm") {
    tryCatch({
    # get goodness of linear relation
    model = lm(paste(yvar,"~",xvar), data=frame)
    fstat = summary(model)$fstatistic
    rsqr = summary(model)$r.squared
    pval = pf(fstat[["value"]], fstat[["numdf"]], fstat[["dendf"]], lower.tail=FALSE)

    # print(summary(model))
    fitstring = paste("R-squared = ", format(rsqr, digits=3))
    sigstring = paste("Significance = ", format(pval, digits=3))

    empty = empty + ggplot2::annotate("text", x=0.5, y=0.75, label=fitstring, size=annot_size) +
      ggplot2::annotate("text", x=0.5, y=0.5, label=sigstring, size=annot_size)},
    error=function(x){})
    gSmooth = ggplot2::geom_smooth(method=smoothmethod)
  } else if(smoothmethod=='identity') {
    meanY = mean(frame[[yvar]])
    rsqr = 1 - sum((frame[[yvar]]-frame[[xvar]])^2)/sum((frame[[yvar]]-meanY)^2)
    fitstring = paste("R-squared = ", format(rsqr, digits=3))

    empty = empty + ggplot2::annotate("text", x=0.5, y=0.75, label=fitstring, size=annot_size)
    gSmooth = ggplot2::geom_abline(slope=1,linetype=2,color='blue')
  }

  # scatterplot of x and y
  plot_center = ggplot2::ggplot(frame, ggplot2::aes_string(x=xvar,y=yvar)) +
    ggplot2::geom_point(alpha=0.5) +
    ggplot2::theme(plot.margin = grid::unit(c(0, 0, 0, 0), "lines"))
  if(!is.null(gSmooth)) {
    plot_center = plot_center + gSmooth
  }

  # get the data range, to help align plots
  x = frame[[xvar]]
  y = frame[[yvar]]
  xlims =  c(min(x), max(x))
  ylims =  c(min(y), max(y))

  #  print(xlims)
  # print(ggplot_build(plot_center)$panel$ranges[[1]]$x.range)

  plot_center = plot_center + ggplot2::xlim(xlims)

  # print(ggplot_build(plot_center)$panel$ranges[[1]]$x.range)

  # marginal density of x - plot on top
  #
  # 0,0,0,0 -- title squooshed down
  # 1,0,0,0 -- title has space
  # 0,1,0,0 -- right side is shorter
  # 0,0,1,0 -- bottom gap bigger
  # 0,0,0,1 -- left side is shorter
  #
  plot_top <- ggplot2::ggplot(frame, ggplot2::aes_string(x=xvar)) +
    ggplot2::geom_histogram(ggplot2::aes(y=..density..), fill="gray",
                   color="white", binwidth=binwidth_x) +
    ggplot2::geom_line(stat='density',color="blue", adjust=adjust_x) +
    ggplot2::xlim(xlims)
  if(minimal_labels) {
    plot_top = plot_top +
      ggplot2::theme(legend.position = "none",
                     axis.title.x = ggplot2::element_blank(),
            axis.text.x = ggplot2::element_blank(),
            axis.ticks.x = ggplot2::element_blank(),
            plot.margin = grid::unit(c(1, 0, 0, 0), "lines"))
  } else {
    plot_top = plot_top +
      ggplot2::theme(plot.margin = grid::unit(c(1, 0, 0, 0), "lines"))
  }


  # marginal density of y - plot on the right
  plot_right <- ggplot2::ggplot(frame, ggplot2::aes_string(x=yvar)) +
    ggplot2::geom_histogram(ggplot2::aes(y=..density..), fill="gray",
                   color="white", binwidth=binwidth_y) +
    ggplot2::geom_line(stat='density',color="blue", adjust=adjust_y) +
    ggplot2::xlim(ylims) +
    ggplot2::coord_flip()
  if(minimal_labels) {
    plot_right = plot_right +
      ggplot2::theme(legend.position = "none",
                     axis.title.y = ggplot2::element_blank(),
            axis.text.y = ggplot2::element_blank(),
            axis.ticks.y = ggplot2::element_blank(),
            plot.margin = grid::unit(c(0, 1, 0, 0), "lines"))
  } else {
    plot_right = plot_right +
      ggplot2::theme(plot.margin = grid::unit(c(0, 1, 0, 0), "lines"))
  }

  yPadFn <- designYLabelPadFunction(plot_center + ggplot2::ylim(ylims),plot_top)
  plot_center <- plot_center + ggplot2::scale_y_continuous(limits=ylims,label=yPadFn)
  plot_top <- plot_top + ggplot2::scale_y_continuous(label=yPadFn)

  # arrange the plots together, with appropriate height and width
  # for each row and column

  gridExtra::grid.arrange(plot_top, empty, plot_center, plot_right,
               top=grid::textGrob(title),
               ncol = 2, nrow = 2, widths = c(4,1), heights = c(1, 4))
}
