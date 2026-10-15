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

# The tablet number identifies a tablet within each sample. I store it as character to make its role as an identifier clear.
tablet_data <- tablet_data |>
  mutate(tablet_no = as.character(tablet_no))

# I check that the tablet number is now stored as character.
class(tablet_data$tablet_no)

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

# I want the strengths to appear in the order Low, Mid, High in my tables and graphs. I store strength as a factor, which tells R
# that these labels represent categories, and specify their order.
tablet_data <- tablet_data |>
  mutate(strength = factor(strength, levels = c("Low", "Mid", "High")))

# With the categories arranged, I begin by counting the records for each strength. This gives me a first look at how the data are
# distributed across strengths. I save the table so I can use it again later, then display it in the Console.
strength_counts <- table(tablet_data$strength)
strength_counts

# The strength counts describe the dataset overall. I now want to see how those records are distributed across the three studies.
# This table places studies in the rows and strengths in the columns. Each cell counts the records for one study and strength combination.
study_strength_counts <- table(tablet_data$study, tablet_data$strength)

# I display the table to check which combinations are represented and how much data are available for each combination.
study_strength_counts

# Now that I know how the records are distributed, I begin looking at the measurements themselves. The strengths have different
# intended tablet weights, so I summarize weight separately for Low, Mid, and High strengths. For each strength, I count the 
# available weight measurements and calculate their mean, median, and standard deviation. Setting na.rm = TRUE leaves 
# missing weights out of each calculation.
weight_summary <- tablet_data |>
  group_by(strength) |>
  summarize(
    n_weight = sum(!is.na(weight_mg)),
    mean_mg = mean(weight_mg, na.rm = TRUE),
    median_mg = median(weight_mg, na.rm = TRUE),
    sd_mg = sd(weight_mg, na.rm = TRUE)
  )

# I display the results to examine the typical weight and the amount of variation within each strength. All weight summaries
# are expressed in milligrams.
weight_summary

# I now summarize tablet hardness, which measures the force needed to break a tablet and is expressed here in kiloponds (kp).
# For each strength, I count the available hardness measurements and calculate their mean, median, and standard deviation.
# These summaries combine the studies and conditions within each strength. Later tables and graphs will help me explore how
# hardness differs across those manufacturing conditions.
hardness_summary <- tablet_data |>
  group_by(strength) |>
  summarize(
    n_hardness = sum(!is.na(hardness_kp)),
    mean_kp = mean(hardness_kp, na.rm = TRUE),
    median_kp = median(hardness_kp, na.rm = TRUE),
    sd_kp = sd(hardness_kp, na.rm = TRUE)
  )

# I display the summary to examine the typical hardness and its variability within each strength.
hardness_summary

# The final measurement I summarize is tablet thickness, expressed in millimeters. Looking at thickness within each strength helps
# me describe the typical tablet dimensions and their variability. As with weight and hardness, I count the available measurements
# and calculate the mean, median, and standard deviation using the recorded thickness values.
thickness_summary <- tablet_data |>
  group_by(strength) |>
  summarize(
    n_thickness = sum(!is.na(thickness_mm)),
    mean_mm = mean(thickness_mm, na.rm = TRUE),
    median_mm = median(thickness_mm, na.rm = TRUE),
    sd_mm = sd(thickness_mm, na.rm = TRUE)
  )

# I display the results to complete the initial numerical summaries of weight, hardness, and thickness by strength.
thickness_summary

# My first graph shows how many tablet-level records come from each study. This gives a visual overview of the dataset before
# I explore the individual tablet measurements. I place study on the horizontal axis. The bar layer counts the
# records in each study automatically, and I add a title and axis labels to explain what the graph shows.
study_barplot <- ggplot(
  data = tablet_data,
  aes(x = study)
) +
  geom_bar() +
  labs(
    title = "Number of Tablet Records by Study",
    x = "Study",
    y = "Number of records"
  )

# I display the saved plot in RStudio's Plots pane.
study_barplot

# Next, I break each study's record count down by tablet strength.Showing the strengths side by side lets me compare how many
# records are available for Low, Mid, and High within each study.Mapping strength to fill gives each strength a different color.
# The dodge position places those colored bars beside one another.
study_strength_barplot <- ggplot(
  data = tablet_data,
  aes(x = study, fill = strength)
) +
  geom_bar(position = "dodge") +
  labs(
    title = "Tablet Records by Study and Strength",
    x = "Study",
    y = "Number of records"
  ) +
  scale_fill_discrete("Tablet strength")

# I display the plot to compare the study and strength combinations.
study_strength_barplot

# I now explore the distribution of tablet weight within each strength. A histogram groups weights into intervals and shows
# how many records fall within each interval.I use intervals that are 1 mg wide and create a separate panel
# for each strength. Each panel has its own horizontal range so the weight distribution for that strength is easy to examine.
weight_histogram <- ggplot(
  data = tablet_data,
  aes(x = weight_mg)
) +
  geom_histogram(
    binwidth = 1,
    center = 0,
    fill = "steelblue",
    color = "white",
    na.rm = TRUE
  ) +
  facet_wrap(~ strength, scales = "free_x") +
  labs(
    title = "Tablet Weight Distribution by Strength",
    x = "Tablet weight (mg)",
    y = "Number of records"
  )

# I display the three distributions together. When comparing their spread, I check the horizontal-axis values because the panels
# use different weight ranges.
weight_histogram

# Next, I compare the hardness distributions across studies within each strength. Box plots help me examine the typical hardness,
# the spread of the measurements, and unusually high or low values. I place strength on the horizontal axis and hardness on the
# vertical axis. Coloring the boxes by study lets me compare the three studies within each strength.
hardness_boxplot <- ggplot(
  data = tablet_data,
  aes(x = strength, y = hardness_kp, fill = study)
) +
  geom_boxplot(na.rm = TRUE) +
  labs(
    title = "Tablet Hardness by Strength and Study",
    x = "Tablet strength",
    y = "Hardness (kp)"
  ) +
  scale_fill_discrete("Study")

# I display the plot, keeping in mind that the engineering studies include experiments with different intended hardness settings.
hardness_boxplot

# I explore how tablet thickness varies with the target hardness setting for each strength. Target hardness describes the intended
# setting for the lot, while thickness is measured on each tablet. Each point represents a record with both values available.
# Coloring by strength helps me distinguish the three groups.
target_thickness_scatterplot <- ggplot(
  data = tablet_data,
  aes(
    x = target_hardness_kp,
    y = thickness_mm,
    color = strength
  )
) +
  geom_point(alpha = 0.5, na.rm = TRUE) +
  labs(
    title = "Tablet Thickness by Target Hardness and Strength",
    x = "Target hardness (kp)",
    y = "Tablet thickness (mm)",
    color = "Tablet strength"
  )

# I display the plot to examine thickness across the target settings.
target_thickness_scatterplot

# I compare relative thickness variability across target hardness settings and strengths. For each combination, I calculate the
# number of thickness readings, their mean, and standard deviation. I then express the standard deviation as a percentage of the mean.
thickness_rsd_data <- tablet_data |>
  filter(!is.na(thickness_mm)) |>
  group_by(strength, target_hardness_kp) |>
  summarize(
    n_thickness = n(),
    mean_mm = mean(thickness_mm),
    sd_mm = sd(thickness_mm),
    .groups = "drop"
  ) |>
  mutate(
    rsd_percent = 100 * sd_mm / mean_mm
  )

# Each heatmap cell shows thickness RSD for one target hardness and strength combination. Higher values indicate greater 
# thickness variation relative to the mean thickness.
thickness_rsd_heatmap <- ggplot(
  data = thickness_rsd_data,
  aes(
    x = factor(target_hardness_kp),
    y = strength,
    fill = rsd_percent
  )
) +
  geom_tile(color = "white") +
  labs(
    title = "Thickness RSD by Target Hardness and Strength",
    x = "Target hardness (kp)",
    y = "Tablet strength",
    fill = "Thickness RSD (%)",
    caption = "RSD pools measurements across contributing lots and studies."
  )

# I display the heatmap to compare relative thickness variability.
thickness_rsd_heatmap
