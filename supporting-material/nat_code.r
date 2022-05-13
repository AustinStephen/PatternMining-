#Pattern forecasting on financial data, Natalie Foss

library(PSF)
library(dplyr)
library(tidyr)
library(tidyverse)

# reading in data and generating train and test split
post_1950 <- read.csv("~/Documents/ml/finalProject/repo/data/SMP500_post_1950.csv")

# making a month col
post_1950 <- post_1950 %>%
  dplyr::mutate(month = lubridate::day(date),
                year = lubridate::year(date))
post_1950 <- select(post_1950, c("month", "year", "date", "residualsCube"))

summary(post_1950)

# train set
train <- post_1950[post_1950$date >= "1951-01-01" & post_1950$date < "2005-01-01", ]
train <- select(train, c("month", "year", "residualsCube"))
train <- train %>% pivot_wider(
  names_from = month, 
  values_from = residualsCube
)

trainYearVec <- train$year
train <- select(train, c("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"))
#rownames(train) <- trainYearVec


# test set
test <- post_1950[post_1950$date >= "2005-01-01", ]
test <- select(test, c("month", "year", "residualsCube", "date"))
nrow(test)

# subtrain set
subtrain <- post_1950[post_1950$date >= "1951-01-01" & post_1950$date < "2000-01-01", ]
subtrain <- select(subtrain, c("month", "year", "residualsCube"))
subtrain <- subtrain %>% pivot_wider(
  names_from = month, 
  values_from = residualsCube
)
# subtrainYearVec <- subtrain$year
subtrain <- select(subtrain, c("1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12"))

# Validation set
valid <- post_1950[post_1950$date >= "2000-01-01" & post_1950$date < "2005-01-01", ]
valid <- select(valid, c("month", "year", "residualsCube", "date"))
nrow(valid)

# building model using psf() function
model <- psf(train, cycle = 12)
model

# performing predictions:
smp_preds <- predict(model, n.ahead = 160)
smp_preds <- smp_preds[1:160]
smp_preds

test["preds"] <- smp_preds

# creating model for rmse
rmse_model <- psf(subtrain, cycle = 12)
rmse_model

# performing predictions for rmse:
rmse_smp_preds <- predict(rmse_model, n.ahead = 60)
rmse_smp_preds <- rmse_smp_preds[1:60]
rmse_smp_preds

valid["preds"] <- rmse_smp_preds
rmse <- sqrt(mean((valid$residualsCube - valid$preds)^2))
rmse

# plots
plot.psf(model, smp_preds)

test %>% ggplot(aes(x=date,y=residualsCube))+
  geom_point()+
  geom_point(aes(y = test$preds, color = "red"), size = .5)+
  theme_classic() +
  theme(
    axis.ticks.x = element_blank(),
    axis.text.x = element_blank()
  ) +
  labs(title = "PSF Predictions With Truth Values") +
  xlab("Time (months)") +
  ylab("ResidsCubed")


tmp <- select(test, c("preds"))

write.csv(tmp,"~/Documents/ml/finalProject/repo/data/nat_predictions.csv", row.names = TRUE)

