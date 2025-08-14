# LLM tools for exploratory data analysis

I have been toying around with the idea of using LLMs in data analytics scenarios. 
Here I am playing with **external tool calls** to allow an AI model to create various 
exploratory charts *without providing the model with the complete dataset* which 
is generally undesirable for most enterprise use cases, *nor allowing it to generate and execute arbitrary code on the host machine* 
for obvious safety and privacy reasons. Instead the LLM is provided with the meta 
information of the dataset (column names, descriptions and data types) and a usage 
description of the available tools. It is then tasked to orchestrate these tools 
to figure out when to call them and with which parameters. The actual tool call 
itself runs on the app host and neither data nor source code needs to be shared 
with the third party LLM provider.

The app uses the excellent `{ellmer}` R package which takes care of interfacing 
with most common AI models along with the tool registration to provide the LLM with 
tool call functionality.

Here is a screen recording of the app in action.

![exploratory-analysis-app-recording-short.gif](https://github.com/nz-stefan/llm-tool-calling-play/blob/main/exploratory-analysis-app-recording-short.gif)

## LLM tools

In this example, I have developed two tools to create some typical exploratory analysis charts,
i.e. scatter plots and distribution plots.

### Scatter plot tool

Creates a ggplot2 scatter plot in the form
`ggplot(data, aes(x = x, y = y, color = color, shape = shape)) + geom_point()`

Optionally, the tool can add a smoothing line to the chart using geom_smooth().

Tool parameters:

- param `title` A suitable title (string) for the plot
- param `x` The data column name (string) to map to the x coordinate of the plot
- param `y`  The data column name (string) to map to the y coordinate of the plot
- param `color` The data column name (string) to map to the color aesthetic of the plot, use NULL if not needed in the plot
- param `shape` The data column name (string) to map to the shape aesthetic of the plot
- param `smoothing_line` Toggle smoothing line (geom_smooth) on or off in the plot, either TRUE or FALSE
- param `smoothing_method` Set the smoothing method, e.g. lm or loess or NULL for automatic selection
- param `facet` The data column (string) used to create facets of the plot, use NULL if not needed in the plot

Example invocations of this tool:

- `plot_scatter(x = "mpg", y = "hp", color = "gear")`
- `plot_scatter(x = "cyl", y = "mpg", color = "gear", smoothing_line = TRUE, smoothing_method = lm)`
- `plot_scatter(x = "cyl", y = "mpg", color = "gear", smoothing_line = TRUE, smoothing_method = lm, facet = "am")`


### Distribution plot tool

Creates a ggplot density plot in the form
`ggplot(data, aes(x)) + geom_density()`

Tool parameters: 

- param x The column name (string) for which the density plot is created for
- param facet The data column (string) used to create facets of the plot

Example invocations of this tool:

- `plot_density("mpg")`
- `plot_density("mpg", facet = "gear")`


## Dev environment setup

The development environment of this project is encapsulated in a Docker container.

1. Install Docker. Follow the instructions on https://docs.docker.com/install/
2. Clone the GIT repository   
   `git clone https://github.com/nz-stefan/llm-tool-calling-play`
3. Open file `.Renviron-template` and follow instructions to set up your `OPENAI_API_KEY`.
4. Setup development Docker container  
   `bin/setup-environment.sh`  
   You should see lots of container build messages
5. Spin up the container  
   `bin/start_rstudio.sh`
6. Open `http://localhost:8792` in your browser to start a new RStudio session
7. Install R packages required for this app. Type the following instructions into the R session window of RStudio  
   `renv::restore()`

The installation will take a few minutes. The package library will be installed into 
the `renv/library` directory of the project path. Open the file `src/app.R` and hit the 
"Run app" button in the toolbar of the script editor. The Shiny app should open in 
a new window. You may need to instruct your browser to not block popup windows for this URL.
