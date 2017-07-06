# Get BBS population time-series data for analysis

library(rdataretriever)
library(dplyr)
library(DBI)
library(tidyr)
library(feather)

# TODO:
# 3. Initial filter of species (unknown water,etc)

get_data <- function(){
  if (!("bbs.sqlite" %in% list.files("data"))){
    rdataretriever::install('breed-bird-survey', 'sqlite', db_file = './data/bbs.sqlite')
  }
  con = dbConnect(RSQLite::SQLite(), "./data/bbs.sqlite")
  query <- "SELECT
                  (counts.statenum*1000) + counts.Route AS site_id,
                  Latitude AS lat,
                  Longitude AS long,
                  Aou AS species_id,
                  counts.Year AS year,
                  speciestotal AS abundance
                FROM
                  breed_bird_survey_counts AS counts
                  JOIN breed_bird_survey_weather
                    ON counts.statenum=breed_bird_survey_weather.statenum
                    AND counts.route=breed_bird_survey_weather.route
                    AND counts.rpid=breed_bird_survey_weather.rpid
                    AND counts.year=breed_bird_survey_weather.year
                  JOIN breed_bird_survey_routes
                    ON counts.statenum=breed_bird_survey_routes.statenum
                    AND counts.route=breed_bird_survey_routes.route
                WHERE breed_bird_survey_weather.runtype=1 AND breed_bird_survey_weather.rpid=101"
  collect(tbl(con, dplyr::sql(query)), n = Inf)
}

#' Get BBS population time-series data
#'
#' Modified from https://github.com/weecology/bbs-forecasting
#'
#' Selects sites with data spanning 1982 through 2013 containing at least 25
#' samples during that period.
#'
#'
#' @param start_yr num first year of time-series
#' @param end_yr num last year of time-series
#' @param min_num_yrs num minimum number of years of data between start_yr & end_yr
#'
#' @return dataframe with site_id, lat, long, year, species_id, and abundance
get_pop_ts_data <- function(start_yr, end_yr, min_num_yrs){
  pop_ts__data = get_data() %>%
    filter_ts(start_yr, end_yr, min_num_yrs) %>%
    tidyr::complete(site_id, year) %>%
    ungroup()
}

#' Filter BBS to specified time series period and number of samples
#'
#' Modified from https://github.com/weecology/bbs-forecasting
#'
#' @param bbs_data dataframe that contains BBS site_id and year columns
#' @param start_yr num first year of time-series
#' @param end_yr num last year of time-series
#' @param min_num_yrs num minimum number of years of data between start_yr & end_yr
#'
#' @return dataframe with original data and associated environmental data
filter_ts <- function(bbs_data, start_yr, end_yr, min_num_yrs){
  sites_to_keep = bbs_data %>%
    dplyr::filter(year >= start_yr, year <= end_yr) %>%
    dplyr::group_by(site_id) %>%
    dplyr::summarise(num_years=length(unique(year))) %>%
    dplyr::ungroup() %>%
    dplyr::filter(num_years >= min_num_yrs)

  filterd_data <- bbs_data %>%
    dplyr::filter(year >= start_yr, year <= end_yr) %>%
    dplyr::filter(site_id %in% sites_to_keep$site_id)
}

pop_ts_data = get_pop_ts_data(1982, 2016, 35)
write_feather(pop_ts_data, './data/bbs_pop_data.feather')
