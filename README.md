# serpentair
Repo to keep track of code used to analyze, transform, and work with IAQ, energy, and climate data. This repo is also a potluck of different Python frameworks I'm trying to get more experience with.

## Setup

1. Create a Virtual environment called `env`
2. Run: `pip install -r requirements.txt` to install the necessary python packages
3. You should now be set up.

## Key Concepts & Architecture

### Analytics - Django App

Collection of views and APIs used to visualize transformed and organized data. Largely a dashboard, and in-depth analysis of circuit data, also has some enhanced views to slice and dice different loads.

- Dream: One dashboard with:
    - EPA AirNow data, score, and color coding
    - Forecast - today's high, low, hourly temps, chance of rain by hour, time of sunset
    - Outdoor temperature & relative humidity
    - Indoor temperature & relative humidity
    - Current HVAC Status (e.g., set to cool, 75 F, interior humidity is 63%)
    - Current electricity consumption
    - Top 5 consuming circuits in the house & consumption (kWh & % of total)

- Bonus: What If analysis, what kind of solar production and set up would affect electricity usage the most? e.g., zero export, TOU arbitrage, baseload absorbtion, etc...

### Extract and Load - Prefect

Flows to get the data, and stage it for further transformation.

- Bonus: Could also monitor transformed data and alert

- Bonus: Trigger an automation? e.g., high basement humidity, turn on basement de-humidifier.

### Live Reads: Fast API

- Retrieve and cache realtime data to power a household monitoring dashboard (e.g., forecast data, air quality data)

### Transform - dbt & DuckDB

- All live retrieval data can be warehoused and integrated into historical look backs
- analytical data from air quality monitors (Airthings) and energy monitor (Emporia) may also net interesting trends for historical analysis.