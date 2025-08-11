## Overview

I have been toying around with the idea of using LLMs in data analytics scenarios. 
Here I am playing with **external tool calls** to allow an AI model to create various 
exploratory charts *without providing the model with the complete dataset* (which 
is generally undesirable for most enterprise use cases), *nor allowing it to generate and execute arbitrary code on the host machine* 
(for obvious safety and privacy reasons). Instead the LLM is provided with the meta 
information of the dataset (column names, descriptions and data types) and a usage 
description of the available tools. It is then tasked to orchestrate these tools 
to figure out when to call them and with which parameters. The actual tool call 
itself runs on the app host and neither data nor source code needs to be shared 
with the third party LLM provider.

The app uses the excellent `{ellmer}` R package which takes care of interfacing 
with most common AI models along with the tool registration to provide the LLM with 
tool call functionality.


## Setup

The development environment of this project is encapsulated in a Docker container.

1. Install Docker. Follow the instructions on https://docs.docker.com/install/
2. Clone the GIT repository   
   `git clone https://github.com/nz-stefan/commute-explorer-2.git`
3. Setup development Docker container  
   `bin/setup-environment.sh`  
   You should see lots of container build messages
4. Spin up the container  
   `bin/start_rstudio.sh`
5. Open `http://localhost:8792` in your browser to start a new RStudio session
6. Install R packages required for this app. Type the following instructions into the R session window of RStudio  
   `renv::restore()`
7. Open file `.Renviron-template` and follow instructions to set up your `OPENAI_API_KEY`.

The installation will take a few minutes. The package library will be installed into 
the `renv/library` directory of the project path. Open the file `src/app.R` and hit the 
"Run app" button in the toolbar of the script editor. The Shiny app should open in 
a new window. You may need to instruct your browser to not block popup windows for this URL.


