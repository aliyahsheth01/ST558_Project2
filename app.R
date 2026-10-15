# I begin by loading Shiny, which provides the functions I need
# to build the app's layout and interactive features.
library(shiny)

# I load the packages that let me read the Excel workbook and
# prepare its columns for use in the app.
library(readxl)
library(dplyr)


# I read the tablet measurements from the data worksheet.
# Each row represents one tablet record.
tablet_data <- read_excel(
  "data/tablet_ipc_deidentified.xlsx",
  sheet = "data"
)


# Before building the filters, I prepare the dates, identifiers,
# category order, and target hardness values.
tablet_data <- tablet_data |>
  mutate(
    
    # I store compression dates as dates so R can interpret them
    # correctly when they are displayed or used later.
    compression_date = as.Date(compression_date),
    
    # Tablet numbers identify tablets within a sample. I treat
    # them as text because they are labels rather than measurements.
    tablet_no = as.character(tablet_no),
    
    # I arrange the strengths in their natural order so tables
    # and graphs consistently display Low, Mid, then High.
    strength = factor(
      strength,
      levels = c("Low", "Mid", "High")
    ),
    
    # I fill missing registration targets using the preset values:
    # 4 kp for Low and 7 kp for Mid and High. Existing targets
    # are retained.
    target_hardness_kp = ifelse(
      study == "Registration" & is.na(target_hardness_kp),
      ifelse(strength == "Low", 4, 7),
      target_hardness_kp
    )
  )

# The user interface determines what someone sees when they open
# the app. I start with a title and divide the page into a sidebar
# for filters and a main panel for information and results.
ui <- fluidPage(
  
  titlePanel("Tablet In-Process Data Explorer"),
  
  sidebarLayout(
    
    sidebarPanel(
      
      h3("Filter the data"),
      
      p(
        "Select the studies and strengths to include.",
        "Keep every box checked to include all categories."
      ),
      
      # I let users choose which studies to include. I get the study
      # names directly from the data and initially select all of them.
      checkboxGroupInput(
        inputId = "study_filter",
        label = "Study:",
        choices = unique(tablet_data$study),
        selected = unique(tablet_data$study)
      ),
      
      # I use the strength levels I arranged during data preparation
      # so these choices appear as Low, Mid, and High.
      # All three strengths are included when the app opens.
      checkboxGroupInput(
        inputId = "strength_filter",
        label = "Tablet strength:",
        choices = levels(tablet_data$strength),
        selected = levels(tablet_data$strength)
      )
    ),
    
    # I organize the main panel into three tabs. About comes first
    # so users can learn about the data before exploring them.
    mainPanel(
      
      tabsetPanel(
        selected = "About",
        
        tabPanel(
          "About",
          h3("About this app"),
          p(
            "Explore tablet weight, thickness, and hardness across",
            "studies, strengths, and manufacturing conditions."
          )
        ),
        
        tabPanel(
          "Data Download",
          h3("View and download the selected data")
        ),
        
        tabPanel(
          "Data Exploration",
          h3("Explore the selected data")
        )
      )
    )
  )
)


# The server will contain the calculations that respond to user
# selections. I leave it empty while I check the initial layout.
server <- function(input, output, session) {
  
}


# Finally, I connect the interface and server to create the app.
shinyApp(ui = ui, server = server)