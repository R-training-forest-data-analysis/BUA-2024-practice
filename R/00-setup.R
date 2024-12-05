
## Load packages, install if necessary
load_pkg <- function(.pkg_name){
  if (!require(.pkg_name, character.only = TRUE, quietly = TRUE)) {
    install.packages(.pkg_name, dep =TRUE)
    library(.pkg_name, character.only = TRUE, quietly = TRUE)
  }
}

load_pkg("tidyverse")
load_pkg("readxl")
load_pkg("tictoc")



# ## Load data - NOT USED
# path <- "data/example2_simp.xlsx"
# 
# cs <- read_xlsx(path = path, sheet = "c_stocks", na = "NA")
# ad <- read_xlsx(path = path, sheet = "AD_lu_transitions", na = "NA")
# time <- read_xlsx(path = path, sheet = "time_periods", na = "NA")
# usr  <- read_xlsx(path = path, sheet = "user_inputs", na = "NA") 



# ## Simulation results - NOT USED
# calc_res <- function(.sims, .alpha){
# 
#   tibble(
#     E = median(.sims),
#     E_cilower = quantile(.sims, .alpha / 2),
#     E_ciupper = quantile(.sims, 1 - .alpha / 2)
#   ) |>
#     mutate(
#       E_ME = (E_ciupper - E_cilower) / 2,
#       E_U  = E_ME / E * 100
#     )
# 
# }
