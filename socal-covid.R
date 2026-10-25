library(tidyverse)
cases <- read_csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/refs/heads/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_confirmed_US.csv")
deaths <- read_csv("https://raw.githubusercontent.com/CSSEGISandData/COVID-19/refs/heads/master/csse_covid_19_data/csse_covid_19_time_series/time_series_covid19_deaths_US.csv")

# Removing unnecessary columns, selecing rows of interest, and pivoting data
deaths <- deaths %>%
  select(-UID, -iso2, -iso3, -code3, -FIPS, -Country_Region, -Lat, -Long_, -Combined_Key) %>%
  filter(deaths$Province_State == "California" & (deaths$Admin2 == "San Bernardino" |  
                                                    deaths$Admin2 == "Riverside" | deaths$Admin2 == "San Diego" |  
                                                    deaths$Admin2 == "Los Angeles" | deaths$Admin2 == "Orange")) %>%
  pivot_longer(cols = -c(Admin2, Province_State, Population), 
               names_to = "date", 
               values_to = "deaths")

cases <- cases %>%
  select(-UID, -iso2, -iso3, -code3, -FIPS, -Country_Region, -Lat, -Long_, -Combined_Key) %>%
  filter(cases$Province_State == "California" & (cases$Admin2 == "San Bernardino" |  
                                                   cases$Admin2 == "Riverside" | cases$Admin2 == "San Diego" |  
                                                   cases$Admin2 == "Los Angeles" | cases$Admin2 == "Orange")) %>%
  pivot_longer(cols = -c(Admin2, Province_State), 
               names_to = "date", 
               values_to = "cases")


# Joining cases and death data
cases_and_deaths <- full_join(deaths, cases) %>%
  mutate(deaths_per_thousand = deaths/(Population/1000),
         cases_per_thousand = cases/(Population/1000),
         date = mdy(date))


# COVID cases graph
cases_and_deaths %>%
  filter(cases > 0) %>%
  ggplot(aes(x=date, y=cases_per_thousand, color=Admin2)) +
  geom_line() +
  theme_bw() +
  labs(title="Covid Cases in Southern California", 
       x="Date", 
       y="Cumulative Cases (Per Thousand)", color="County") +
  scale_color_discrete(breaks=c("Los Angeles", "San Bernardino", "San Diego", "Riverside", "Orange"))


# COVID deaths graph
cases_and_deaths %>%
  filter(deaths > 0) %>%
  ggplot(aes(x=date, y=deaths_per_thousand, color=Admin2)) +
  geom_line() +
  theme_bw() +
  labs(title="Covid Deaths in Southern California", 
       x="Date", 
       y="Cumulative Deaths (Per Thousand)", color="County") +
  scale_color_discrete(breaks=c("San Bernardino", "Los Angeles", "Riverside", "Orange", "San Diego"))

# Linear model predicts deaths per thousand, uses cases per thousand information from all counties. 
socal_model <- lm(deaths_per_thousand ~ cases_per_thousand, data=cases_and_deaths)

# Adds predictions to cases and deaths tibble
cases_and_deaths <- cases_and_deaths %>%
  mutate(pred = predict(socal_model))


# Graph of San Diego/Orange outcomes against linear model
cases_and_deaths %>%
  filter(cases_and_deaths$Admin2 == "Orange" | cases_and_deaths$Admin2 == "San Diego") %>%
  ggplot(aes(x=cases_per_thousand, y=deaths_per_thousand, color=Admin2)) +
  geom_line() +
  geom_line(aes(x=cases_per_thousand, y=pred), color="lightblue3") +
  theme_bw() +
  labs(title="Predicted vs. Actual Covid Deaths",
       x="Cases Per Thousand",
       y="Deaths Per Thousand",
       color="County")