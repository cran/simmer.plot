#' Plot method for simmer objects
#'
#' A method for the \code{\link{plot}} generic. There are three kinds of plots with different
#' metrics available:
#' \itemize{
#'   \item Plot of resources. Two metrics available: \itemize{
#'     \item the usage of a resource over the simulation time frame.
#'     \item the utilization of specified resources in the simulation.
#'   }
#'   \item Plot of arrivals. Three metrics available: \itemize{
#'     \item activity time.
#'     \item waiting time.
#'     \item flow time.
#'   }
#'   \item Plot of attributes.
#' }
#'
#' @param x a single simmer environment or a list of environments representing several replications.
#' @param what type of plot, one of \code{c("resources", "arrivals", "attributes")}.
#' @param metric specific metric for each type of plot.
#' \describe{
#'   \item{\code{what = "resources"}}{one of \code{c("usage", "utilization")}.}
#'   \item{\code{what = "arrivals"}}{one of \code{c("activity_time", "waiting_time", "flow_time")}.}
#'   \item{\code{what = "attributes"}}{no metrics at the moment.}
#' }
#' @param ... further arguments for each kind of plot.
#' \describe{
#'   \item{\code{what = "resources"}}{\describe{
#'     \item{all metrics}{\describe{
#'       \item{\code{names}}{the name of the resource(s) (a single string or a character
#'       vector) to show.}
#'     }}
#'     \item{\code{metric = "usage"}}{\describe{
#'       \item{\code{items}}{the components of the resource to be plotted, one or more
#'       of \code{c("system", "queue", "server")}.}
#'       \item{\code{steps}}{adds the changes in the resource usage.}
#'     }}
#'   }}
#'   \item{\code{what = "attributes"}}{\describe{
#'     \item{keys}{the keys of attributes you want to plot (if left empty, all attributes are shown).}
#'   }}
#' }
#'
#' @return Returns a ggplot2 object.
#' @import simmer ggplot2
#' @importFrom graphics plot
#' @export
#'
#' @examples
#' t0 <- trajectory("my trajectory") %>%
#'   ## add an intake activity
#'   seize("nurse", 1) %>%
#'   timeout(function() rnorm(1, 15)) %>%
#'   release("nurse", 1) %>%
#'   ## add a consultation activity
#'   seize("doctor", 1) %>%
#'   timeout(function() rnorm(1, 20)) %>%
#'   release("doctor", 1) %>%
#'   ## add a planning activity
#'   seize("administration", 1) %>%
#'   timeout(function() rnorm(1, 5)) %>%
#'   release("administration", 1)
#'
#' env <- simmer("SuperDuperSim") %>%
#'   add_resource("nurse", 1) %>%
#'   add_resource("doctor", 2) %>%
#'   add_resource("administration", 1) %>%
#'   add_generator("patient", t0, function() rnorm(1, 10, 2))
#'
#' env %>% run(until=80)
#'
#' plot(env, what="resources", metric="usage", "doctor", items = "server", steps = TRUE)
#' plot(env, what="resources", metric="utilization", c("nurse", "doctor", "administration"))
#' plot(env, what="arrivals", metric="waiting_time")
#'
plot.simmer <- function(x, what=c("resources", "arrivals", "attributes"), metric=NULL, ...) {
  what <- match.arg(what)
  dispatch_next(what, x, metric, ...)
}

#' @export
plot.wrap <- function(x, ...) plot.simmer(x, ...)

#' @export
plot.list <- function(x, ...) {
  if (length(class(x)) == 1) {
    stopifnot(all(class(x[[1]]) == sapply(x, class)))
    plot_list_proxy(x, ...)
  } else NextMethod()
}

plot_list_proxy <- function(x, ...) {
  if (all(sapply(x, inherits, class(x[[1]]))))
    class(x) <- c(class(x), class(x[[1]]))
  plot(x, ...)
}

dispatch_next <- function(.next, ...) {
  caller <- match.call(sys.function(-1), sys.call(-1))
  caller <- as.character(caller)[[1]]
  caller <- strsplit(caller, ".", fixed = TRUE)[[1]][[1]]
  do.call(paste0(caller, "_", .next), list(...))
}