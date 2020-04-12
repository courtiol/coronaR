#' Augment the data for better ploting
#'
#' @param data_ranked the dataset built with [`compare_last_2_rankings`]
#'
#' @return the dataset with everything needed for the plot (and some more)
#'
augment_data_plot <- function(data_ranked) {

  ## we add country labels based on last rank:
  data_ranked %>%
    dplyr::mutate(country_label = paste(.data$country, "-", .data$rank_last_report),
                  country_label =  gsub(pattern = "_", replacement = " ", x = .data$country_label),
                  country_label = forcats::fct_reorder(.data$country_label, -.data$rank_last_report)) -> data_plot_raw

  ## we add data labels:
  levels_days <- c("last day", "last week", "last 14d", ">14 days")

  data_plot_raw %>%
    dplyr::mutate(date_simple = paste(lubridate::month(date, label = TRUE, abbr = FALSE),
                                      lubridate::day(date), sep = " "),
                  date_cat = dplyr::case_when(
                    days_since_date == 0  ~ levels_days[1],
                    days_since_date  < 7  ~ levels_days[2],
                    days_since_date  < 15 ~ levels_days[3],
                    days_since_date >= 15 ~ levels_days[4],
                    TRUE ~ NA_character_),
                  date_cat = factor(.data$date_cat, levels = !!levels_days),
                  cumul_span = paste0(.data$date_report, " -> ", .data$date_first_10_cumul_deaths),
                  cumul_span = dplyr::if_else(is.na(.data$date_first_10_cumul_deaths),
                                              NA_character_,
                                              .data$cumul_span))  -> data_plot

  ## output:
  data_plot
}


#' A wrapper to faciliate the preparation of the data for the plot
#'
#' This function is a wrapper successively calling [`merge_datasets`],
#' [`prepare_data_with_rank`], [`compare_last_2_rankings`], [`augment_data_plot`]
#' and then selecting what is needed for the plot.
#'
#' @inheritParams merge_datasets
#'
#' @return the dataset with just what is needed for the plot (and no more)
#' @export
#'
prepare_data_plot <- function(data_ECDC,
                              data_WB,
                              type = c("daily", "cumul"),
                              baseline = c("country", "world"),
                              select = c("worst_day", "last_day")) {

  ## we combine the two sources of data:
  data_combined <- merge_datasets(data_ECDC = data_ECDC,
                                  data_WB = data_WB,
                                  type = type[1],
                                  baseline = baseline[1],
                                  select = select[1]) ## checked -> OK

  ## we prepare the rank of the last day, of previous day and their difference:
  data_ranked <- prepare_data_with_rank(data_combined = data_combined) ## checked -> OK
  data_ranked2 <- compare_last_2_rankings(data_ranked = data_ranked) ## checked -> OK

  ## we add nice columns for pretty plotting:
  data_plot_raw <- augment_data_plot(data_ranked = data_ranked2)

  ## clean up:
  data_plot_raw %>%
    dplyr::select(.data$date_report,
                  .data$country,
                  .data$country_label,
                  .data$continent,
                  extra_mortality = .data$extra_mortality_last_report,
                  diff_ranks = .data$diff_ranks_pretty,
                  date = .data$date_simple,
                  .data$date_cat) -> data_plot

  ## output:
  data_plot
}


#' Create the data for plotting mortality and draw the plot
#'
#' This function calls [`prepare_data_plot`] (up to) twice to prepare (up to) 2 different
#' datasets to be plotted.
#'
#' The so-called major dataset is the one used to rank the country.
#' The so-called is used to add information within each horizontal bars.
#' The typical usage is to use the major dataset to represent the mortality at their worst,
#' and to use the minor dataset to represent the mortality of the last date. Yet,
#' this can be used to represent other combinations.
#'
#' @inheritParams merge_datasets
#' @param type_major either `"daily"` (for daily deaths) or `"cumul"` (for cumulative deaths)
#' @param type_minor same for minor dataset (see Details)
#' @param baseline_major either `"country"` (for correcting by the baseline mortality in the country), or `"world"` (for correcting all countries by the same baseline mortality)
#' @param baseline_minor same for minor dataset (see Details)
#' @param select_major either `"worst_day"` (for measuring mortality at its worst) or `"last_day"` (for measuring mortality at the last day in the report considered)
#' @param select_minor same for minor dataset (see Details)
#' @param alpha_major a number betweeen 0 and 1 defining the transparency
#' @param alpha_minor same for minor dataset (see Details)
#' @param title the title for the plot
#' @param return_plot either FALSE (default) for returning data or TRUE for returning the plot so to modify it
#'
#' @return the data used for the plot (invisibly) or the plot (invisibly) depending on the argument `return_plot`
#' @export
#'
plot_deaths <- function(data_ECDC,
                        data_WB,
                        type_major = c("daily", "cumul"),
                        type_minor = NULL,
                        baseline_major = c("country", "world"),
                        baseline_minor = NULL,
                        select_major = c("worst_day", "last_day"),
                        select_minor = NULL,
                        alpha_major = 0.5,
                        alpha_minor = 1,
                        title = "",
                        return_plot = FALSE) {

  data_for_plot_major <- prepare_data_plot(data_ECDC = data_ECDC,
                                           data_WB = data_WB,
                                           type = type_major[1],
                                           baseline = baseline_major[1],
                                           select = select_major[1])

  if (!is.null(type_minor) && !is.null(baseline_minor) && !is.null(select_minor)) {
    data_for_plot_minor <- prepare_data_plot(data_ECDC = data_ECDC,
                                             data_WB = data_WB,
                                             type = type_minor[1],
                                             baseline = baseline_minor[1],
                                             select = select_minor[1])
  } else {
    data_for_plot_minor <- NULL
  }

  minor <- !is.null(data_for_plot_minor)

  ## select from the datasets what we need from minor and add it to major:
  if (minor) {
    data_for_plot_minor %>%
      dplyr::select(.data$country, extra_mortality_minor = .data$extra_mortality) -> data_for_plot_minor2
    data_for_plot_major %>%
      dplyr::left_join(data_for_plot_minor2, by = "country") -> data_for_plot_raw
  } else {
    data_for_plot_major -> data_for_plot_raw
  }

  ## select worst 30
  data_for_plot_raw %>%
    dplyr::slice_max(.data$extra_mortality, n = 30, with_ties = FALSE) -> data_plot

  ## define xmax
  xmax <- 10 + round(0.1*safe_max(data_for_plot_raw$extra_mortality)) * 10
  xmax <- xmax + xmax %% 20

  ## define theme:
  ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(panel.grid.major.y = ggplot2::element_blank(),
                   plot.caption = ggplot2::element_text(hjust = 0, colour = "darkgrey"),
                   plot.caption.position = "plot",
                   plot.title = ggplot2::element_text(hjust = 0.5),
                   plot.subtitle = ggplot2::element_text(hjust = 0.5, face = "italic"),
                   plot.tag = ggplot2::element_text(face = "italic", size = 10, colour = "red", hjust = 0),
                   plot.tag.position = c(0, 1),
                   legend.key.width = ggplot2::unit(0.4, "cm"),
                   legend.key.height = ggplot2::unit(0.4, "cm"),
                   legend.title = ggplot2::element_text(size = 9, face = "italic", margin = ggplot2::margin(b = 0.1, unit = "cm")),
                   legend.text = ggplot2::element_text(size = 8)) -> theme_coronaR

  ## plot
  data_plot %>%
    ggplot2::ggplot() +
    ggplot2::aes(x = .data$extra_mortality,
                 y = .data$country_label,
                 label = .data$date,
                 fill = .data$continent) +
    ggplot2::geom_col(alpha = ifelse(minor, 0.6, 1)) +
    ggplot2::geom_text(ggplot2::aes(label = .data$diff_ranks, x = 0),
                       size = 2.5, hjust = 1, fontface = "bold") +
    ggplot2::geom_text(ggplot2::aes(colour = .data$date_cat), size = 2, nudge_x = 0.2, hjust = 0) +
    ggplot2::scale_colour_manual(values = c("red", "orange", "blue", "darkgreen"),
                                 drop = FALSE,
                                 guide = ggplot2::guide_legend(override.aes = list(label = levels(data_plot$date_cat)),
                                                               label = FALSE, nrow = 1, keywidth = 1, unit = "cm")) +
    ggplot2::scale_x_continuous(breaks = seq(0, xmax, by = 20), limits = c(0, xmax)) +
    # ggplot2::scale_fill_hue(h.start = 220, c = 80, drop = FALSE) +
    # palette = ggplot2::scale_color_hue(h.start = 220, c = 80)$palette(5)
    ggplot2::scale_fill_manual(values = c(Africa = "#9CA600",
                                          Americas = "#E88170",
                                          Asia = "#DD78DE",
                                          Europe = "#00AAE8",
                                          Oceania = "#00BA8B"),
                               drop = FALSE) +
    ggplot2::labs(title = title,
                  tag = paste0("Update ", max(data_plot$date_report)),
                  subtitle = "Most affected 30 countries with more than 2,000,000 inhabitants",
                  caption = "Data processed by @alexcourtiol and downloaded from:\n - European Centre for Disease Prevention and Control for death counts attributed to COVID19 (direct download)\n - World Bank for yearly mortality per country (via R package {wbstats})\n For the R code and explanations on how to interpret the x-axis, please visit https://github.com/courtiol/coronaR",
                  x = "Deaths caused by COVID-19 per 100 deaths due to all other causes", y = "",
                  fill = "Continent",
                  colour = "Date of worst day") +
    theme_coronaR -> plot_temp

  ## add minor plot:
  if (minor) {
    plot_temp +
      ggplot2::geom_col(ggplot2::aes(x = .data$extra_mortality_minor)) -> plot_temp2
  } else {
    plot_temp -> plot_temp2
  }

  ## print:
  print(plot_temp2)

  ## output
  if (return_plot) return(invisible(plot_temp))
  invisible(data_for_plot_raw)
}
