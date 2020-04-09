#read library
library(readr)
library(dplyr)
library(tidyr)
library(stringr)
library(ggplot2)
library(data.table)
library(reshape2)

#read csv file
fandango_comparison <- read_csv("fandango_score_comparison.csv")
movie_ratings <- read_csv("movie_ratings_16_17.csv")

fandango_2015 <- fandango_comparison %>% select('FILM', 'Fandango_Stars', 'Fandango_Ratingvalue', 
                                 'Fandango_votes', 'Fandango_Difference')
fandango_2017 <-movie_ratings %>% select('movie', 'year', 'fandango')

head(fandango_2015)
head(fandango_2017)

fandango_2015 <- fandango_2015 %>% mutate(year = str_sub(FILM,-5, -2))
fandango_2015 %>% group_by(year) %>% summarize(Freq = n())
# we need only movie(2015)
fandango_2015 <- fandango_2015 %>% filter(year == 2015)
nrow(fandango_2015)


table(movie_ratings $year)


#we need only movie(2016)
fandango_2016 <- movie_ratings %>% filter(year == 2016)
table(fandango_2016$year)


ggplot(data = fandango_2015, aes(x = Fandango_Stars)) +
  geom_density() +
  geom_density(data = fandango_2016, aes(x = fandango), color = "orange") +
  labs(title = "Comparison of fandango ratings between 2015 and 2016",
       x = "Fandango_Stars",
       y = "density") +
  scale_x_continuous(breaks = seq(0, 5, by = 0.5), limits = c(0,5))


fandango_2015 %>% group_by(Fandango_Stars) %>% 
  summarise(percentage = n() / nrow(fandango_2015) * 100)

fandango_2016 %>% group_by(fandango) %>% 
  summarize(percentage = n() / nrow(fandango_2016) * 100)
#in 2016, movies with a rating of 4.5-5 were reduced.  

mode <- function(x) {
  ux <- unique(x)
  ux[which.max(tabulate(match(x, ux)))]
}

fandango_summary_2015 <- fandango_2015 %>% summarize(year = "2015", 
                                                     mean = mean(Fandango_Stars),
                                                     median = median(Fandango_Stars),
                                                     mode = mode(Fandango_Stars))
fandango_summary_2016 <- fandango_2016 %>% summarize(year = "2016",
                                                     mean = mean(fandango),
                                                     median = median(fandango),
                                                     mode = median(fandango))
summary_2015_2016 <- bind_rows(fandango_summary_2015, fandango_summary_2016)

summary_2015_2016 <- melt(summary_2015_2016, id = "year")

ggplot(data = summary_2015_2016, aes(x = variable, y = value, fill = year)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(title = "Comparing summary statistics: 2015 vs 2016",
       x = "",
       y = "Stars")
#Looking at the plot, the average grade has decreased by about 0.5 compared to 2015.
means <- summary_2015_2016 %>% 
  filter(variable == "mean")
means %>% 
  summarize(change = (value[1] - value[2]) / value[1])
#movies released in 2016 were rated lower than movies released in 2015
#the chances are very high that it was caused by Fandango fixing the biased rating system