# Data Folder

This folder contains the datasets used in the research study on hate crime, mental health, and LGBTQ politicians. The data is divided into raw, unprocessed data and cleaned, processed datasets.

Not all datasets will be stored in the Github, given the data limit. The origin location will be indicated if the dataset can not be uploaded or restored

## Folder Structure
```
data
├── raw/                        # Original, unprocessed datasets
│   ├── HCSP/                       # Hate crime HCSP data from FBI
│   │   ├── Raw Tables/                 # Raw Tables from HCSP system
│   │   └── Processed Data/             # Processed Data, mostly stored in Dta form
│   ├── ACA/                        # ACA Medicaid Enrollment data
│   ├── LGBTQ/                      # LGBTQ politician data from Wikipedia
│   └── Other/                      # Other covariates data from different sources 
├── processed/                  # Cleaned and modified datasets for analysis
└── README.md                   # Documentation for data sources and preprocessing
```

## `raw/`
The `raw` folder contains the original datasets collected from various sources. These datasets are not modified and are stored here for reference.
### BRFSS
The Behavioral Risk Factor Surveillance System (BRFSS) data is available [here](https://www.cdc.gov/brfss/behavioral-risk-factor-surveillance-system.html). Due to the size of the data, it can not be stored in Github. But this list contains all the year location and the code book

| BRFSS-Year                | Codebook |
| :--------------------     | ------- |
| [2011 Annual Survey Data](https://www.cdc.gov/brfss/annual_data/annual_2011.htm)   | [Link](https://www.cdc.gov/brfss/annual_data/2011/pdf/CODEBOOK11_LLCP.pdf)    |
|                                                                                      |            |

### [`HCSP/`](./raw/HCSP/) - Hate Crime
The hate crime data is from FBI Hate Crime Statistics Program (HCSP). Through the HCSP, the FBI Uniform Crime Reporting (UCR) Program collects hate crime data on crimes that were motivated by an offender’s bias against a race, religion, disability, sexual orientation, ethnicity, gender, or gender identity. The categories of bias have changed over time, and now include 6 categories of bias motivation and 34 specific types of bias. Determining if an offender was motivated by bias can be difficult, and the FBI instructs reporting agencies to report bias “only if investigation reveals sufficient objective facts to lead a reasonable and prudent person to conclude that the offender’s actions were motivated, in whole or in part, by bias."

As of January 1, 2021, the FBI National Incident-Based Reporting System (NIBRS) is the national standard by which law enforcement agencies submit crime data to the FBI. NIBRS agencies indicate whether an offense was motivated by an offender’s bias against the victim for each reported offense. For more information, refer to the FBI’s Hate Crime Statistics program page.

Note: Florida changed its reporting system in 2021, therefore the raw dataset contains no quarterly data for Florida in 2021; we supplement the data with [Florida Hate Crime Report](https://www.myfloridalegal.com/files/pdf/page/BE0185D36969417B852589270066D783/Web+Link.pdf).

Data are captured from [FBI Crime Data Explorer](https://cde.ucr.cjis.gov/LATEST/webapp/#).

#### [`HCSP/Raw Table`](./raw/HCSP/Raw%20Tables/)
This folder contains the compressed tables and reported directly downloaded from the FBI's UCR system. It needs to be processed before can be used.
* [`clean.do`](./raw/HCSP/Raw%20Tables/clean.do) - dofile to clean the HCSP table 13 (quarterly data) into dta file.

#### [`HCSP/Processed Data`](./raw/HCSP/Processed%20Data/)
This folder contains the processed data, including the following datasets:
* `hate crime by motivation and state and year 2004_2023.dta` - hate crime statistics by state and year and motivation;
* `hate crime by state quarter 2007_2023.dta` - hate crime statistics by quarter, state and year;
* `law enforcement officers feloniously killed.dta` - law enforcement, [FBI Crime Data Explorer](https://cde.ucr.cjis.gov/LATEST/webapp/#)
* `Q2008.dta` to `Q2019.dta` - quarterly data
* `state level agencies.dta` - state level FBI agenecies

#### [`LGBTQ/`](./raw/LGBTQ/)
This folder contains the processed LGBTQ data from [Wikipedia](https://en.wikipedia.org/wiki/List_of_LGBTQ_politicians_in_the_United_States)
The code for processing the data can be found [here](https://colab.research.google.com/drive/1qZ1TxAPBjV5Up4pnDoAaWu0UT1wPgbPc?usp=drive_link)
The most up-to-date data is from 2000 to 2023.

#### [`ACA/`](./raw/ACA/)
[**Medicaid Enrollment - New Adult Group**](https://data.medicaid.gov/dataset/6c114b2c-cb83-559b-832f-4d8b06d6c1b9/data?conditions[0][property]=enrollment_year&conditions[0][value]=2024&conditions[0][operator]=starts%20with)
The enrollment information is a state-reported count of unduplicated individuals enrolled in the state’s Medicaid program at any time during each month in the quarterly reporting period. The enrollment data identifies the total number of Medicaid enrollees and, for states that have expanded Medicaid, provides specific counts for the number of individuals enrolled in the new adult eligibility group, also referred to as the “VIII Group”. The VIII Group is only applicable for states that have expanded their Medicaid programs by adopting the VIII Group. This data includes state-by-state data for this population as well as a count of individuals whom the state has determined are newly eligible for Medicaid. All 50 states, the District of Columbia and the US territories are represented in these data.

[**Status of State Medicaid Expansion Decisions**](https://www.kff.org/affordable-care-act/issue-brief/status-of-state-medicaid-expansion-decisions-interactive-map/) from KFF
The Affordable Care Act’s (ACA) Medicaid expansion expanded Medicaid coverage to nearly all adults with incomes up to 138% of the Federal Poverty Level ($20,783 for an individual in 2024) and provided states with an enhanced federal matching rate (FMAP) for their expansion populations.
To date, 41 states (including DC) have adopted the Medicaid expansion and 10 states have not adopted the expansion. Current status for each state is based on KFF tracking and analysis of state expansion activity.

Notes:
1. “VIII GROUP” is also known as the “New Adult Group.”
2. The VIII Group is only applicable for states that have expanded their Medicaid programs by adopting the VIII Group. VIII Group enrollment information for the states that have not expanded their Medicaid program is noted as “N/A.”

**Data**
* `data2014` - `data2023`: monthly medicaid enrollment statistics from Medicaid.gov
* `Other/ACAexpansion.csv` : information about state's decision on adopting ACA expansion, from KFF
* `ACA.dta` & `ACAcode.do`: processing the Medicaid enrollment and ACAexpansion decision 

#### [`Other/`](./raw/Other/)
This folder contains the other covariates, with the list as follows:
**Data**
1. [Unemployment rate](./raw/Other/unemployment%20rate%20by%20state%20year%201980_2023.dta),1980-2023: [BLS](https://www.bls.gov/lau/tables.htm#stateaa) 
2. [Sex ratio](./raw/Other/sexratio20072023.dta), 2007-2023: [KFF](https://www.kff.org/other/state-indicator/distribution-by-sex/?currentTimeframe=0&sortModel=%7B%22colId%22:%22Location%22,%22sort%22:%22asc%22%7D)
    * Sex Ratio 2023 - 2023 sex ratio from [wisevoter](https://wisevoter.com/state-rankings/male-to-female-ratio-by-state/#wisconsin)
    * 2020 is missing due to Covid. For 2020, I use the average number of 2019 and 2021. 
3. High school graduates or higher, 2007-2023: [Fed](https://fred.stlouisfed.org/release/tables?rid=330&eid=391443)
4. Gay event and resources, 2012-2023: [Damron](https://damron.com/events-and-tours/previous-events#events_September_2023)
5. Covid death and cases, 2020-2023, covid data from https://github.com/nytimes/covid-19-data/blob/master/us-states.csv
6. State-statefips crosswalk
7. state-stateabbraviation crosswalk
8. `vote2016` & `vote2020`: 2016 and 2020 presidential election turnout, results saved to trump vs. non-trump vote, data from Federal Election Commission. October 2022.


* (Missing) Population: [FBI Crime Data Explorer](https://cde.ucr.cjis.gov/LATEST/webapp/#) 

## Potential Data Candidates
1. [American Value Altas](https://ava.prri.org/about), *Starting from 2014, LGBTQ topics from 2015*: The American Values Atlas (AVA) is a powerful new tool for understanding the complex demographic, religious, and cultural changes occurring in the United States today. Recognizing the need to provide a more complete portrait of substantial diversity of opinion, identities and values across the U.S. PRRI launched the AVA in late 2014. In 2015, the AVA launched specific issue modules, covering topics such as immigration, abortion, LGBTQ issues, and others.
