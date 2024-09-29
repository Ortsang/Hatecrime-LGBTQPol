# Data Folder

This folder contains the datasets used in the research study on hate crime, mental health, and LGBTQ politicians. The data is divided into raw, unprocessed data and cleaned, processed datasets.

Not all datasets will be stored in the Github, given the data limit. The origin location will be indicated if the dataset can not be uploaded or restored

## Folder Structure
```
data
├── raw/               # Original, unprocessed datasets
|   └── HCSP/           # Hate crime HCSP data from FBI
|       ├── Raw Tables      # Raw Tables from HCSP system
|       └── Processed Data  # Processed Data, mostly stored in Dta form
├── processed/         # Cleaned and modified datasets for analysis
└── README.md          # Documentation for data sources and preprocessing
```

## `raw/`
The `raw` folder contains the original datasets collected from various sources. These datasets are not modified and are stored here for reference.
### BRFSS
The Behavioral Risk Factor Surveillance System (BRFSS) data is available: https://www.cdc.gov/brfss/behavioral-risk-factor-surveillance-system.html. Due to the size of the data, it can not be stored in Github. But this list contains all the year location and the code book

| BRFSS-Year                | Codebook |
| :--------------------     | ------- |
| [2011 Annual Survey Data](https://www.cdc.gov/brfss/annual_data/annual_2011.htm)   | [Link](https://www.cdc.gov/brfss/annual_data/2011/pdf/CODEBOOK11_LLCP.pdf)    |
|                                                                                      |            |

### Hate Crime
The hate crime data is from FBI Hate Crime Statistics Program (HCSP). Through the HCSP, the FBI Uniform Crime Reporting (UCR) Program collects hate crime data on crimes that were motivated by an offender’s bias against a race, religion, disability, sexual orientation, ethnicity, gender, or gender identity. The categories of bias have changed over time, and now include 6 categories of bias motivation and 34 specific types of bias. Determining if an offender was motivated by bias can be difficult, and the FBI instructs reporting agencies to report bias “only if investigation reveals sufficient objective facts to lead a reasonable and prudent person to conclude that the offender’s actions were motivated, in whole or in part, by bias."

As of January 1, 2021, the FBI National Incident-Based Reporting System (NIBRS) is the national standard by which law enforcement agencies submit crime data to the FBI. NIBRS agencies indicate whether an offense was motivated by an offender’s bias against the victim for each reported offense. For more information, refer to the FBI’s Hate Crime Statistics program page.

Note: Florida changed its reporting system in 2021, therefore the raw dataset contains no quarterly data for Florida in 2021; we supplement the data with [Florida Hate Crime Report](https://www.myfloridalegal.com/files/pdf/page/BE0185D36969417B852589270066D783/Web+Link.pdf).



