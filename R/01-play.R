
source("R/00-setup.R", local = TRUE)



## Basics R and Rstudio
## + graphic interface
## + read data
## + basic operations


## 1. Refresher: objects and data types ======

a <- c("a", "b", "c")
b <- c(1, 2, 3)
c <- c(4, 5, 6)
b + c


## 2. Work with Excel files ======

## Path to data
path <- "data/example2_simp.xlsx"

## Check tabs
readxl::excel_sheets(path)

## Load table
cs <- read_xlsx(path = path, sheet = "c_stocks", na = "NA")

## Visualize
cs
head(cs)
summary(cs$c_value)
table(cs$c_pool)

## !!! EX 
## + Read the activity data (land use transition tab) into an object call "ad"
## + check how many rows per time period and per REDD+ activities
## !!!


## Load more tables 
time <- read_xlsx(path = path, sheet = "time_periods", na = "NA")
usr  <- read_xlsx(path = path, sheet = "user_inputs", na = "NA") 



## 3. Basic calculations ======

## Calculate the number of years in each period
time2 <- time |> mutate(nb_years = year_end - year_start + 1)

## Filter data for calculations ======
cs_ev <- cs |> filter(lu_id == "EV")
cs_agb <- cs |> filter(c_pool == "AGB")

## Make a vector of unique land uses
lu_id_cs <- unique(cs$lu_id)
lu_id_ad <- unique(c(ad$lu_initial_id, ad$lu_final_id))

## Do they match?
lu_id_cs == lu_id_ad
all(lu_id_cs == lu_id_ad)


## !!! EX
## Get to know the data
## + make a vector 'c_pools' of unique carbon pools and other carbon ratios
## + create a subset "cs_mo" that contain carbon stock info for mountain forest


## 4. graphs ======

## Initial graph
ggplot(cs) +
  geom_point(aes(x = lu_id, y = c_value))

## Add pools as color 
ggplot(cs) +
  geom_point(aes(x = lu_id, y = c_value, color = c_pool))

## Make separate graphs for different pools
cs |>
  filter(c_pool == "RS") |>
  ggplot() +
  geom_point(aes(x = lu_id, y = c_value, color = c_pool))

## !!! EX
## + Make a graph to show degradation ratio of the different land uses
## + Make a graph to show area of land use transitions from 'ad' with different 
## + color for different time periods
## !!!

ad |>
  ggplot(aes(x = trans_id, y = trans_area, color = trans_period)) +
  geom_point()



## 5. advanced graphs ======
ad |>
  mutate(lu_change = paste0(lu_initial_id, "-", lu_final_id)) |>
  ggplot(aes(x = lu_change, y = trans_area, fill = trans_period)) +
  geom_col(position = position_dodge()) +
  scale_x_discrete(guide = guide_axis(n.dodge = 2)) + 
  theme_bw() +
  labs(
    x = "Land use change",
    y = "Area (ha)",
    fill = ""
  )
