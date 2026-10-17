# I begin by loading Shiny, which provides the functions I need
# to build the app's layout and interactive features.
library(shiny)

# I load the packages that let me read the Excel workbook and
# prepare its columns for use in the app.
library(readxl)
library(dplyr)

# I load ggplot2 to let me build bar charts for this app.
library(ggplot2)

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

# I list the categorical variables users can explore.
# These choices include manufacturing details beyond the
# study and strength filters available in the sidebar.
categorical_choices <- c(
  "Study" = "study",
  "Tablet strength" = "strength",
  "Manufacturing condition" = "condition",
  "Sampling point" = "sampling_point",
  "Equipment" = "equipment",
  "Blend" = "blend",
  "Compression lot" = "lot",
  "Speed setting" = "speed_setting"
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
        "After choosing your filters, click Apply filters",
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
          
          # I introduce the app's purpose before explaining the data
          # and how someone can explore them.
          h3("About this app"),
          
          p(
            "The Tablet In-Process Data Explorer was developed for",
            "ST 558 Project 2. It helps users explore in-process tablet weight,",
            "thickness, and hardness through tablet compression across studies,",
            "strengths, and manufacturing conditions."
          ),
          
          # I describe what each record represents and identify the
          # workbook that supplies the data.
          
          # I include an example of a rotary tablet press to connect the
          # measurements with the compression process. I credit Natoli
          # and provide a link to the equipment's product page.
          img(
            src = "tablet_press.jpg",
            alt = "Natoli NP-255 rotary tablet press",
            width = 350
          ),
          
          p(
            "Example of a rotary tablet press. Image source: ",
            tags$a(
              "Natoli Engineering — NP-255",
              href = paste0(
                "https://natoli.com/products/tablet-presses/",
                "production-tablet-presses/np-255/"
              ),
              target = "_blank"
            )
          ),
          
          h4("About the data"),
          
          p(
            "The dataset contains 4,850 tablet records from 52 compression",
            "lots of an immediate-release tablet product under development.",
            "It includes three strengths (Low, Mid, and High), two",
            "engineering studies, and one registration batch campaign."
          ),
          
          p(
            "Samples of 20–30 tablets were collected at defined points",
            "during compression. Available measurements include weight",
            "in milligrams, thickness in millimeters, and hardness",
            "(tablet breaking force) in kiloponds."
          ),
          
          p(
            "The data come from the deidentified workbook",
            "tablet_ipc_deidentified.xlsx supplied for this project.",
            "The project README provides additional background",
            "and descriptions of the variables."
          ),
          
          p(
            tags$a(
              "View the dataset documentation on GitHub",
              href = paste0(
                "https://github.com/aliyahsheth01/",
                "ST558_Project2#about-the-data"
              ),
              target = "_blank"
            )
          ),
          
          # I explain features of the data that matter when interpreting
          # summaries and comparing the measurements.
          h4("Understanding the measurements"),
          
          p(
            "Not every record contains all three measurements.",
            "The number of available readings can therefore differ",
            "between weight, thickness, and hardness.",
            "Compression dates were not recorded for Engineering Study 1."
          ),
          
          p(
            "Target hardness describes the intended setting rather than",
            "the measured breaking force. Missing targets in the",
            "Registration study are filled using preset values of",
            "4 kp for Low strength and 7 kp for Mid and High strengths.",
            "Existing target values are retained."
          ),
          
          # I explain how users choose a subset and when those choices
          # take effect.
          h4("Using the sidebar"),
          
          p(
            "Choose the studies and strengths to include.",
            "Keep every checkbox selected to include all categories."
          ),
          
          p(
            "You can also select up to two numerical measurements",
            "and adjust their lower and upper limits using the sliders.",
            "Choose No numerical filter when you do not want",
            "to restrict a measurement."
          ),
          
          p(
            "Click Apply filters after making your selections.",
            "The selected data and results update when this button",
            "is pressed."
          ),
          
          # I describe what users can find in each main tab.
          h4("Using the tabs"),
          
          p(
            strong("About: "),
            "Learn about the dataset and how to use the app."
          ),
          
          p(
            strong("Data Download: "),
            "Browse the selected records and download them as a CSV file."
          ),
          
          p(
            strong("Data Exploration: "),
            "Create frequency tables, numerical summaries, and graphs.",
            "Choose variables and available grouping, coloring,",
            "or faceting options to explore the selected records."
          )
        ),
        
        tabPanel(
          "Data Download",
          
          h3("View and download the selected data"),
          
          p(
            "Use the sidebar and Apply filters to choose the records.",
            "Use the table's search box and column headings to browse",
            "and sort the applied dataset."
          ),
          
          textOutput("record_count"),
          
          helpText(
            "Numerical filters exclude records with missing values",
            "for the selected measurement."
          ),
          
          # I provide a download of every record in the applied dataset.
          downloadButton(
            outputId = "download_data",
            label = "Download applied data (CSV)"
          ),
          
          helpText(
            "The CSV includes all records selected by your last",
            "Apply filters click. Table search and paging affect",
            "only the table display."
          ),
          
          # I reserve a location for the interactive table that the
          # server will create from the applied dataset.
          DT::dataTableOutput("download_table")
        ),
        
        tabPanel(
          "Data Exploration",
          
          h3("Explore the selected data"),
          
          p(
            "Summaries and graphs use the dataset from your most recent",
            "Apply filters click. Choose variables below to explore",
            "those records."
          ),
          
          # I organize exploration into categorical and numerical
          # sections so users can find the appropriate summaries.
          tabsetPanel(
            id = "exploration_tabs",
            
            tabPanel(
              "Categorical",
              
              # The first variable determines the categories counted
              # in a one-way frequency table and simple bar chart.
              selectInput(
                inputId = "cat_var1",
                label = "First categorical variable:",
                choices = categorical_choices,
                selected = "strength"
              ),
              
              # An optional second variable allows users to examine
              # combinations through a two-way table and grouped bars.
              selectInput(
                inputId = "cat_var2",
                label = "Second categorical variable (optional):",
                choices = c(
                  "No second variable" = "none",
                  categorical_choices
                ),
                selected = "none"
              ),
              
              # I reserve locations for the frequency table and chart
              # that the server will create from these selections.
              h4("Frequency table"),
              tableOutput("categorical_table"),
              
              h4("Bar chart"),
              plotOutput("categorical_plot")
            ),
            
            tabPanel(
              "Numerical",
              
              h4("Numerical exploration"),
              
              p(
                "Summarize measurements and explore their distributions",
                "and relationships."
              )
            )
          )
        )
      )
    )
  )
)


# The server creates a range slider whenever a user selects a
# numerical measurement. Each slider starts with the full range
# of available values for that measurement.
server <- function(input, output, session) {
  
  # I store the applied dataset in a reactive object so that tables,
  # downloads, and graphs can share the same selected records.
  # When the app opens, I initially include the entire dataset.
  selected_data <- reactiveValues(data = tablet_data)
  
  
  # I apply the sidebar selections when Apply filters is clicked.
  # Each click starts with the complete dataset.
  observeEvent(input$apply_filters, {
    
    # I first keep records belonging to the selected studies
    # and strengths.
    filtered_data <- tablet_data |>
      filter(
        study %in% input$study_filter,
        strength %in% input$strength_filter
      )
    
    # If a first numerical measurement is selected, I also require
    # its value to fall within the chosen range.
    if (input$numeric_var1 != "none") {
      
      # If the slider is still loading, I leave the previously
      # applied dataset in place. The user can click again once
      # the slider appears.
      if (length(input$numeric_range1) != 2) {
        return()
      }
      
      measurement_values <- filtered_data[[input$numeric_var1]]
      
      # I exclude missing readings and include both endpoints
      # of the selected range.
      filtered_data <- filtered_data |>
        filter(
          !is.na(measurement_values),
          measurement_values >= input$numeric_range1[1],
          measurement_values <= input$numeric_range1[2]
        )
    }
    
    
    # I apply the second numerical filter to the records that
    # remain, so included records must satisfy both ranges.
    if (input$numeric_var2 != "none") {
      
      if (length(input$numeric_range2) != 2) {
        return()
      }
      
      measurement_values <- filtered_data[[input$numeric_var2]]
      
      filtered_data <- filtered_data |>
        filter(
          !is.na(measurement_values),
          measurement_values >= input$numeric_range2[1],
          measurement_values <= input$numeric_range2[2]
        )
    }
    
    
    # After applying every active filter, I store the resulting
    # dataset for the record count and subsequent outputs.
    selected_data$data <- filtered_data
    
  })
  
  
  # I count the rows in the stored dataset. This output updates
  # when a newly applied selection changes those records.
  output$record_count <- renderText({
    
    paste(
      "Records in the applied dataset:",
      nrow(selected_data$data)
    )
    
  })
  
  # I display the same applied dataset used by the record count.
  # Because this output reads selected_data$data, it responds
  # when Apply filters saves a new selection.
  output$download_table <- DT::renderDataTable({
    
    DT::datatable(
      selected_data$data,
      
      # The data already contain tablet identifiers, so I hide
      # the additional row numbers that DT would otherwise add.
      rownames = FALSE,
      
      # Sidebar filters determine the dataset. Individual table
      # rows do not need a separate selection control.
      selection = "none",
      
      # I initially show ten records per page and allow horizontal
      # scrolling so all seventeen columns remain accessible.
      options = list(
        pageLength = 10,
        scrollX = TRUE
      )
    )
    
  })
  
  # I create a CSV file when the download button is clicked.
  # The filename includes the download date to help identify it.
  output$download_data <- downloadHandler(
    
    filename = function() {
      paste0("tablet_data_", Sys.Date(), ".csv")
    },
    
    # Shiny supplies a temporary file location. I write the applied
    # dataset there, and Shiny sends that file to the user's browser.
    content = function(file) {
      
      write.csv(
        selected_data$data,
        file = file,
        
        # I keep the original data columns without adding row numbers.
        row.names = FALSE,
        
        # I represent missing measurements as blank cells.
        na = ""
      )
      
    },
    
    contentType = "text/csv"
  )
  
  # I create a frequency table using the records saved by
  # the most recent Apply filters click.
  output$categorical_table <- renderTable({
    
    exploration_data <- selected_data$data
    
    # I display helpful instructions when the applied dataset
    # is empty or the dropdown inputs are still loading.
    validate(
      need(
        nrow(exploration_data) > 0,
        "No records match your filters. Adjust the sidebar and click Apply filters."
      ),
      need(
        !is.null(input$cat_var1) && !is.null(input$cat_var2),
        "Choose a categorical variable to begin."
      )
    )
    
    # I retrieve the readable label associated with the first
    # selected column so the table has an informative heading.
    first_label <- names(categorical_choices)[
      categorical_choices == input$cat_var1
    ]
    
    if (input$cat_var2 == "none") {
      
      # With one variable, I count the records in each category.
      frequency_table <- as.data.frame(
        table(exploration_data[[input$cat_var1]])
      )
      
      names(frequency_table) <- c(first_label, "Records")
      
    } else {
      
      # A two-way table needs two different variables.
      validate(
        need(
          input$cat_var1 != input$cat_var2,
          "Choose a different second variable, or select No second variable."
        )
      )
      
      second_label <- names(categorical_choices)[
        categorical_choices == input$cat_var2
      ]
      
      # With two variables, I count each category combination.
      frequency_table <- as.data.frame(
        table(
          exploration_data[[input$cat_var1]],
          exploration_data[[input$cat_var2]]
        )
      )
      
      names(frequency_table) <- c(
        first_label,
        second_label,
        "Records"
      )
    }
    
    frequency_table
    
  }, digits = 0, rownames = FALSE)
  
  # I create a bar chart from the applied dataset and the
  # categorical variables selected in the exploration tab.
  output$categorical_plot <- renderPlot({
    
    exploration_data <- selected_data$data
    
    # I provide instructions when there are no records to plot
    # or the dropdown inputs are still loading.
    validate(
      need(
        nrow(exploration_data) > 0,
        "No records match your filters. Adjust the sidebar and click Apply filters."
      ),
      need(
        !is.null(input$cat_var1) && !is.null(input$cat_var2),
        "Choose a categorical variable to begin."
      )
    )
    
    first_label <- names(categorical_choices)[
      categorical_choices == input$cat_var1
    ]
    
    # I place the selected values into a plotting data frame.
    # The fixed column name lets me use familiar aes() syntax
    # regardless of which variable the user selects.
    plot_data <- data.frame(
      category1 = exploration_data[[input$cat_var1]]
    )
    
    if (input$cat_var2 == "none") {
      
      # With one variable, each bar counts the records belonging
      # to one category.
      ggplot(data = plot_data, aes(x = category1)) +
        geom_bar(fill = "steelblue") +
        labs(
          title = paste("Tablet Records by", first_label),
          x = first_label,
          y = "Number of records"
        )
      
    } else {
      
      validate(
        need(
          input$cat_var1 != input$cat_var2,
          "Choose a different second variable, or select No second variable."
        )
      )
      
      second_label <- names(categorical_choices)[
        categorical_choices == input$cat_var2
      ]
      
      # I add the second variable and use it to color the bars.
      plot_data$category2 <- exploration_data[[input$cat_var2]]
      
      # Dodge places the colored groups beside one another.
      ggplot(
        data = plot_data,
        aes(x = category1, fill = category2)
      ) +
        geom_bar(position = "dodge") +
        labs(
          title = paste(
            "Tablet Records by", first_label, "and", second_label
          ),
          x = first_label,
          y = "Number of records",
          fill = second_label
        )
    }
    
  })
  
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