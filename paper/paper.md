---
title: 'gaia: An R package to estimate crop yield responses to temperature and precipitation'

tags:
  - 
authors:
  - name: Mengqi Zhao
    orcid: 0000-0001-5385-2758
    affiliation: 1
  - name: Stephanie T. Morris
    orcid: 0000-0002-8073-0868
    affiliation: 2
  - name: Claudia Tebaldi
    orcid: 0000-0001-9233-8903
    affiliation: 2
  - name: Abigail Snyder
    orcid: 0000-0002-9034-9948
    affiliation: 2

affiliations:
 - name: Pacific Northwest National Laboratory, Richland, WA, USA
   index: 1
 - name: Pacific Northwest National Laboratory, Joint Global Change Research Institute, College Park, MD, USA
   index: 2
date: 2024
bibliography: paper.bib
---

# Summary

`gaia` is an open-source R package designed to estimate crop yield shocks in response to annual weather variations and CO~2~ concentrations at the country scale for 12 major crops. This innovative tool streamlines the workflow from raw climate data processing to projections of annual shocks to crop yields at the country level, using the response surfaces developed and documented in @Waldhoff_2020, an empirical econometric model that leverages historical weather, CO~2~, and crop yield data for robust empirical fitting for 12 crops. `gaia` uses these response surfaces with bias-corrected, gridded monthly temperature and precipitation projections (e.g., from the Coupled Model Intercomparison Project Phase 6 (CMIP6) [@Oneil_2016] climate data bias-adjusted and statistically downscaled by ISIMIP3BASD approach [@Lange_2019] in the Inter-Sectoral Impact Model Intercomparison Project (ISIMIP) [@Warszawski_2014]) to project shocks that can be applied to agricultural productivity changes at the country-level for use in multisectoral economic models. The historical and future projections use gridded, country-crop specific monthly growing season precipitation and temperature data, aggregated to the national level, weighted by cropland area derived from the global Monthly Irrigated and Rainfed Crop Areas around the year 2000 (MIRCA2000) dataset [@Portmann_2010]. These annual, country, crop-specific yield shocks can be aggregated to different definitions of regions, crop commodities, and time periods, as needed by specific multisectoral economic models. `gaia` serves as a lightweight, powerful tool that can aid exploration of crop yields responses under a broad range of future climate projections, enhancing human-Earth system analysis capabilities.


# Statement of need

Agricultural production is highly responsive to annual weather patterns, which are becoming increasingly variable in response to climate change (e.g. @Iizumi_2016). Agricultural markets are global, and yield shocks in one region will therefore impact others due to the variability in international trade. In addition, agricultural production is closely connected with energy and water sectors. Improving the representation of agricultural production and their yield responses to changing weather patterns in global multi-sector dynamics models, such as the Global Change Analysis Model (GCAM)[@Calvin_2019; @GCAM_Documentation_2023], is key to better understanding economic impacts of climate change that account for human-Earth system interactions.

Most multisectoral economic modeling of climate change impacts on agriculture address only the long-term trends in temperature and precipitation effects on crop yields for a few key crops [@von-Lampe_2014]. There is a need to include projections of the impacts of inter-annual weather changes on yield responses for multiple crops under a wide range of climate projections [@Ray_2015]. However, the current crop modeling landscape lacks globally comprehensive, computationally efficient, validated models capable of the aforementioned needs [@Waldhoff_2020]. To address the gap, we have developed `gaia`, which uses the empirical model described in @Waldhoff_2020. `gaia` produces projections of both future annual variations and long-term trends in yield changes at the country-level for a wide range of crops (cassava, cotton, maize, rice, potatoes, sorghum, soybean, sugar beet, sugarcane, sunflower, and wheat) using gridded monthly temperature and precipitation inputs for any future climate scenario.


# State of the Field

The exploration of effects of future climate change on agricultural production is crucial for providing insights into global food, energy, water, and economic development. Various crop models, including process-based and empirical models, have been developed to simulate crop yields under different climate scenarios [@Chapagain_2022; @Rauff_2015]. @Muller_2017 conducted a Global Gridded Crop Model (GGCM) intercomparison experiment involving 14 process-based crop models, which allow users to simulate diverse crop management options, soil types, and weather conditions. However, GGCMs require large amounts of site-specific data for calibration, making extension to many crops and regions more challenging [@Muller_2017]. In addition, these models can take significant time to run and the yield shock projections are often available for only a limited number of climate change scenarios.

These considerations may limit the usefulness of yield changes from process models as inputs to global economic, multisector models, which include a wider range of crops and many future climate scenarios. `gaia` achieves this balance by employing computationally efficient statistical methods to model 12 major crops globally, while maintaining the sensitivity to capture both gradual climate changes and interannual variability impacts on crop yields. In addition, users can estimate yield shocks for additional crops by providing the appropriate input data.


# Functionality

The primary functionality of `gaia` is encapsulated in the `yield_impact` wrapper function that streamlines the entire workflow shown in \autoref{fig:workflow}. The modular design also facilitates comprehensive diagnostic outputs, enhancing the tool’s utility for researchers and decision makers. Users can also execute individual functions to work through the main steps of the process. Detailed instructions on installing and using `gaia` with example dataset can be accessed at https://jgcri.github.io/gaia.

1. `weighted_climate`: Processes CMIP6 daily or monthly climate NetCDF data formatted in accordance with the [ISIMIP simulation protocols](https://www.isimip.org/protocol/) and calculates cropland-weighted precipitation and temperature at the country level, differentiated by crop type and irrigation type.
2. `crop_calenders`: Generates crop planting months for each country and crop based on crop calendar data [@Sacks_2010].
3. `data_aggregation`: Calculates crop growing seasons using climate variables processed by `weighted_climate` and crop calendars for both historical and projected periods. This function prepares climate and yield data for subsequent model fitting.
4. `yield_regression`: Performs regression analysis fitted with historical annual crop yields, growing season monthly temperature and precipitation, CO~2~ concentrations, and GDP per capita. The default econometric model applied in `gaia` is from @Waldhoff_2020. User can specify alternative formulas that are consistent with the data processed in `data_aggregation`.
5. `yield_shock_projection`: Projects country-level yield shocks for future climate scenarios using the fitted model obtained from `yield_regression` and temperature, precipitation, and CO~2~ projections from the climate scenario. The outputs can be integrated into non-GCAM modeling frameworks requiring country-level yield responses to climate.
6. `gcam_agprodchange`: Generates GCAM-compatible outputs for agricultural productivity changes by GCAM commodity at the region-basin level. The function remaps country-level yield shocks from `yield_shock_projection` to GCAM-required spatial scales (i.e., region, basin, technology intersections), using harvested areas and aggregates crops into GCAM commodities. This function applies these projected shocks to GCAM scenario-specific agricultural productivity growth rates (the metric used to project future yields in GCAM) and creates ready-to-use XML outputs for GCAM.


![The gaia workflow showing the functions and the corresponding outputs of modeling crop yield shocks to weather variables using an empirical econometric model. \label{fig:workflow}](workflow.jpg)


# Acknowledgements
This research was supported by the US Department of Energy, Office of Science, as part of research in MultiSector Dynamics, Earth and Environmental System Modeling Program. The Pacific Northwest National Laboratory is operated for DOE by Battelle Memorial Institute under contract DE-AC05-76RL01830. The views and opinions expressed in this paper are those of the authors alone.

# References
