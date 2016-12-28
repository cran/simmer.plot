## ---- echo = FALSE, message = FALSE--------------------------------------
knitr::opts_chunk$set(collapse = T, comment = "#>", 
                      fig.width = 6, fig.height = 8, fig.align = "center")

## ---- message=FALSE------------------------------------------------------
library(simmer.plot)

t0 <- trajectory() %>%
  seize("resource", 1) %>%
  timeout(function() rnorm(1, 15)) %>%
  release("resource", 1) %>%
  branch(function() 1, c(TRUE, FALSE),
         trajectory() %>%
           clone(2,
                 trajectory() %>%
                   seize("resource", 1) %>%
                   timeout(1) %>%
                   release("resource", 1),
                 trajectory() %>%
                   trap("signal",
                        handler=trajectory() %>%
                          timeout(1)) %>%
                   timeout(1)),
         trajectory() %>%
           set_attribute("dummy", 1) %>%
           set_attribute("dummy", function() 1) %>%
           seize("resource", function() 1) %>%
           timeout(function() rnorm(1, 20)) %>%
           release("resource", function() 1) %>%
           rollback(9)) %>%
  timeout(1) %>%
  rollback(2)

plot(t0)

## ---- message=FALSE------------------------------------------------------
cat(plot(t0, output="DOT"))
