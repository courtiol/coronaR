#' Download and prepare the data from World Bank
#'
#' @param min_pop_size population size below which data will be dropped
#'
#' @return a tidy WB dataset
#' @export
#'
prepare_data_WB <- function(min_pop_size = 2e6) {

  ## we download new data from World Bank (WB):
  message("Downloading fresh data from World Bank, be patient...")
  new_cache <- wbstats::wbcache()

  ## we extract data from WB:
  data_pop_raw <- wbstats::wb(indicator = c("SP.POP.TOTL", "SP.DYN.CDRT.IN"),
                              startdate = 2010,
                              enddate = 2020, cache = new_cache)

  ## we only keep the info we need:
  data_pop_raw %>%
    dplyr::filter(.data$indicatorID %in% c("SP.DYN.CDRT.IN", "SP.POP.TOTL"),
                  .data$iso2c %in% c(countrycode::codelist$iso2c, "XK", "1W")) %>% ## we keep World and proper country, XK is code used here for Kosovo which differs from that in {countrycode}
    dplyr::select(.data$country, .data$iso2c, .data$date, .data$indicator, .data$indicatorID, .data$value) -> data_pop_raw2

  ## we only keep the most data corresponding to most recent mortality:
  data_pop_raw2 %>%
    dplyr::mutate(year = as.numeric(date)) %>%
    dplyr::arrange(.data$country) %>%
    dplyr::group_by(.data$country) %>%
    dplyr::mutate(focal_year = ifelse(
      !all(is.na(.data$year[.data$indicatorID == "SP.DYN.CDRT.IN"])),
      safe_max(.data$year[.data$indicatorID == "SP.DYN.CDRT.IN"]),
      NA)) %>%
    dplyr::ungroup() %>%
    dplyr::filter(.data$year == .data$focal_year) %>%
    dplyr::rename(year_mortality = .data$year) %>%
    dplyr::add_count(.data$country) %>%
    dplyr::filter(.data$n == 2) %>% ## only keep countries for which we have both mortality and pop size
    dplyr::select(-.data$focal_year, -.data$date, -.data$n) -> data_pop_raw3
  # data_pop_raw3 %>% dplyr::filter(year < 2018) ## all big countries have 2018 data! World is 2017

  ## we pivot the data to have variables in columns:
  data_pop_raw3 %>%
    tidyr::pivot_wider(-.data$indicator,
                       names_from = .data$indicatorID,
                       values_from = .data$value) -> data_pop_raw4

  ## we remove small countries for which numbers are unreliable:
  data_pop_raw4 %>%
    dplyr::filter(.data$SP.POP.TOTL > !!min_pop_size) -> data_pop_raw5


  ## we improve info about deaths:
  data_pop_raw5 %>%
    dplyr::mutate(total_death_year = .data$SP.DYN.CDRT.IN * .data$SP.POP.TOTL / 1000,
                  total_death_day = .data$total_death_year / 365,
                  total_death_year_world = .data$total_death_year[.data$country == "World"],
                  total_death_day_world = .data$total_death_day[.data$country == "World"],
                  country_pop = .data$SP.POP.TOTL,
                  world_pop = .data$SP.POP.TOTL[.data$country == "World"]) -> data_pop_raw6

  ## we clean up:
  data_pop_raw6 %>%
    dplyr::filter(.data$country != "World") %>%
    dplyr::select(-.data$SP.POP.TOTL, -.data$SP.DYN.CDRT.IN) -> data_pop

  ## output:
  data_pop
}
