# Tablet In-Process Data Explorer

This project is being developed for ST 558 Project 2. Its purpose is to create a Shiny app that helps users explore tablet manufacturing data and understand how tablet weight, thickness, and hardness vary across studies, strengths, and manufacturing conditions.

Deployed app: Not yet deployed.

Static exploration: [data_exploration.R](data_exploration.R)

## About the data

`data/tablet_ipc_deidentified.xlsx` contains 4,850 tablet-level records from 52 compression lots of an immediate-release tablet product under development. The data cover three strengths (Low, Mid, High), two engineering studies, and one registration batch campaign. Samples of 20–30 tablets were collected at defined points during compression. Available measurements include weight, thickness, and breaking force (hardness), with measurement availability varying across records.

| Column | Type | Description |
|---|---|---|
| `tablet_id` | integer | Row identifier |
| `study` | categorical (3) | Eng Study 1, Eng Study 2, Registration |
| `strength` | categorical (3) | Low, Mid, High |
| `blend` | categorical (9) | Common final blend the lot was compressed from (B1–B9) |
| `lot` | categorical (52) | Compression lot / sub-lot (L01–L52) |
| `condition` | categorical (5) | Registration, Target hardness, Compressibility curve, Speed DOE, Score functionality |
| `target_hardness_kp` | numeric | Hardness setpoint for the lot, where stated (data for registration lots added based on manufacturing records) |
| `speed_setting` | categorical (5) | Nominal, or the turret/feeder corner for Speed DOE lots |
| `sampling_point` | categorical (4) | Pre-Start, Beginning, Middle, End |
| `sampling_detail` | categorical (10) | Original sampling label before grouping |
| `equipment` | categorical (2) | AT4 (automated tester) or Manual (individual tablet hardness tester) |
| `sample_id` | text | One IPC pull of 20–30 tablets (lot–point–equipment) |
| `tablet_no` | text | Tablet number within the sample; stored as character in R |
| `weight_mg` | numeric | Individual tablet weight, mg |
| `thickness_mm` | numeric | Tablet thickness, mm |
| `hardness_kp` | numeric | Tablet breaking force, kp |
| `compression_date` | date | Date of measurement (not recorded for Eng Study 1) |

Measurement availability varies across records. AT4 records contain weight and thickness, and some also contain hardness. Most manual records contain hardness only, although some include all three measurements. Missing values will be handled separately for each summary or graph.

During data preparation, missing target hardness values for registration records are filled using the preset targets: 4 kp for Low strength and 7 kp for Mid and High strengths. Existing target values are retained. Compression dates are also converted to R’s Date class. These preparation steps are applied to the imported data in R; the Excel source retains its original contents.

## App features

The app contains three main tabs:

- **About** introduces the dataset, explains the measurements, and describes how to use the app.
- **Data Download** provides a searchable, sortable data table and a CSV download of the applied dataset.
- **Data Exploration** provides interactive summaries and graphs through four subtabs:
  - **Categorical:** one-way and two-way frequency tables and bar charts.
  - **Numerical:** grouped counts, means, medians, and standard deviations, plus histograms and box plots.
  - **Relationships:** scatter plots with selectable measurements, color grouping, and optional faceting.
  - **Variability:** RSD heatmaps with selectable measurements and grouping variables.

The sidebar includes study and strength selections and two optional numerical range filters. Clicking **Apply Filters** updates the dataset used throughout the app. Graph controls update the selected graph using that applied dataset.

The CSV download includes the full applied dataset. Searching or paging within the displayed table affects only the table display.

RSD is calculated as 100 × standard deviation / mean. Each heatmap cell summarizes the available readings within its selected group combination and may pool measurements across lots and studies.

## Running the app locally

1. Clone or download this repository.
2. Open `ST558_Project2.Rproj` in RStudio.
3. Install the required packages in the R Console if they are not already installed:

   ```r
   install.packages(c(
     "shiny", "readxl", "dplyr", "ggplot2", "DT", "shinycssloaders"
   ))
   ```

4. Open `app.R` and click **Run App**.

Keep the `data` and `www` folders in the project directory so the app can locate the workbook and tablet press image.

## Repository files

- `ST558_Project2.Rproj` opens the project in RStudio.
- `data/tablet_ipc_deidentified.xlsx` contains the dataset and supporting worksheets.
- `data_exploration.R` contains the static data exploration developed before building the app.
- `app.R` contains the Shiny app's interface, data preparation, and server logic.
- `www/tablet_press.jpg` contains the tablet press image displayed on the About tab.
