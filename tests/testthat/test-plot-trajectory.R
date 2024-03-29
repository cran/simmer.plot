test_graph <- function(x, name, from, to) {
  expect_true(inherits(plot(x), "htmlwidget"))
  graph <- trajectory_graph(x, scales::brewer_pal("qual"))
  expect_true(inherits(graph, "dgr_graph"))

  nodes_df <- dplyr::arrange(graph$nodes_df, .data$id)
  edges_df <- dplyr::arrange(graph$edges_df, .data$from, .data$to)
  expect_equal(nodes_df$label, name)
  expect_equal(edges_df$from, from)
  expect_equal(edges_df$to, to)
}

test_that("a null trajectory fails", {
  expect_error(plot(trajectory()))
})

test_that("a single-node trajectory is correctly converted to graph", {
  x <- trajectory() %>%
    timeout(1)

  test_graph(x, c("Timeout"), integer(0), integer(0))
})

test_that("a simple trajectory is correctly converted to graph", {
  x <- trajectory() %>%
    seize("res", 1) %>%
    release("res", 1)

  test_graph(x, c("Seize", "Release"), 1, 2)
})

test_that("a rollback with variable amount is correctly converted to graph", {
  test_graph(trajectory() %>% rollback(0), c("Rollback"), 1, 1)
  test_graph(trajectory() %>% rollback(1), c("Rollback"), 1, 1)
  test_graph(trajectory() %>% rollback(Inf), c("Rollback"), 1, 1)
  test_graph(trajectory() %>% timeout(1) %>% rollback(0), c("Timeout", "Rollback"), c(1, 2), c(2, 2))
  test_graph(trajectory() %>% timeout(1) %>% rollback(1), c("Timeout", "Rollback"), c(1, 2), c(2, 1))
  test_graph(trajectory() %>% timeout(1) %>% rollback(2), c("Timeout", "Rollback"), c(1, 2), c(2, 1))
  test_graph(trajectory() %>% timeout(1) %>% rollback(Inf), c("Timeout", "Rollback"), c(1, 2), c(2, 1))
})

test_that("a rollback with tag is correctly converted to graph", {
  skip_if(packageVersion("simmer") <= "4.4.5")

  x <- trajectory() %>%
    timeout(1, tag="foo") %>%
    timeout(2, tag="foo") %>%
    timeout(3) %>%
    rollback("foo", tag="bar")

  test_graph(x,
             c("Timeout [foo]", "Timeout [foo]", "Timeout", "Rollback [bar]"),
             c(1, 2, 3, 4),
             c(2, 3, 4, 2))
})

test_that("a complex trajectory is correctly converted to graph", {
  x <- trajectory() %>%
    seize("res0", 1) %>%
    branch(function() 1, c(TRUE, FALSE),
           trajectory() %>%
             clone(2,
                   trajectory() %>%
                     seize("res1", 1) %>%
                     timeout(1) %>%
                     release("res1", 1),
                   trajectory() %>%
                     trap("signal",
                          handler=trajectory() %>%
                            timeout(1)) %>%
                     timeout(1)),
           trajectory() %>%
             set_attribute("dummy", 1) %>%
             seize("res2", function() 1) %>%
             timeout(function() rnorm(1, 20)) %>%
             release("res2", function() 1) %>%
             release("res0", 1) %>%
             rollback(11)) %>%
    synchronize() %>%
    rollback(2) %>%
    release("res0", 1)

  activities <- c("Seize", "Branch", "Clone", "Seize", "Timeout", "Release", "Trap",
                  "Timeout", "Timeout", "SetAttribute", "Seize", "Timeout", "Release",
                  "Release", "Rollback", "Synchronize", "Rollback", "Release")
  from <- c(1, 2, 2, 2, 3, 3, 4, 5, 6, 7, 7, 9, 10, 11, 12, 13, 14, 15, 16, 17, 17)
  to <- c(2, 3, 10, 16, 4, 7, 5, 6, 16, 8, 9, 16, 11, 12, 13, 14, 15, 1, 17, 2, 18)

  if (packageVersion("simmer") >= "4.2.2") {
    # connect the Timeout back to the Handler
    pos <- 1:11
    from <- c(from[pos], 8, from[-pos])
    to <- c(to[pos], 7, to[-pos])
  }

  test_graph(x, activities, from, to)
})

test_that("edges are removed for ignored subtrajectories in Clone", {
  x <- trajectory() %>%
    clone(3,
          trajectory() %>% timeout(1),
          trajectory() %>% set_attribute("asdf", 1)) %>%
    clone(2,
          trajectory() %>% timeout(1),
          trajectory() %>% set_attribute("asdf", 1)) %>%
    clone(1,
          trajectory() %>% timeout(1),
          trajectory() %>% set_attribute("asdf", 1)) %>%
    clone(0,
          trajectory() %>% timeout(1),
          trajectory() %>% set_attribute("asdf", 1)) %>%
    synchronize()

  test_graph(x,
             c("Clone", "Timeout", "SetAttribute", "Clone", "Timeout", "SetAttribute",
               "Clone", "Timeout", "SetAttribute", "Clone", "Timeout", "SetAttribute", "Synchronize"),
             c(1, 1, 1, 2, 3, 4, 4, 5, 6, 7, 8, 9, 11, 12),
             c(2, 3, 4, 4, 4, 5, 6, 7, 7, 8, 10, 10, 13, 13))
})

test_that("edges are not postprocessed when n is specified as a function", {
  x <- trajectory() %>%
    clone(function() 3,
          trajectory() %>% timeout(1),
          trajectory() %>% set_attribute("asdf", 1)) %>%
    clone(function() 2,
          trajectory() %>% timeout(1),
          trajectory() %>% set_attribute("asdf", 1)) %>%
    clone(function() 1,
          trajectory() %>% timeout(1),
          trajectory() %>% set_attribute("asdf", 1)) %>%
    clone(function() 0,
          trajectory() %>% timeout(1),
          trajectory() %>% set_attribute("asdf", 1)) %>%
    synchronize()

  test_graph(x,
             c("Clone", "Timeout", "SetAttribute", "Clone", "Timeout", "SetAttribute",
               "Clone", "Timeout", "SetAttribute", "Clone", "Timeout", "SetAttribute", "Synchronize"),
             c(1, 1, 1, 2, 3, 4, 4, 4, 5, 6, 7, 7, 7, 8, 9, 10, 10, 10, 11, 12),
             c(2, 3, 4, 4, 4, 5, 6, 7, 7, 7, 8, 9, 10, 10, 10, 11, 12, 13, 13, 13))
})
