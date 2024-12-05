
## Get packages and data
source("R/00-setup.R")

conf_level <- 0.9
ci_alpha   <- 1 - conf_level

## 1. rnorm() ======

sims <- rnorm(10, mean = 100, sd = 10)

mean(sims)
median(sims)
sd(sims)
quantile(sims, ci_alpha/2)
quantile(sims, 1 - ci_alpha/2)
hist(sims)


## 2. apply to REDD+ carbon accounting ======
calc_res <- function(.sims, .alpha){
  
  tibble(
    E = median(.sims),
    E_cilower = quantile(.sims, .alpha / 2),
    E_ciupper = quantile(.sims, 1 - .alpha / 2)
  ) |>
    mutate(
      E_ME = (E_ciupper - E_cilower) / 2,
      E_U  = E_ME / E * 100
    )
  
}

test_data <- cs |> filter(lu_id == "EV", c_pool == "AGB")

## run simulations
n_iter <- 10^4
set.seed(123)
tic()
sims_ev_agb <- rnorm(n_iter, test_data$c_value, test_data$c_se)
calc_res(.sims = sims_ev_agb, .alpha = ci_alpha)
toc()

## !!! EX
## + Run from 10 to 10 million simulation and record the time it takes to process
## + Run 10^4 simulations for:
##    - AGB of Mountain forest 
##    - RS of Mountain forest
##    - RS of  EV forest


## 3. Combine ======

## Demo.
## - Create vector of possible carbon stock elements for EV
## - Loop through the data and generate the simulations
## - Calculate carbon stock


## 3.1 Get data and a vector of pools ----
cs_sub <- cs |> filter(lu_id == "EV")

c_pool <- cs_sub$c_pool


## 3.2 Start seed ----
set.seed(123)

## 3.3 Simulate CF ----
sims_CF <- rnorm(n_iter, usr$c_fraction, usr$c_fraction_se)

## 3.4 Simulate pools ----
sims_pools_EV <- map(c_pool, function(x){
  
  ## TESTING ONLY
  # x = "AGB"
  MEAN <- cs_ev |> filter(c_pool == x) |> pull(c_value)
  SE   <- cs_ev |> filter(c_pool == x) |> pull(c_se)
  
  sim_df <- data.frame(SIMS = rnorm(n_iter, MEAN, SE))
  names(sim_df) <- x
  
  ## Check
  # hist(sim_df[[x]])
  
  sim_df
  
}) |> list_cbind() |> as_tibble()
  
## 3.5 Calculate carbon stock ----  
sims_C_EV <- sims_pools_EV |>
  mutate(
    sim_no = 1:n_iter,
    CF = sims_CF,
    BGB = AGB * RS,
    C_all = (AGB + BGB) * CF,
    C_form = "AGB * (1 + RS) * CF",
    lu_id = "EV"
  ) |>
  select(sim_no, lu_id, C_all, C_form, everything())

sims_C_EV
calc_res(.sims = sims_C_EV$C_all, .alpha = ci_alpha)


## 4. EX: simulate values for mountain forest ======

## Follow the same steps as 3. 


## 5. Simulate values for Crop ======
cs_crop <- cs |> filter(lu_id == "Crop")

sims_C_Crop <- tibble(
  sim_no = 1:n_iter,
  lu_id = "Crop",
  C_all = rnorm(n_iter, cs_crop$c_value, cs_crop$c_se),
  C_form = "ALL"
  )

## 6. Add degradation ======
cs_sub <- cs |> filter(lu_id == "EV_deg", c_pool == "DG_ratio")

tmp_sims_C_EV <- sims_C_EV |> select(sim_no, C_all)

sims_C_EV_deg <- tibble(
  sim_no = 1:n_iter,
  lu_id = "EV_deg",
  DG_ratio = rbeta(n_iter, cs_sub$c_pdf_a, cs_sub$c_pdf_b),
) |> 
  left_join(tmp_sims_C_EV, by = "sim_no") |>
  mutate(
    C_all = C_all * DG_ratio,
    C_form = "DG_ratio * C_all_intact"
  ) |>
  select(sim_no, lu_id, C_all, C_form, everything())

rm(tmp_sims_C_EV)


## !!! EX
## + Create degradation simulations for Mountain forest
## !!!



## 7. Combine all Carbon ======
list_sims <- str_subset(ls(), pattern = "sims_C_")

sims_C <- bind_rows(mget(list_sims))

table(sims_C$lu_id)

write_csv(sims_C, "results/sims_C_seed123.csv")


## 8. AD and E ======

## Check trans ids are unique
all(unique(ad$trans_id) == ad$trans_id)

vec_trans <- ad$trans_id

sims_E <- map(vec_trans, function(x){
  
  ## TESTING ONLY
  # x = "T2_EV_EV_deg"
  
  ## Simulate AD
  ad_sub <- ad |> filter(trans_id == x)
  
  sims_AD <- tibble(
    sim_no = 1:n_iter,
    time_period = ad_sub$trans_period,
    redd_activity = ad_sub$redd_activity,
    AD = rnorm(n_iter, ad_sub$trans_area, ad_sub$trans_se)
  )
  
  ## Prepare EF
  sims_CI <- sims_C |> filter(lu_id == ad_sub$lu_initial_id)
  sims_CF <- sims_C |> filter(lu_id == ad_sub$lu_final_id)
  
  ## Combine simulations and calculate EF and E
  combi <- sims_AD |>
    dplyr::left_join(sims_CI, by = "sim_no") |>
    dplyr::left_join(sims_CF, by = "sim_no", suffix = c("_i", "_f"))
  
  combi |>
    mutate(
      EF = (C_all_i - C_all_f) * 44 / 12,
      E  = round(AD * EF, 0)
    ) |>
    select(sim_no, time_period, redd_activity, lu_id_i, lu_id_f, E, AD, EF, C_all_i, C_all_f, everything())
  
}) |> list_rbind()

sims_E


## SAVE RESULTS
write_csv(sims_E, "results/sims_E_trans.csv")

