
source("R/00-setup.R")

sims_E <- read_csv("results/sims_E_trans.csv")

ci_alpha <- 0.1

summary(sims_E$E)

## 1. Aggregate to REDD+ activities ======


sims_redd <- sims_E |>
  group_by(sim_no, time_period, redd_activity) |>
  summarise(E_redd = sum(E, na.rm = T), .groups = "drop") |>
  mutate(
    redd_id  = paste0(time_period, "-", redd_activity),
    nb_years = if_else(time_period == "T1", 5, 2),
    E_redd   = round(E_redd / nb_years, 0)
  )
  
summary(sims_redd$E_redd)

## Generate results
calc_res(.sims = sims_redd$E_redd, .alpha = ci_alpha)

res_redd <- map(unique(sims_redd$redd_id), function(x){
  
  ## TESTING ONLY
  # x = "T1-DF"
  
  sims_redd |> 
    filter(redd_id == x) |>
    pull(E_redd) |>
    calc_res(.alpha = ci_alpha) |>
    mutate(redd_id = x) |>
    select(redd_id, everything())
  
}) |> list_rbind()

res_redd


## 2. aggregate to time periods =======

sims_REF <- sims_E |>
  filter(time_period == "T1") |>
  group_by(sim_no) |>
  summarise(E_ref = sum(E, na.rm = T) / 5, .groups = "drop")

calc_res(.sims = sims_REF$E_ref, .alpha = ci_alpha)


## !!! EX
## + Aggregate simulations for the monitoring period in sims_MON
## + Calculate the result emission level with Uncertainty for the Monitoring period
## !!!


## 3. ERs ======

sims_ER <- left_join(sims_REF, sims_MON, by = "sim_no") |>
  mutate(ER = E_ref - E_mon)

calc_res(sims_ER$ER, ci_alpha)

