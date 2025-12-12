# Prebid Auction Data Dictionary

**Context:**  
These fields represent auction-level and bid-level data from a Prebid Server integration. Each record corresponds to one bid line within an auction. Queries often filter to `DEVICE_GEO_COUNTRY = 'US'`, where `DEVICE_GEO_REGION` corresponds to U.S. state codes.

---

## Table Overview

| Column | Type (Snowflake) | Example | Description | Notes / Constraints |
|---|---|---|---|---|
| `TIMESTAMP` | `TIMESTAMP_NTZ` | `2025-10-12 14:03:27` | Event time the log row was recorded. | Treated as UTC unless explicitly converted. Multiple rows per `AUCTION_ID` possible. |
| `DATE_UTC` | `DATE` | `2025-10-12` | Calendar date (UTC) for partitioning or grouping. | Typically derived from `TIMESTAMP`. Useful for partitioning in Snowflake. |
| `AUCTION_ID` | `VARCHAR` | `a7f2…` | Unique identifier for a single auction. | One auction → many rows (bidders, sizes, seats). |
| `PUBLISHER_ID` | `VARCHAR` | `pub_12345` | Publisher/site/app identifier. | Medium/high cardinality. Useful for rollups and filtering. |
| `DEVICE_TYPE` | `VARCHAR` | `mobile` | Device category. | Common values: `desktop`, `mobile`, `tablet`. |
| `DEVICE_GEO_COUNTRY` | `VARCHAR(2)` | `US` | ISO 2-letter country code. | Filtered to `'US'` in this dataset. |
| `DEVICE_GEO_REGION` | `VARCHAR(2)` | `CA` | U.S. state/region (postal code). | Two-letter USPS code (e.g., CA, NY, TX). |
| `DEVICE_GEO_CITY` | `VARCHAR` | `San Diego` | City derived from device IP. | Free text; may vary in casing/spelling. |
| `DEVICE_GEO_ZIP` | `VARCHAR(10)` | `92101` | ZIP/postal code. | Can include ZIP+4 (e.g., `92101-1234`). |
| `DEVICE_GEO_LAT` | `FLOAT` | `32.7157` | Latitude of device. | Nullable; precision depends on provider. |
| `DEVICE_GEO_LONG` | `FLOAT` | `-117.1611` | Longitude of device. | Required in your filtered query. |
| `REQUESTED_SIZES` | `VARCHAR` (or `ARRAY`) | `300x250, 320x50` | All sizes requested in the impression. | Use consistent delimiter if stored as string. |
| `SIZE` | `VARCHAR` | `300x250` | Size for this bid line. | Often a single size chosen from `REQUESTED_SIZES`. |
| `PRICE` | `NUMBER(12,6)` | `0.75` | **CPM bid** (USD) for this record. | Represents the bid amount; rename to `CPM_BID` downstream if clearer. |
| `RESPONSE_TIME` | `NUMBER(10,0)` | `128` | Bidder response latency (ms). | Validate non-negative; used for SLOs. |
| `BID_WON` | `BOOLEAN` | `TRUE` | Whether this bid won the auction. | At least one `TRUE` per `AUCTION_ID` guaranteed by your filter logic. |

---

## Table Grain and Keys

- **Grain:** One record per `(AUCTION_ID, bidder/seat, size, …)`  
- **Primary keys / joins:** `AUCTION_ID`, `PUBLISHER_ID`, `DATE_UTC`  
- **Partitioning:** Typically by `DATE_UTC`  
- **Common filters:**  
  - `DEVICE_GEO_COUNTRY = 'US'`  
  - `PRICE IS NOT NULL`  
  - `DEVICE_GEO_LONG IS NOT NULL`

---

## Recommended Conventions

- **Currency:** All prices are USD CPM values. If multi-currency support is added, include a `CURRENCY` field.  
- **Sizes:** Store as `"WIDTHxHEIGHT"` strings (e.g., `300x250`).  
- **Geo:** Ensure `DEVICE_GEO_REGION` uses USPS 2-letter state codes when `DEVICE_GEO_COUNTRY = 'US'`.  
- **Time:** Use UTC (`TIMESTAMP_NTZ`) and derive `DATE_UTC` for partitioning.

---

## Data Quality Checks

| Check | Rule | Purpose |
|---|---|---|
| Price bounds | `PRICE >= 0 AND PRICE < 500` | Remove outliers / sanity check. |
| Geo bounds | `ABS(DEVICE_GEO_LAT) <= 90` and `ABS(DEVICE_GEO_LONG) <= 180` | Validate coordinate integrity. |
| Region validity | `DEVICE_GEO_REGION` ∈ USPS state list | Ensure clean U.S. geo coverage. |
| Winner logic | `SUM(CASE WHEN BID_WON THEN 1 ELSE 0 END) >= 1` per `AUCTION_ID` | Ensure every auction has a winner. |

---

## Example Usage

```sql
-- Select all rows for 500 random auctions that have at least one winning bid
WITH params AS (
  SELECT 500 AS n
),
filtered AS (
  SELECT *
  FROM PREBID.STAGE.PREBID_DATA_COMBINED
  WHERE DEVICE_GEO_COUNTRY = 'US'
    AND PRICE IS NOT NULL
    AND DEVICE_GEO_LONG IS NOT NULL
),
valid_auctions AS (
  SELECT AUCTION_ID
  FROM filtered
  GROUP BY AUCTION_ID
  HAVING SUM(CASE WHEN BID_WON THEN 1 ELSE 0 END) > 0
),
ranked_ids AS (
  SELECT AUCTION_ID,
         ROW_NUMBER() OVER (ORDER BY RANDOM()) AS rn
  FROM valid_auctions
),
pick_ids AS (
  SELECT AUCTION_ID FROM ranked_ids CROSS JOIN params WHERE rn <= n
)
SELECT f.*
FROM filtered f
JOIN pick_ids p USING (AUCTION_ID)
ORDER BY f.AUCTION_ID;
