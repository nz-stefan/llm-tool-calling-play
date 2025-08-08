################################################################################
# Demonstration of tool calling from within a modern chat model.
#
# The motivating example is to create a chat interface to perform an exploratory
# data analysis without writing any code. We want to talk to a chat bot about a
# given data set and create various exploratory visualizations like scatter and
# density plots as we go along.
#
# For privacy and safety reasons we don't want to give to the LLM direct access 
# to the data. Additionally, we don't trust the LLM to generate code to be executed 
# locally. Instead we will use so called external tools that the LLM is instructed 
# to use to achieve the various exploration goals. These tools have a well defined
# signature that the LLM is allowed to parameterise and call at will. The tools
# do not share any results with the LLM and we retain full control over the actual
# code getting executed.
#
# The tool usage using the {ellmer} package us demonstrated in a little toy Shiny 
# app.
#
# Author: Stefan Schliebs
# Created: 2025-08-08 04:08:23 UTC
################################################################################


library(shiny)
library(shinychat)
library(plotly)
library(ellmer)
library(here)


# Config ------------------------------------------------------------------

F_SYSTEM_PROMPT <- here("src/prompt.md")
F_GREETINGS <- here("src/greetings.md")


# Set up the chat bot -------------------------------------------------------

# load system prompt
system_prompt <- readLines(F_SYSTEM_PROMPT)

# initialize the bot
# NOTE: this will require a valid API key in `.Renviron`
chat <- chat_openai(system_prompt = system_prompt)


# UI definitions of the Shiny app -------------------------------------------

ui <- bslib::page_sidebar(
  title = "Exploratory Data Analysis using an LLM",
  sidebar = bslib::sidebar(chat_ui("chat"), width = "40%"),
  bslib::card(
    full_screen = TRUE,
    plotlyOutput("plot")
  )
)


# Server logic of the Shiny app ---------------------------------------------

server <- function(input, output, session) {

  # Define AI tools ---------------------------------------------------------

  # TOOL plot_scatter -------------------------------------------------------
  
  #' Create a ggplot2 scatter plot in the form
  #' `ggplot(data, aes(x = x, y = y, color = color, shape = shape)) + geom_point()`
  #' 
  #' Optionally, the function can add a smoothing line to the chart using `geom_smooth()`
  #' and add facets using `facet_wrap()`
  #'
  #' @param title A suitable title for the plot
  #' @param x The data column name (string) to map to the x coordinate of the plot
  #' @param y  The data column name (string) to map to the y coordinate of the plot
  #' @param color The data column name (string) to map to the color aesthetic of the plot, use NULL if not needed in the plot
  #' @param shape The data column name (string) to map to the shape aesthetic of the plot, use NULL if not needed in the plot
  #' @param smoothing_line Toggle smoothing line (geom_smooth) on or off in the plot, either TRUE or FALSE
  #' @param smoothing_method Set the smoothing method, e.g. lm or loess or NULL for automatic selection
  #' @param facet The data column (string) used to create facets of the plot
  #' @return NULL, we are only interested in the side effect of the function
  plot_scatter <- function(title, x, y, color = NULL, shape = NULL, smoothing_line = FALSE, smoothing_method = NULL, facet = NULL) {
    # make a copy of the data, we may need to convert some columns into factors 
    # before plotting
    d <- mtcars

    # create a list of aesthetics that we fill with the function parameters (if not NULL)
    aes_list <- list(x = sym(x), y = sym(y))
    
    if (! is.null(color)) {
      d[color] <- factor(d[[color]])
      aes_list$color <- sym(color)
    }
    
    if (! is.null(shape)) {
      d[shape] <- factor(d[[shape]])
      aes_list$shape <- sym(shape)
    }
    
    tryCatch(
      {
        p <- ggplot(d, do.call(aes, aes_list)) + 
          geom_point() + 
          labs(title = title)
        
        if (smoothing_line) {
          p <- p + geom_smooth(method = smoothing_method)
        }
        
        if (! is.null(facet)) {
          p <- p + facet_wrap(as.formula(paste("~ factor(", facet, ")")))
        }
        # print(p)
        output$plot <- renderPlotly(ggplotly(p))
      },
      error = function(err) {
        append_output("> Error: ", conditionMessage(err), "\n\n")
        stop(err)
      }
    )
  }
  

  # TOOL plot_density -------------------------------------------------------

  #' Create ggplot density plot using
  #' `ggplot(data, aes(x)) + geom_density()`
  #' 
  #' @param x The column name (string) for which the density plot is created for
  #' @param color The data column name (string) to map to the color aesthetic of the plot, use NULL if not needed in the plot
  #' @param facet The data column (string) used to create facets of the plot
  #' @return NULL, we are only interested in the side effect of the function
  plot_density <- function(x, color = NULL, facet = NULL) {
    # make a copy of the data, we may need to convert some columns into factors 
    # before plotting
    d <- mtcars
    
    # create a list of aesthetics that we fill with the function parameters (if not NULL)
    aes_list <- list(x = sym(x))
    
    if (! is.null(color)) {
      d[color] <- factor(d[[color]])
      aes_list$color <- sym(color)
    }
    
    tryCatch(
      {
        p <- ggplot(d, do.call(aes, aes_list)) +
          geom_density()
        
        if (! is.null(facet)) {
          p <- p + facet_wrap(as.formula(paste("~ factor(", facet, ")")))
        }
        
        output$plot <- renderPlotly(ggplotly(p))
      },
      error = function(err) {
        append_output("> Error: ", conditionMessage(err), "\n\n")
        stop(err)
      }
    )
  }
  

  # Register tools in the chatbot -------------------------------------------

  # register scatter plot tool
  chat$register_tool(
    tool(
      plot_scatter,
      name = "plot_scatter",
      description = "Creates a scatter plot of x versus y with optional color and shape aesthetics, and optional smoothing line.",
      arguments = list(
        title = type_string("A suitable title for the plot, e.g. 'Miles per gallon by horsepower'"),
        x = type_string("The data column name (string) to map to the x coordinate of the plot, .e.g. 'mpg'"),
        y = type_string("The data column name (string) to map to the y coordinate of the plot, .e.g. 'hp'"),
        color = type_string("The data column name (string) to map to the color aesthetic of the plot, use NULL if not needed in the plot", required = FALSE),
        shape = type_string("The data column name (string) to map to the shape aesthetic of the plot, use NULL if not needed in the plot", required = FALSE),
        smoothing_line = type_boolean("Whether to add a smoothing line. Defaults to FALSE.", required = FALSE),
        smoothing_method = type_string("The smoothing method to use if smoothing_line is TRUE (e.g., 'lm', 'loess'). Defaults to NULL.", required = FALSE),
        facet = type_string("The data column (string) used to create facets of the plot. Defaults to NULL.", required = FALSE)
      )
    )
  )
  
  # register density plot tool
  chat$register_tool(
    tool(
      plot_density,
      name = "plot_density",
      description = "Creates a density plot for a given column in the data set",
      arguments = list(
        x = type_string("The data column name (string) to generate the density plot for, .e.g. 'mpg'"),
        color = type_string("The data column name (string) to map to the color aesthetic of the plot, use NULL if not needed in the plot", required = FALSE),
        facet = type_string("The data column (string) used to create facets of the plot. Defaults to NULL.", required = FALSE)
      )
    )
  )
  

  # Set up the chat stream --------------------------------------------------

  chat_append("chat", readLines(F_GREETINGS), role = "assistant", session = session)
  
  # helper function to append text to the chat window
  append_output <- function(...) {
    txt <- paste0(...)
    chat_append_message(
      "chat",
      list(role = "assistant", content = txt),
      chunk = TRUE,
      operation = "append",
      session = session
    )
  }
  
  # stream LLM response as it becomes available
  observeEvent(input$chat_user_input, {
    stream <- chat$stream_async(input$chat_user_input)
    chat_append("chat", stream)
  })
  

  # Plot output -------------------------------------------------------------

  output$plot <- renderPlotly({ggplot()})
}


# Run the shiny app -------------------------------------------------------

shinyApp(ui, server)