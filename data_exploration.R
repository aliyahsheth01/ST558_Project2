# ST 558 Project 2
# Explore deidentified tablet manufacturing data.

# Load packages for reading, summarizing, and plotting data.
library(readxl)
library(dplyr)
library(ggplot2)

# Read the main data worksheet.
tablet_data <- read_excel("data/tablet_ipc_deidentified.xlsx", sheet = "data")

# R has recognized the compression dates, but it has included a time component. These records only need the calendar date, so I convert
# this column to Date. This keeps it suitable for sorting and plotting.
tablet_data$compression_date <- as.Date(tablet_data$compression_date)

# I now check that the conversion worked and review the earliest and latest dates. The na.rm argument leaves missing dates out of this
# range calculation. I also confirm how many dates are still missing.
class(tablet_data$compression_date)
range(tablet_data$compression_date, na.rm = TRUE)
sum(is.na(tablet_data$compression_date))

# The routine registration records are missing target hardness values in the workbook, but their intended targets were preset based on manufacturing
# instructions: 4 kp for Low strength and 7 kp for both Mid and High strengths. I first retain any target that is already recorded. For registration
# records with a missing target, I then assign the preset value for that strength. These values describe the intended settings, rather
# than the hardness actually measured on the tablets.
tablet_data <- tablet_data |>
  mutate(
    target_hardness_kp = ifelse(
      study == "Registration" & is.na(target_hardness_kp),
      ifelse(strength == "Low", 4, 7),
      target_hardness_kp
    )
  )

# I confirm that no target hardness values remain missing.
sum(is.na(tablet_data$target_hardness_kp))

# Check the number of rows and columns.
dim(tablet_data)

# Display the column names.
names(tablet_data)

# The number of rows and columns matches what I expected. Before making tables and graphs, I want to see how R has read each column.
# For example, weight should be stored as numbers, while strength contains labels such as Low, Mid, and High. The output below shows
# each column's data type and a few values so I can check this.
str(tablet_data)

# I also want to know where measurements are missing. R represents missing values as NA, and this command counts them in each column.
# The is.na() part identifies missing values, and colSums() adds up those results separately for each column.These counts will help me 
# plan the summaries and graphs. A row without a hardness measurement may still have a weight measurement, so I will consider missing 
# values separately for each analysis.
colSums(is.na(tablet_data))
