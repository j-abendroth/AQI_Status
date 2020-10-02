# AQI Status
A macOS status bar app that lets you easily view your current AQI

`AQI_Status` is a status bar app that utilizes Purple Air data to give you an AQI score that is more accurate for your location than AirNow, due to Purple Air's larger network of censors. Input your choosen zip code at startup and `AQI_Status` will refresh the AQI with your choosen parameters every 15 minutes. 

![app preview](https://i.imgur.com/jDDlnMB.png)

## How does it work?

`AQI_Status` pulls data from Purple Air mimicking their online map API calls, and uses [Purple Air's given formulas](https://docs.google.com/document/d/15ijz94dXJ-YAZLi9iZ_RaBwrZ4KtYeCy08goGBwnbCU/edit) for calculating AQI with realtime data instead of the traditional 24 hour average. `AQI_Status` caches all sensors within 10 mi of the given zip code to enable changes to the PM2.5 conversion and filter distance without having to fetch new data from Purple Air. It uses Apple's CoreLocation to geocode a given zip code and present a coordinate that can be used to find purple air sensors in your area. 

## Configuration

Choose between recomended PM2.5 conversions for Purple Air's sensors, sensor distance filtering, and data averaging lengths to get the AQI data that is most useful to you. There are 2 different conversions presented, [AQandU](https://www.aqandu.org/airu_sensor#calibrationSection) and [LRAPA](https://www.lrapa.org/DocumentCenter/View/4147/PurpleAir-Correction-Summary). If you are monitoring AQI Data for wood smoke particles, it is recomended to choose 1 of these to correct Purple Air's overestimation of AQI scores, especially for AQI scores above 150. 

There are 6 options presented for data averaging length, which are just the 6 options given to choose from by Purple Air. By default, the app starts with 10 minute average. You can select realtime data, 10 minute average, 30 minute average, 1 hour average, 1 day average, and 1 week average. 

Finally, choose a distance filter between 1 and 10 miles from your source zip code. The app starts with a default of 2; if initially you see an AQI of 0 presented, increase the the filter distance as there may not be enough Purple Air sensors close to you. 

## Prerequisites 

`AQI_Status` was targeted and tested for macOS 10.15. It was designed with Xcode storyboards, not SwiftUI, so it's possible it will run on earlier versions of macOS. However, this is not tested.
