#' Download and prepare the data from the European Centre for Diseases Prevention and Control
#'
#' @param date_of_report the date of the report to download and process (of format Date)
#' @param path_save_data the path where to save the data file (without trailing "/")
#' @param .skip_download TRUE if you do not not want to download and use directly a file of the right name stored in path_save_data.
#'
#' @return a tidy ECDC dataset
#' @export
#'
prepare_data_ECDC <- function(date_of_report = Sys.Date(), path_save_data = NULL, .skip_download = FALSE) {

  if (is.null(path_save_data)) {
    stop("you must set the path_save_data argument")
  }

  ## ECDC = European Centre for Diseases Prevention and Control

  ## we download COVID-19 data from https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-disbtribution-worldwide-2020-03-17.xlsx:

  if (!dir.exists(path_save_data)) {
    dir.create(path_save_data)
  }
  data_COVID_basefile <- paste0(path_save_data, "/COVID-19-geographic-disbtribution-worldwide-", date_of_report)
  weblink_COVID_baselfile <- paste0("https://www.ecdc.europa.eu/sites/default/files/documents/COVID-19-geographic-disbtribution-worldwide-", date_of_report)
  data_COVID_full_path_local <- paste0(data_COVID_basefile, ".xlsx")
  data_COVID_full_path_online <- paste0(weblink_COVID_baselfile, ".xlsx")

  if (!.skip_download) {
    ## download file:
    downloadOK <- utils::download.file(data_COVID_full_path_online,
                                       destfile = data_COVID_full_path_local,
                                       mode = "wb")
    if (downloadOK != 0) stop("Download failed, perhaps the report is not yet out...")

    message(paste0("The source of the COVID data have been stored in", data_COVID_full_path_local, "!"))
  }

  ## read file:
  data_COVID_raw <- readxl::read_xlsx(paste0(data_COVID_basefile, ".xlsx"))

  if (!tibble::is_tibble(data_COVID_raw)) stop("The reading of the xlsx file failed...")


  ## we add info about continents:
  data_COVID_raw %>%
    dplyr::rename(Country = "countriesAndTerritories") %>%
    dplyr::mutate(iso2c = dplyr::case_when(.data$geoId %in% unique(countrycode::codelist$iso2c) ~ .data$geoId,
                                           .data$geoId == "UK" ~ "GB",
                                           .data$geoId == "XK" ~ "XK",
                                           .data$geoId == "EL" ~ "GR",
                                           TRUE ~ NA_character_),
                  continent = dplyr::if_else(.data$iso2c == "XK", ## Kosovo is not present in the list
                                             "Europe",
                                             ## We extract the continents using {countrycode}
                                             countrycode::countrycode(.data$iso2c, origin = "iso2c", destination = "continent")),
                  continent = factor(.data$continent, levels = c("Africa", "Americas", "Asia", "Europe", "Oceania"))) %>%
    dplyr::select(-.data$geoId, -.data$countryterritoryCode) %>%
    dplyr::rename_all(tolower) %>%
    dplyr::rename(daterep = 1) -> data_COVID_raw2 ## sometimes first column contains something else


  ## we improve info about dates:

  ###Template to fix missing dates
  data_COVID_raw2 %>%
    dplyr::mutate(date_report = as.Date(.data$daterep)) %>%
    dplyr::group_by(country) %>%
    dplyr::summarise(date_report = list(!!date_of_report:min(date_report)),
                     continent = unique(continent),
                     iso2c = unique(iso2c),
                     continentexp = unique(continentexp),
                     popdata2018 = unique(popdata2018)) %>%
    tidyr::unnest(cols = date_report) %>%
    dplyr::mutate(date_report = as.Date(date_report, origin = "1970-01-01")) -> full_country_dates

  data_COVID_raw2 %>%
    dplyr::mutate(date_report = as.Date(.data$daterep)) %>%
    dplyr::right_join(full_country_dates, by = c("country", "popdata2018", "continentexp", "iso2c", "continent", "date_report")) %>%
    dplyr::mutate(days_since_report = !!date_of_report - as.Date(.data$date_report)) %>%
    dplyr::group_by(.data$country) %>%
    dplyr::mutate(date_report_last = max(.data$date_report, na.rm =  TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::select(-.data$daterep, -.data$day, -.data$month, -.data$year) -> data_COVID_raw3

  ## we improve info about deaths:
  data_COVID_raw3 %>%
    dplyr::mutate(deaths = ifelse(is.na(deaths), 0, deaths),
                  cases = ifelse(is.na(cases), 0, cases)) %>%
    dplyr::group_by(.data$country) %>%
    dplyr::arrange(.data$date_report, .by_group = TRUE) %>%
    dplyr::mutate(deaths_cumul = cumsum(.data$deaths),
                  date_first_10_cumul_deaths = .data$date_report[which(.data$deaths_cumul >= 10)[1]]) %>%
    #dplyr::group_by(.data$country, .data$date_report) %>%  ## we remove some rare duplicates -> no longer needed
    #dplyr::slice(which.max(.data$cases)[1]) %>% ## we remove some rare duplicates -> no longer needed
    dplyr::ungroup() %>%
    dplyr::arrange(country, dplyr::desc(date_report)) %>%
    dplyr::rename(deaths_daily = .data$deaths) -> data_COVID4

  ## we select and reorder the columns for clarity:
  data_COVID4 %>%
    dplyr::select(.data$country,
                  .data$iso2c,
                  .data$continent,
                  .data$date_report,
                  .data$date_report_last,
                  .data$cases,
                  .data$deaths_daily,
                  .data$deaths_cumul,
                  .data$date_first_10_cumul_deaths) -> data_COVID

  ## output
  data_COVID
}

