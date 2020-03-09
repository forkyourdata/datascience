#Read packages
library(readr)
library(ggplot2)
library(dplyr)
library(purrr)
library(DescTools)

#Read csv file
forestfires <- read_csv("forestfires.csv")
View(forestfires)

#  change the data type 
forestfires <- forestfires %>%
  mutate(month = factor(month, levels = c("jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep",
                                          "oct", "nov", "dec")), day = factor(day, levels = c("sun", "mon", "tue", "wed", "thu", "fri", "sat")))

forestfires_month <- forestfires %>% group_by(month) %>% summarize(total = n())

forestfires_day <- forestfires %>% group_by(day) %>% summarize(total = n())

x_month <- names(forestfires)[3]
x_day <- names(forestfires)[4]
FWI_components <- names(forestfires)[5:12]
y_area <- names(forestfires)[13]

#bar_chart_month

ggplot(data = forestfires_month) + aes(x = month, y = total) + geom_bar(stat = "identity")

#bar_chart_day

ggplot(data = forestfires_day) + aes(x = day, y = total) + geom_bar(stat = "identity")



#box_plot_month

box_chart <- function(x,y){
  ggplot(data = forestfires) + 
    aes_string(x = x, y = y) +
    geom_boxplot() + theme(panel.background = element_rect(fill="white"))
}

month_box_chart <-map2(x_day, FWI_components, box_chart)
month_box_chart

# scatter plot
scatter_chart <- function(x,y){
  ggplot(data = forestfires) + 
    aes_string(x = x, y = y) +
    geom_point() + theme(panel.background = element_rect(fill="white"))
}

FWI_area_scatter <-map2(FWI_components, y_area, scatter_chart)
FWI_area_scatter


ggplot(data = forestfires) + aes(x = area) + geom_histogram()
# but this graph contains very high values


# let's except for rows with zero values & very high values of area
forest_fires_area <- forestfires %>% filter(area>0 & area < 300)

ggplot(data = forest_fires_area) + aes(x = area) + geom_histogram()









