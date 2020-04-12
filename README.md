
<!-- README.md is generated from README.Rmd. Please edit that file -->

# coronaR

The motivation for such an R package and the plots it produces is that
most people don’t know if X deaths caused by something is a lot or not.
Indeed, unless you are a demographer, you probably have no idea how many
people die in the world or even in your city, over a year, or over a
day. (If you want to know, a good rule of thumb is that over a given
year, in a “rich” country, you can expect roughly 1% of its whole
population to die.)

## How to read the x-axis?

Here I express the number of *reported* COVID19 deaths compared to 100
“normal” deaths.

For example, a value of 50 would imply that if 100 normal deaths used to
occur in a city, then we would observe 150 deaths in total (100 normal +
50 COVID19 ones) assuming that normal deaths have not changed.

This is more informative than expressing the result as a percentage: if
the COVID deaths reach very large numbers, we will still see on this
graph such an increase progressing linearly. Instead, expressed as a
percentage, the death toll would just slowly converge towards 100%.

If you still want to express such number as a percentage, just do:

If you still want to express such number as a percentage, just do `100 *
X/(100 + X)`. For example, with 50 COVID death per 100 normal ones, the
percentage of COVID death is thus 100 \* 50/150 = 33.333%.

If instead you want to instead express values along the x-axis as the
odd of dying from COVID, just divide the value X you read on the axis by
100: `(X / (100 + X))/(100 / (100 + X)) = X/100`. For example, with 50
COVID death per 100 normal ones, the odd of COVID death is thus 50/100 =
0.5.

### Daily vs cumulative deaths

The package allows to explore or plot either daily deaths or cumulated
deaths since a given country had reached a total of 10 deaths. Daily
deaths are susceptible to vary due to lags in reporting alone. For this
reason, I try to discount the lump reports from nursing homes when they
correspond to several days, but I cannot keep track of all of them.

Cumulative deaths are thus probably better since when the deaths are
being reported matters less.

### Baseline

When deaths are counted on a daily basis, the baseline is also computed
on a daily basis.

When deaths are cumulated, the baseline is computed using normal
mortality that would have occurred during the period between the date
when the country reached 10 cumulative total deaths and the date of the
report being analysed.

To count normal deaths and produce a baseline, the package allows you to
either use the most recent mortality data for the same country that is
analysed (2018), or to use the average mortality data from the entire
world (which is much higher than the country level one in the healthier
countries). The choice of the baseline impacts on the ranking.

### Why on Earth can cumulative mortality go down?

It is because the cumulative deaths are expressed relatively to the
baseline mortality that occurs during the same period. Therefore, if the
deaths caused by COVID19 pile up more slowly that the normal deaths,
then the relative measure shown in the plot can go down.

## Installation

You can install this package using **{remotes}** (or **{devtools}**):

``` r
remotes::install_github("courtiol/coronaR")
```

## Basic usage

### Load the package {coronaR}

``` r
library(coronaR)
```

### Create the data with the COVID mortality information

``` r
today <- Sys.Date() ## note: you can change the date, to rebuild plots retrospectively
data_COVID <- prepare_data_ECDC(path_save_data = "~/Downloads/COVID19",
                                date_of_report = today)
#> The source of the COVID data have been stored in~/Downloads/COVID19/COVID-19-geographic-disbtribution-worldwide-2020-04-12.xlsx!
#> Warning in countrycode::countrycode(.data$iso2c, origin = "iso2c", destination = "continent"): Some values were not matched unambiguously: XK
data_COVID
#> # A tibble: 10,332 x 9
#>    country iso2c continent date_report date_report_last cases deaths_daily
#>    <chr>   <chr> <fct>     <date>      <date>           <dbl>        <dbl>
#>  1 Afghan… AF    Asia      2019-12-31  2020-04-12           0            0
#>  2 Afghan… AF    Asia      2020-01-01  2020-04-12           0            0
#>  3 Afghan… AF    Asia      2020-01-02  2020-04-12           0            0
#>  4 Afghan… AF    Asia      2020-01-03  2020-04-12           0            0
#>  5 Afghan… AF    Asia      2020-01-04  2020-04-12           0            0
#>  6 Afghan… AF    Asia      2020-01-05  2020-04-12           0            0
#>  7 Afghan… AF    Asia      2020-01-06  2020-04-12           0            0
#>  8 Afghan… AF    Asia      2020-01-07  2020-04-12           0            0
#>  9 Afghan… AF    Asia      2020-01-08  2020-04-12           0            0
#> 10 Afghan… AF    Asia      2020-01-09  2020-04-12           0            0
#> # … with 10,322 more rows, and 2 more variables: deaths_cumul <dbl>,
#> #   date_first_10_cumul_deaths <date>
  
## NOTE: the following Warning is expected:
#Warning message:                                                                         
#  In countrycode::countrycode(.data$iso2c, origin = "iso2c", destination = "continent") :
#  Some values were not matched unambiguously: XK
```

### Small manual fix for lumped report of deaths

For daily plots, you may want to remove manually lump report of deaths
from nursing homes:

``` r
  data_COVID[data_COVID$country == "France" & data_COVID$date_report == "2020-04-04", "deaths_daily"] <- 1120
  data_COVID[data_COVID$country == "Belgium" & data_COVID$date_report == "2020-04-08", "deaths_daily"] <- 162
  data_COVID[data_COVID$country == "Belgium" & data_COVID$date_report == "2020-04-11", "deaths_daily"] <- 325
```

### Create the data with the baseline mortality information

``` r
data_baseline_mortality <- prepare_data_WB() ## the data do sometimes change from day to day!
#> Downloading fresh data from World Bank, be patient...
data_baseline_mortality
#> # A tibble: 147 x 9
#>    country iso2c year_mortality total_death_year total_death_day
#>    <chr>   <chr>          <dbl>            <dbl>           <dbl>
#>  1 Afghan… AF              2018          238758.           654. 
#>  2 Albania AL              2018           22639.            62.0
#>  3 Algeria DZ              2018          199149.           546. 
#>  4 Angola  AO              2018          252332.           691. 
#>  5 Argent… AR              2018          338559.           928. 
#>  6 Armenia AM              2018           29096.            79.7
#>  7 Austra… AU              2018          157391.           431. 
#>  8 Austria AT              2018           83985.           230. 
#>  9 Azerba… AZ              2018           57651.           158. 
#> 10 Bangla… BD              2018          892138.          2444. 
#> # … with 137 more rows, and 4 more variables: total_death_year_world <dbl>,
#> #   total_death_day_world <dbl>, country_pop <dbl>, world_pop <dbl>
```

### Create the plots:

To look at daily deaths, using the baseline mortality from each country:

``` r
plot_deaths(data_ECDC = data_COVID,
            data_WB = data_baseline_mortality,
            type_major = "daily",
            baseline_major = "country",
            select_major = "worst_day",
            type_minor = "daily",
            baseline_minor = "country",
            select_minor = "last_day",
            title = "Deaths by COVID19 on the worst and last day (dull & bright colour)\nrelative to baseline country mortality")
```

<img src="figures/README/plot1-1.png" width="100%" />

To look at daily deaths, using the baseline mortality from the world:

``` r
plot_deaths(data_ECDC = data_COVID,
            data_WB = data_baseline_mortality,
            type_major = "daily",
            baseline_major = "world",
            select_major = "worst_day",
            type_minor = "daily",
            baseline_minor = "world",
            select_minor = "last_day",
            title = "Deaths by COVID19 on the worst and last day (dull & bright colour)\nrelative to baseline worldwide mortality")
```

<img src="figures/README/plot2-1.png" width="100%" />

To look at cumulative deaths, using the baseline mortality from each
country:

``` r
plot_deaths(data_ECDC = data_COVID,
            data_WB = data_baseline_mortality,
            type_major = "cumul",
            baseline_major = "country",
            select_major = "worst_day",
            type_minor = "cumul",
            baseline_minor = "country",
            select_minor = "last_day",
            title = "Cumulative deaths by COVID19 on the worst and last day (dull & bright colour)\nrelative to baseline country mortality")
```

<img src="figures/README/plot3-1.png" width="100%" />

To look at cumulative deaths, using the baseline mortality from the
world:

``` r
plot_deaths(data_ECDC = data_COVID,
            data_WB = data_baseline_mortality,
            type_major = "cumul",
            baseline_major = "world",
            select_major = "worst_day",
            type_minor = "cumul",
            baseline_minor = "world",
            select_minor = "last_day",
            title = "Cumulative deaths by COVID19 on the worst and last day (dull & bright colour)\nrelative to baseline worldwide mortality")
```

<img src="figures/README/plot4-1.png" width="100%" />

## More advanced usage

### Do your own plot

The workhorse function that lead to tidy longitudinal series is
`merge_datasets()`. You can for example use it like that:

``` r
full_data <- merge_datasets(data_ECDC = data_COVID,
                            data_WB = data_baseline_mortality,
                            type = "daily",
                            baseline = "country",
                            select = "worst_day")
full_data
#> # A tibble: 8,235 x 24
#>    country continent date_report date_report_last cases deaths_daily
#>    <chr>   <fct>     <date>      <date>           <dbl>        <dbl>
#>  1 Afghan… Asia      2020-04-12  2020-04-12          34            3
#>  2 Afghan… Asia      2020-04-11  2020-04-12          37            0
#>  3 Afghan… Asia      2020-04-10  2020-04-12          61            1
#>  4 Afghan… Asia      2020-04-09  2020-04-12          56            3
#>  5 Afghan… Asia      2020-04-08  2020-04-12          30            4
#>  6 Afghan… Asia      2020-04-07  2020-04-12          38            0
#>  7 Afghan… Asia      2020-04-06  2020-04-12          29            2
#>  8 Afghan… Asia      2020-04-05  2020-04-12          35            1
#>  9 Afghan… Asia      2020-04-04  2020-04-12           0            0
#> 10 Afghan… Asia      2020-04-03  2020-04-12          43            0
#> # … with 8,225 more rows, and 18 more variables: deaths_cumul <dbl>,
#> #   date_first_10_cumul_deaths <date>, year_mortality <dbl>,
#> #   total_death_year <dbl>, total_death_day <dbl>,
#> #   total_death_year_world <dbl>, total_death_day_world <dbl>,
#> #   country_pop <dbl>, world_pop <dbl>,
#> #   days_since_first_10_cumul_deaths <drtn>,
#> #   extra_mortality_daily_country <dbl>, extra_mortality_cumul_country <dbl>,
#> #   country_weight <dbl>, extra_mortality_daily_world <dbl>,
#> #   extra_mortality_cumul_world <dbl>, extra_mortality <dbl>, date <date>,
#> #   days_since_date <drtn>
str(full_data)
#> tibble [8,235 × 24] (S3: tbl_df/tbl/data.frame)
#>  $ country                         : chr [1:8235] "Afghanistan" "Afghanistan" "Afghanistan" "Afghanistan" ...
#>  $ continent                       : Factor w/ 5 levels "Africa","Americas",..: 3 3 3 3 3 3 3 3 3 3 ...
#>  $ date_report                     : Date[1:8235], format: "2020-04-12" "2020-04-11" ...
#>  $ date_report_last                : Date[1:8235], format: "2020-04-12" "2020-04-12" ...
#>  $ cases                           : num [1:8235] 34 37 61 56 30 38 29 35 0 43 ...
#>  $ deaths_daily                    : num [1:8235] 3 0 1 3 4 0 2 1 0 0 ...
#>  $ deaths_cumul                    : num [1:8235] 18 15 15 14 11 7 7 5 4 4 ...
#>  $ date_first_10_cumul_deaths      : Date[1:8235], format: "2020-04-08" "2020-04-08" ...
#>  $ year_mortality                  : num [1:8235] 2018 2018 2018 2018 2018 ...
#>  $ total_death_year                : num [1:8235] 238758 238758 238758 238758 238758 ...
#>  $ total_death_day                 : num [1:8235] 654 654 654 654 654 ...
#>  $ total_death_year_world          : num [1:8235] 56650926 56650926 56650926 56650926 56650926 ...
#>  $ total_death_day_world           : num [1:8235] 155208 155208 155208 155208 155208 ...
#>  $ country_pop                     : num [1:8235] 37172386 37172386 37172386 37172386 37172386 ...
#>  $ world_pop                       : num [1:8235] 7.51e+09 7.51e+09 7.51e+09 7.51e+09 7.51e+09 ...
#>  $ days_since_first_10_cumul_deaths: 'difftime' num [1:8235] 4 3 2 1 ...
#>   ..- attr(*, "units")= chr "days"
#>  $ extra_mortality_daily_country   : num [1:8235] 0.459 0 0.153 0.459 0.611 ...
#>  $ extra_mortality_cumul_country   : num [1:8235] 0.55 0.573 0.764 1.07 1.682 ...
#>  $ country_weight                  : num [1:8235] 0.00495 0.00495 0.00495 0.00495 0.00495 ...
#>  $ extra_mortality_daily_world     : num [1:8235] 0.391 0 0.13 0.391 0.521 ...
#>  $ extra_mortality_cumul_world     : num [1:8235] 0.469 0.488 0.651 0.911 1.432 ...
#>  $ extra_mortality                 : num [1:8235] 0.611 0.611 0.611 0.611 0.611 ...
#>  $ date                            : Date[1:8235], format: "2020-04-08" "2020-04-08" ...
#>  $ days_since_date                 : 'difftime' num [1:8235] 4 4 4 4 ...
#>   ..- attr(*, "units")= chr "days"
```

### Recover the data behind the plot

``` r
plot_data <- plot_deaths(data_ECDC = data_COVID,
            data_WB = data_baseline_mortality,
            type_major = "daily",
            baseline_major = "country",
            select_major = "worst_day",
            type_minor = "daily",
            baseline_minor = "country",
            select_minor = "last_day",
            title = "Deaths by COVID19 on the worst and last day (dull & bright colour)\nrelative to baseline mortality")
```

``` r
class(plot_data)
#> [1] "tbl_df"     "tbl"        "data.frame"
```

### Modify the plot

Just add `return_plot = TRUE`, when calling `plot_deaths()` and store
the output in an object. The object created will be a plot.

``` r
plot_plot <- plot_deaths(data_ECDC = data_COVID,
            data_WB = data_baseline_mortality,
            type_major = "daily",
            baseline_major = "country",
            select_major = "worst_day",
            type_minor = "daily",
            baseline_minor = "country",
            select_minor = "last_day",
            title = "Deaths by COVID19 on the worst and last day (dull & bright colour)\nrelative to baseline mortality",
            return_plot = TRUE)
```

``` r
class(plot_plot)
#> [1] "gg"     "ggplot"
```

## Known caveats

There are many limitation that directly stem from the data. For example:

  - some countries (seem to under-report death by COVID19. This is
    because for many deaths occurying outside hospitals the exact cause
    of death is not known. (We will be able to look at that when overall
    death rates will be known.)

  - some countries are not included because either we have no data for
    COVID19, or the population and mortality data are not in the
    database I am using. The latter is for example the case of Taiwan.

  - the baseline mortality is based on **average** daily mortality from
    2018.

  - comorbidities are not accounted for.

## Developers corner

Here is my current R/computer configuration:

``` r
devtools::session_info()
#> ─ Session info ───────────────────────────────────────────────────────────────
#>  setting  value                       
#>  version  R version 3.6.2 (2019-12-12)
#>  os       macOS Catalina 10.15.3      
#>  system   x86_64, darwin15.6.0        
#>  ui       X11                         
#>  language (EN)                        
#>  collate  en_US.UTF-8                 
#>  ctype    en_US.UTF-8                 
#>  tz       Europe/Berlin               
#>  date     2020-04-12                  
#> 
#> ─ Packages ───────────────────────────────────────────────────────────────────
#>  package     * version     date       lib source                            
#>  assertthat    0.2.1       2019-03-21 [1] CRAN (R 3.6.0)                    
#>  backports     1.1.6       2020-04-05 [1] CRAN (R 3.6.2)                    
#>  callr         3.4.3       2020-03-28 [1] CRAN (R 3.6.2)                    
#>  cellranger    1.1.0       2016-07-27 [1] CRAN (R 3.6.0)                    
#>  cli           2.0.2       2020-02-28 [1] CRAN (R 3.6.0)                    
#>  colorspace    1.4-1       2019-03-18 [1] CRAN (R 3.6.0)                    
#>  coronaR     * 0.0.0.9000  2020-04-12 [1] local                             
#>  countrycode   1.1.1       2020-02-08 [1] CRAN (R 3.6.0)                    
#>  crayon        1.3.4       2017-09-16 [1] CRAN (R 3.6.0)                    
#>  curl          4.3         2019-12-02 [1] CRAN (R 3.6.0)                    
#>  desc          1.2.0       2018-05-01 [1] CRAN (R 3.6.0)                    
#>  devtools      2.2.2       2020-02-17 [1] CRAN (R 3.6.0)                    
#>  digest        0.6.25      2020-02-23 [1] CRAN (R 3.6.2)                    
#>  dplyr         0.8.99.9002 2020-04-06 [1] Github (tidyverse/dplyr@9a0209d)  
#>  ellipsis      0.3.0       2019-09-20 [1] CRAN (R 3.6.0)                    
#>  evaluate      0.14        2019-05-28 [1] CRAN (R 3.6.0)                    
#>  fansi         0.4.1       2020-01-08 [1] CRAN (R 3.6.0)                    
#>  farver        2.0.3       2020-01-16 [1] CRAN (R 3.6.0)                    
#>  forcats       0.5.0       2020-03-01 [1] CRAN (R 3.6.2)                    
#>  fs            1.4.1       2020-04-04 [1] CRAN (R 3.6.2)                    
#>  generics      0.0.2       2018-11-29 [1] CRAN (R 3.6.0)                    
#>  ggplot2       3.3.0.9000  2020-04-06 [1] Github (tidyverse/ggplot2@bca6105)
#>  glue          1.4.0       2020-04-03 [1] CRAN (R 3.6.2)                    
#>  gtable        0.3.0       2019-03-25 [1] CRAN (R 3.6.0)                    
#>  htmltools     0.4.0       2019-10-04 [1] CRAN (R 3.6.0)                    
#>  httr          1.4.1       2019-08-05 [1] CRAN (R 3.6.1)                    
#>  jsonlite      1.6.1       2020-02-02 [1] CRAN (R 3.6.0)                    
#>  knitr         1.28        2020-02-06 [1] CRAN (R 3.6.0)                    
#>  lifecycle     0.2.0.9000  2020-03-21 [1] Github (r-lib/lifecycle@355dcba)  
#>  lubridate     1.7.8       2020-04-06 [1] CRAN (R 3.6.2)                    
#>  magrittr      1.5         2014-11-22 [1] CRAN (R 3.6.0)                    
#>  memoise       1.1.0       2017-04-21 [1] CRAN (R 3.6.0)                    
#>  munsell       0.5.0       2018-06-12 [1] CRAN (R 3.6.0)                    
#>  pillar        1.4.3.9001  2020-03-21 [1] Github (r-lib/pillar@52b4503)     
#>  pkgbuild      1.0.6       2019-10-09 [1] CRAN (R 3.6.1)                    
#>  pkgconfig     2.0.3       2019-09-22 [1] CRAN (R 3.6.0)                    
#>  pkgload       1.0.2       2018-10-29 [1] CRAN (R 3.6.0)                    
#>  prettyunits   1.1.1       2020-01-24 [1] CRAN (R 3.6.0)                    
#>  processx      3.4.2       2020-02-09 [1] CRAN (R 3.6.0)                    
#>  ps            1.3.2       2020-02-13 [1] CRAN (R 3.6.0)                    
#>  purrr         0.3.3       2019-10-18 [1] CRAN (R 3.6.0)                    
#>  R6            2.4.1       2019-11-12 [1] CRAN (R 3.6.0)                    
#>  Rcpp          1.0.4       2020-03-17 [1] CRAN (R 3.6.0)                    
#>  readxl        1.3.1       2019-03-13 [1] CRAN (R 3.6.0)                    
#>  remotes       2.1.1       2020-02-15 [1] CRAN (R 3.6.2)                    
#>  rlang         0.4.5.9000  2020-03-21 [1] Github (r-lib/rlang@a90b04b)      
#>  rmarkdown     2.1         2020-01-20 [1] CRAN (R 3.6.0)                    
#>  rprojroot     1.3-2       2018-01-03 [1] CRAN (R 3.6.0)                    
#>  scales        1.1.0       2019-11-18 [1] CRAN (R 3.6.0)                    
#>  sessioninfo   1.1.1       2018-11-05 [1] CRAN (R 3.6.0)                    
#>  stringi       1.4.6       2020-02-17 [1] CRAN (R 3.6.0)                    
#>  stringr       1.4.0       2019-02-10 [1] CRAN (R 3.6.0)                    
#>  testthat      2.3.2       2020-03-02 [1] CRAN (R 3.6.2)                    
#>  tibble        3.0.0.9000  2020-04-02 [1] Github (tidyverse/tibble@4f0fd61) 
#>  tidyr         1.0.2       2020-01-24 [1] CRAN (R 3.6.0)                    
#>  tidyselect    1.0.0       2020-01-27 [1] CRAN (R 3.6.0)                    
#>  usethis       1.5.1.9000  2020-04-06 [1] Github (r-lib/usethis@1eb8efc)    
#>  utf8          1.1.4       2018-05-24 [1] CRAN (R 3.6.0)                    
#>  vctrs         0.2.99.9010 2020-04-06 [1] Github (r-lib/vctrs@5c69793)      
#>  wbstats       0.2         2018-01-03 [1] CRAN (R 3.6.0)                    
#>  withr         2.1.2       2018-03-15 [1] CRAN (R 3.6.0)                    
#>  xfun          0.12        2020-01-13 [1] CRAN (R 3.6.0)                    
#>  yaml          2.2.1       2020-02-01 [1] CRAN (R 3.6.1)                    
#> 
#> [1] /Library/Frameworks/R.framework/Versions/3.6/Resources/library
```

## Help & feedbacks wanted\!

If you find that this project interesting an idea worth pursuing, please
let me know by liking, RT or messaging on Twitter (@alexcourtiol).

Developing is always more fun when it becomes a collaborative work, so
please also email me (or leave an issue) if you want to get involved\!
