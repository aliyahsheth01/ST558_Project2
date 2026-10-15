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

# I list the measurements users can filter. The names on the
# left appear in the app; the values on the right identify the
# corresponding columns in the data.
#
# I also include an option to leave numerical values unrestricted.
numeric_choices <- c(
  "No numerical filter" = "none",
  "Tablet weight (mg)" = "weight_mg",
  "Tablet thickness (mm)" = "thickness_mm",
  "Measured hardness (kp)" = "hardness_kp",
  "Target hardness (kp)" = "target_hardness_kp"
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
      ),
    
      # I let users choose a first numerical measurement to filter.
      # Initially, no numerical restriction is applied.
      selectInput(
        inputId = "numeric_var1",
        label = "First numerical filter:",
        choices = numeric_choices,
        selected = "none"
      ),
      
      # I reserve a location for the range slider that the server
      # will create for the first selected measurement.
      uiOutput("numeric_range1_ui"),
      
      # A second selector allows users to restrict another measurement
      # using its own range.
      selectInput(
        inputId = "numeric_var2",
        label = "Second numerical filter:",
        choices = numeric_choices,
        selected = "none"
      ),
      
      uiOutput("numeric_range2_ui"),
      
      # I provide a button so users can finish choosing their filters
      # before applying them to the data.
      helpText(
        "After choosing your filters, click Apply Filters",
        "to update the data and results."
      ),
      
      actionButton(
        inputId = "apply_filters",
        label = "Apply filters"
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


# The server creates a range slider whenever a user selects a
# numerical measurement. Each slider starts with the full range
# of available values for that measurement.
server <- function(input, output, session) {
  
  # I create the first slider after a measurement has been selected.
  # Checking that the input exists also protects against errors
  # while the app is first loading.
  output$numeric_range1_ui <- renderUI({
    
    if (!is.null(input$numeric_var1) &&
        input$numeric_var1 != "none") {
      
      # I retrieve the column selected in the first dropdown.
      variable_values <- tablet_data[[input$numeric_var1]]
      
      # Some measurements are missing, so I exclude missing values
      # when finding the smallest and largest available readings.
      variable_range <- range(variable_values, na.rm = TRUE)
      
      # Supplying both endpoints as the starting value creates
      # a slider with separate lower and upper handles.
      sliderInput(
        inputId = "numeric_range1",
        label = "Include values between:",
        min = variable_range[1],
        max = variable_range[2],
        value = variable_range,
        step = 0.01
      )
    }
  })
  
  
  # I repeat the process for the second numerical filter.
  # Its separate input names let users adjust it independently.
  output$numeric_range2_ui <- renderUI({
    
    if (!is.null(input$numeric_var2) &&
        input$numeric_var2 != "none") {
      
      variable_values <- tablet_data[[input$numeric_var2]]
      variable_range <- range(variable_values, na.rm = TRUE)
      
      sliderInput(
        inputId = "numeric_range2",
        label = "Include values between:",
        min = variable_range[1],
        max = variable_range[2],
        value = variable_range,
        step = 0.01
      )
    }
  })
  
}


# Finally, I connect the interface and server to create the app.
shinyApp(ui = ui, server = server)