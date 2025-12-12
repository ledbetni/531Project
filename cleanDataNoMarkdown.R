
library(tidyverse)
library(arrow)

library(tidyverse)
library(arrow)
bids_raw <- read_parquet("./data/bids_data_vDTR.parquet")
bids <- read_parquet("./data/bids_data_vDTR.parquet")
glimpse(bids_raw)

library(dplyr)
class(bids$PRICE)
summary(bids$PRICE)
set.seed(123)
sample(bids$PRICE, size=20)
head(bids$PRICE)


library(readr)
library(dplyr)
bids <- bids %>% mutate(PRICE_clean = parse_number(PRICE))
summary(bids$PRICE_clean)
class(bids$PRICE_clean)

sum(is.na(bids$PRICE_clean))


summary(bids$PRICE_clean)
quantile(bids$PRICE_clean, probs = seq(0,1,0.01), na.rm=TRUE)
bids%>%filter(!is.na(PRICE_clean), PRICE_clean < 0) %>% head(20)
p99 <- quantile(bids$PRICE_clean, 0.99, na.rm=TRUE)
bids%>%filter(!is.na(PRICE_clean), PRICE_clean > p99) %>% head(20)

library(dplyr)
p99 <- quantile(bids$PRICE_clean, 0.99, na.rm=TRUE)
bids <- bids %>% mutate(PRICE_final = case_when(PRICE_clean %in% c(-999, -99) ~ NA_real_, PRICE_clean < 0 ~NA_real_, PRICE_clean > p99 ~ p99, TRUE ~ PRICE_clean))

summary(bids$PRICE_final)


library(dplyr)
library(stringr)
bids%>%count(DEVICE_GEO_REGION, sort=TRUE)


library(dplyr)
library(stringr)
bids%>%count(DEVICE_GEO_REGION, sort=TRUE)



bids<-bids%>% mutate(DEVICE_GEO_REGION_clean = case_when(str_detect(DEVICE_GEO_REGION, "OR") ~ "OR", str_detect(DEVICE_GEO_REGION, "Or") ~ "OR", str_detect(DEVICE_GEO_REGION, "oregon") ~ "OR", str_detect(DEVICE_GEO_REGION, "xor") ~ "OR", TRUE ~ NA_character_))

bids %>% count(DEVICE_GEO_REGION_clean, sort=TRUE)


bids<-bids%>% mutate(DEVICE_GEO_ZIP_char = as.character(DEVICE_GEO_ZIP))

bids%>%count(DEVICE_GEO_ZIP_char, sort=TRUE) %>% head(30)


bids%>% mutate(ZIP_trim = str_trim(DEVICE_GEO_ZIP_char), ZIP_len=str_length(ZIP_trim), ZIP_digits=str_detect(ZIP_trim, "^[0-9]+$"))%>%summarise(min_len=min(ZIP_len, na.rm=TRUE), max_len=max(ZIP_len,na.rm=TRUE), non_digit_count=sum(!ZIP_digits,na.rm=TRUE))

bids%>%filter(DEVICE_GEO_ZIP_char %in% c("-999", "9999", "00000", "99999"))%>% count(DEVICE_GEO_ZIP_char)


bids<- bids%>%mutate(ZIP_trim=DEVICE_GEO_ZIP_char %>% as.character() %>% str_trim(), DEVICE_GEO_ZIP_clean = case_when(str_detect(ZIP_trim, "^97[0-9]{3}$") ~ ZIP_trim, TRUE ~ NA_character_))

bids%>% count(DEVICE_GEO_ZIP_clean, sort=TRUE) %>% head(20)


bids<- bids%>%mutate(ZIP_trim=DEVICE_GEO_ZIP_char %>% as.character() %>% str_trim(), DEVICE_GEO_ZIP_clean = case_when(str_detect(ZIP_trim, "^97[0-9]{3}$") ~ ZIP_trim, TRUE ~ NA_character_))

bids%>% count(DEVICE_GEO_ZIP_clean, sort=TRUE) %>% head(20)


set.seed(123)
sample(bids$RESPONSE_TIME, size=20)


bids <- bids%>% mutate(RESPONSE_TIME_char = as.character(RESPONSE_TIME), RESPONSE_TIME_trim = str_trim(RESPONSE_TIME_char), RESPONSE_TIME_strip = str_replace(RESPONSE_TIME_trim, "^[^0-9.-]*", ""), 
                       RESPONSE_TIME_str=str_replace(RESPONSE_TIME_strip, "[^0-9.-]+$", ""), RESPONSE_TIME_clean = as.numeric(RESPONSE_TIME_str))

summary(bids$RESPONSE_TIME_clean)


na_response <- sum(is.na(bids$RESPONSE_TIME_clean))
na_response



library(dplyr)
library(stringr)
library(lubridate)

set.seed(123)
sample(bids$TIMESTAMP,size=20)


bids<-bids%>%mutate(TIMESTAMP_char = as.character(TIMESTAMP))

bids%>%summarise(num_dash=sum(str_detect(TIMESTAMP_char, "-"), na.rm=TRUE), num_slash=sum(str_detect(TIMESTAMP_char, "/"), na.rm=TRUE))


bids<-bids%>% mutate(TIMESTAMP_clean = parse_date_time(TIMESTAMP_char, orders = c("ymd HMS", "ymd HM", "mdy HMS", "mdy HM"), tz="UTC"))


sum(is.na(bids$TIMESTAMP_clean))



summary(bids$TIMESTAMP_clean)
range(bids$TIMESTAMP_clean, na.rm = TRUE)


bids %>% count(AUCTION_ID) %>% filter(n>1)


bids_dup <- bids %>% count(across(everything()), name="n") %>% filter(n>1)
nrow(bids_dup)
sum(bids_dup$n - 1)
bids_dup %>% head()


bids_nodup<- bids %>% distinct()
nrow(bids)
nrow(bids_nodup)
bids_nodup %>% count(across(everything()), name="n") %>% filter(n>1)



bids %>% summarise(min_lat = min(DEVICE_GEO_LAT, na.rm=TRUE), max_lat = max(DEVICE_GEO_LAT, na.rm=TRUE), min_long = min(DEVICE_GEO_LONG, na.rm=TRUE), max_long = max(DEVICE_GEO_LONG, na.rm=TRUE))

## Lat looks roughly valid, long valid ranges from (-124 to -116)


lat_min <- 42
lat_max <- 47
long_min <- -125
long_max <- -116


bids %>% filter(DEVICE_GEO_LONG < long_min) %>% select(DEVICE_GEO_LAT,DEVICE_GEO_LONG) %>%arrange(DEVICE_GEO_LONG)


lat_min <- 42
lat_max <- 47
long_min <- -125
long_max <- -116

bids<- bids%>% mutate( DEVICE_GEO_LAT_clean = if_else(!is.na(DEVICE_GEO_LAT) & DEVICE_GEO_LAT >= lat_min & DEVICE_GEO_LAT <= lat_max, DEVICE_GEO_LAT,NA_real_), DEVICE_GEO_LONG_clean = if_else(!is.na(DEVICE_GEO_LONG) & DEVICE_GEO_LONG >= long_min & DEVICE_GEO_LONG <= long_max, DEVICE_GEO_LONG, NA_real_))

bids %>% summarise(min_lat_clean = min(DEVICE_GEO_LAT_clean, na.rm=TRUE), max_lat_clean = max(DEVICE_GEO_LAT_clean, na.rm=TRUE), min_long_clean = min(DEVICE_GEO_LONG_clean, na.rm=TRUE), max_long_clean = max(DEVICE_GEO_LONG_clean, na.rm=TRUE))


bids_clean<- bids %>% select(AUCTION_ID, TIMESTAMP_clean, DATE_UTC, PUBLISHER_ID, DEVICE_TYPE, DEVICE_GEO_CITY, DEVICE_GEO_REGION_clean, DEVICE_GEO_ZIP_clean, DEVICE_GEO_LAT_clean, DEVICE_GEO_LONG_clean, PRICE_final, REQUESTED_SIZES, SIZE, RESPONSE_TIME_clean,BID_WON)

glimpse(bids_clean)

bids %>%count(across(everything()), name = "n") %>%filter(n > 1)

bids_final <- bids_clean%>% distinct()
glimpse(bids_final)




glimpse(bids_final)
head(bids_final)


##### Price, response, zip codes, auction_id

hist(bids_final$PRICE_final, breaks = 30, main = "Distribution of Price")

library(ggplot2)
library(dplyr)
library(sf)
library(tigris)
options(tigris_use_cache = TRUE)

# Price
ggplot(bids_final, aes(x = PRICE_final)) +
  geom_histogram(binwidth = .1, fill = "steelblue", alpha = 0.7) +
  theme_minimal() + labs(title = "Distribution of Bid Prices", x = "Price", y = "Count") + theme(plot.title = element_text(size=16, face="bold", hjust=0.5))

Interpretation: 
- strongly right-skewed
- data was cut off at 99th percentile because we have extreme outliers (histogram that includes outliers is terribly uninformative)
- shape suggests high variance in willingness to pay across bidders/auctions 
- most bids at low prices, small fraction of bidders willing to pay more
- Highest bidder wins vast majority of the time, meaning auction mechanism is behaving correctly most of the time
- The small percentage of situations where the highest bid doesn’t win are likely due to non-price constraints.

bids_per_auction <- bids %>%
  count(AUCTION_ID, name = "num_bids")

head(bids_per_auction)

#Bids per auction
ggplot(bids_per_auction, aes(x = num_bids)) +
  geom_histogram(binwidth = 1, fill = "steelblue", alpha = 0.7) +
  theme_minimal() + labs(title = "Distribution of Bids per Auction", x = "Number of Bids", y = "Count of Auctions") + theme(plot.title = element_text(size=16, face="bold", hjust=0.5))

Interpretation:
- Heavily right skewed
- Largest spike at 1-2 bids per auction, steep drop-off after 3-4 bids per auction
- Small number of auctions receive high number of bids
    - High demand ad slots
    - These auctions likely produce high CPMs


#Repsonse time
ggplot(bids_final, aes(x = RESPONSE_TIME_clean)) +
  geom_histogram(binwidth = 30, fill = "steelblue", alpha = 0.7) +
  theme_minimal() + labs(title = "Distribution of Response Times", x = "Reponse Time in MS", y = "Count") + theme(plot.title = element_text(size=16, face="bold", hjust=0.5))

Interpretation:
- Heavily right-skewed
- Most common response time is between 100 and 150 milliseconds
- We do see moderate tail from 250-600 milliseconds
- This suggests that bidders within this response range have non-optimal infrastructure
- Bulk of data is at relatively low response time, we can assume that faster response times help win likelihood



#Price per zip
ggplot(bids_final, aes(x = PRICE_final)) + geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7) +
  facet_wrap(~ DEVICE_GEO_ZIP_clean, scales = "free_y") +
  labs(
    title = "Bid Price Distribution Across ZIP Codes",
    x = "Bid Price",
    y = "Count"
  ) +
  theme_minimal()



zip_avg <- bids_final %>%
  group_by(DEVICE_GEO_ZIP_clean) %>%
  summarise(avg_price = mean(PRICE_final, na.rm = TRUE))

zip_shapes <- zctas(year = 2020) %>% st_as_sf()
names(zip_shapes)
portland_bbox <- sf::st_bbox(c(
  xmin = -123.2,  # west
  xmax = -122.2,  # east
  ymin = 45.2,    # south
  ymax = 45.8     # north
), crs = sf::st_crs(zip_shapes))

portland_area <- sf::st_crop(zip_shapes, portland_bbox)

zip_avg <- bids %>%
  group_by(DEVICE_GEO_ZIP_clean) %>%
  summarise(avg_price = mean(PRICE_final, na.rm = TRUE))

portland_map <- portland_area %>%
  left_join(zip_avg, by = c("ZCTA5CE20" = "DEVICE_GEO_ZIP_clean"))

ggplot(portland_map) +
  geom_sf(aes(fill = avg_price), color = NA) +
  scale_fill_viridis_c(option = "magma", na.value = "grey90") +
  labs(
    title = "Average Bid Prices — Portland Metro ZIP Codes",
    fill = "Avg Price"
  ) +
  theme_minimal()

Interpretation:
- High variance in CPM across ZIP Codes
- Areas with “Premium ZIPs” - high median CPM, relatively high competition
- Reasons: Affluent demographics, urban areas, areas w/ strong advertiser demand
- Areas with “Low-Value ZIPs” - rural areas, areas w/ low-density traffic


#### Does highest bid win?

max_bids <- bids_final %>%
  group_by(AUCTION_ID) %>%
  summarise(max_price = max(PRICE_final, na.rm = TRUE))

bids2 <- bids_final %>%
  left_join(max_bids, by = "AUCTION_ID")

bids2 <- bids2 %>%
  mutate(winner_is_max = as.logical(BID_WON) & PRICE_final == max_price)

auction_win_check <- bids2 %>%
  group_by(AUCTION_ID) %>%
  summarise(
    highest_bid_won = any(winner_is_max)
  )

mean(auction_win_check$highest_bid_won)

auction_win_check %>%
  filter(!highest_bid_won)


auction_win_check %>%
  count(highest_bid_won) %>%
  ggplot(aes(x = "", y = n, fill = highest_bid_won)) +
  geom_col(width = 1) +
  coord_polar("y") +
  labs(title = "Highest Bid Winning Rate") +
  theme_void() +
  scale_fill_manual(values = c("red", "green"))
