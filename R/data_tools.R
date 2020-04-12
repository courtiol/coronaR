#' Merge the dataset from ECDC with that of WB
#'
#' @param data_ECDC the dataset built with [`prepare_data_ECDC`]
#' @param data_WB the dataset built with [`prepare_data_WB`]
#' @param type either `"daily"` (for daily deaths) or `"cumul"` (for cumulative deaths)
#' @param baseline either `"country"` (for correcting by the baseline mortality in the country), or `"world"` (for correcting all countries by the same baseline mortality)
#' @param select either `"worst_day"` (for measuring mortality at its worst) or `"last_day"` (for measuring mortality at the last day in the report considered)
#'
#' @return a `tibble` with all the raw data
#' @export
#'
merge_datasets <- function(data_ECDC, data_WB,
                           type = c("daily", "cumul"),
                           baseline = c("country", "world"),
                           select = c("worst_day", "last_day")) {

  ## we merge the two datasets:
  data_ECDC %>%
    dplyr::inner_join(data_WB, by = "iso2c") %>%
    dplyr::rename(country = .data$country.x) %>%
    dplyr::arrange(.data$country, dplyr::desc(.data$date_report)) -> full_data_raw

  ## we remove useless columns:
  full_data_raw %>%
    dplyr::select(-.data$iso2c, -.data$country.y) -> full_data_raw2

  ## we improve information about deaths:
  full_data_raw2 %>%
    dplyr::mutate(days_since_first_10_cumul_deaths = .data$date_report - .data$date_first_10_cumul_deaths,
                  extra_mortality_daily_country = 100 * .data$deaths_daily/.data$total_death_day,
                  extra_mortality_cumul_country = 100 * .data$deaths_cumul/(.data$total_death_day * (as.numeric(.data$days_since_first_10_cumul_deaths) + 1)),
                  extra_mortality_cumul_country = dplyr::if_else(as.numeric(.data$days_since_first_10_cumul_deaths) < 0, NA_real_, .data$extra_mortality_cumul_country),
                  country_weight = .data$country_pop / .data$world_pop,
                  extra_mortality_daily_world = 100 * .data$deaths_daily/(.data$country_weight * .data$total_death_day_world),
                  extra_mortality_cumul_world = dplyr::if_else(.data$days_since_first_10_cumul_deaths >= 0,
                                                               100 * .data$deaths_cumul/(.data$country_weight * .data$total_death_day_world * (as.numeric(.data$days_since_first_10_cumul_deaths) + 1)),
                                                               NA_real_)) -> full_data_raw3

  ## we retrieve the extra mortality for the correct baseline:
  full_data_raw3 %>%
    dplyr::mutate(extra_mortality = dplyr::case_when(type[1] == "daily" & baseline[1] == "country" ~ .data$extra_mortality_daily_country,
                                                     type[1] == "daily" & baseline[1] == "world" ~ .data$extra_mortality_daily_world,
                                                     type[1] == "cumul" & baseline[1] == "country" ~ .data$extra_mortality_cumul_country,
                                                     type[1] == "cumul" & baseline[1] == "world" ~ .data$extra_mortality_cumul_world,
                                                     TRUE ~ NA_real_)) -> full_data_raw4

  ## we retrieve the extra mortality for the worst before or at report date:
  if (select[1] == "worst_day") {
    full_data_raw4 %>%
      dplyr::arrange(.data$country, .data$date_report) %>% ## we reverse date order for cummax
      dplyr::group_by(.data$country) %>%
      dplyr::mutate(date = .data$date_report[which(.data$extra_mortality == safe_max(.data$extra_mortality))[1]],
                    extra_mortality = safe_cummax(.data$extra_mortality)) %>%
      dplyr::ungroup() -> full_data_raw5
  }

  if (select[1] == "last_day") {
    full_data_raw4 %>%
      dplyr::group_by(.data$country) %>%
      dplyr::mutate(date = .data$date_report) %>%
      dplyr::ungroup() -> full_data_raw5
  }

  ## we order by country and decreasing date:
  full_data_raw5 %>%
    dplyr::mutate(days_since_date = max(.data$date_report) - .data$date) %>%
    dplyr::arrange(.data$country, dplyr::desc(.data$date_report)) -> full_data

  ## output:
  full_data
}


#' Compute the ranks based on extra mortality and simplify data
#'
#' @note What the extra mortality represents depends on what has been done with [`merge_datasets`]
#'
#' @param data_combined the dataset built with [`merge_datasets`]
#'
#' @return a `tibble` with all the relevant data and the ranks for all days
#' @export
#'
prepare_data_with_rank <- function(data_combined) {

  ## we compute the ranks:
  data_combined %>%
    dplyr::group_by(.data$date_report) %>%
    dplyr::mutate(rank = rank(-.data$extra_mortality, ties.method = "min")) %>%
    dplyr::ungroup() %>%
    dplyr::select(.data$date_report, .data$country, .data$continent, .data$rank, .data$extra_mortality, .data$date, .data$days_since_date, .data$date_first_10_cumul_deaths, days_since_10 = .data$days_since_first_10_cumul_deaths) %>%
    dplyr::arrange(.data$date_report, .data$rank, .data$extra_mortality, .data$country) -> data_rank

  ## output:
  data_rank
}


#' Compare ranking between the extra mortality between the last report and the previous one
#'
#' @param data_ranked the dataset built with [`prepare_data_with_rank`]
#'
#' @return a `tibble` with all the relevant data and the ranks for 2 reporting days
#' @export
#'
compare_last_2_rankings <- function(data_ranked) {

  ## we focus on the information of last day:
  data_ranked %>%
    dplyr::filter(.data$date_report == max(.data$date_report)) %>%
    dplyr::select(-.data$rank, -.data$extra_mortality) -> data_last


  ## we focus on difference between last day and day before last:
  data_ranked %>%
    dplyr::filter(.data$date_report %in% c(max(.data$date_report), max(.data$date_report - 1))) %>%
    dplyr::select(.data$country, .data$date_report, .data$rank, .data$extra_mortality) %>%
    dplyr::arrange(.data$country) %>%
    tidyr::pivot_wider(values_from = c(.data$rank, .data$extra_mortality), names_from = .data$date_report) %>%
    dplyr::rename(rank_before_last_report = 2,
                  rank_last_report = 3,
                  extra_mortality_before_last_report = 4,
                  extra_mortality_last_report = 5) %>%
    dplyr::mutate(diff_ranks = -1*(.data$rank_last_report - .data$rank_before_last_report),
                  diff_ranks_pretty = dplyr::case_when(diff_ranks > 0 ~ paste0(diff_ranks, "↑ "),
                                                       diff_ranks < 0 ~ paste0(-diff_ranks, "↓ "),
                                                       diff_ranks == "0" ~ "= ",
                                                       TRUE ~ "new"), .after = .data$rank_last_report) %>%
    dplyr::arrange(.data$rank_last_report) -> data_compared

  ## we merge the datasets:
  data_last %>%
    dplyr::left_join(data_compared, by = "country") -> data_ranked

  data_ranked
}

#' Compute the maximum without failing
#'
#' This function attempts to solve some limitations of [`max`] as shown in example.
#'
#' @param x a numerical vector
#'
#' @return a scalar
#' @export
#'
#' @examples
#' safe_max(c(NA, NA))
#' safe_max(c(1, 2))
#' safe_max(c(NA, 1, 2))
#'
safe_max <- function(x) {
  if (all(is.na(x))) return(NA)
  max(x, na.rm = TRUE)
}

#' Compute the cumulative maximum without failing
#'
#' This function attempts to solve some limitations of [`cummax`] as shown in example.
#'
#' @inheritParams safe_max
#'
#' @return a numerical vector
#' @export
#'
#' @examples
#' safe_cummax(x = c(NA, NA, 1, 1, 2, 2, 3))
#' safe_cummax(x = c(NA, NA))
#'
safe_cummax <- function(x) {
  res <- rep(NA_real_, length(x))
  for (i in seq_len(length(x))) {
    res[i] <- safe_max(x[seq_len(i)])
  }
  res
}
