# Summary

This is my diploma project, which was developed within the diploma thesis. My diploma thesis deals with the statistical analysis of data measured over time. For the purposes of statistical analysis, the MATLAB program was used, in which a fully functional project was developed. The project consists of several functions and applications that allow users to effectively view the data from many different angles, thus helping them to achieve the desired results. My thesis also points to the usage of MATLAB in the field of data science.

# 1. Applications

## 1.1. ETL Configuration
### Description
Using the application is very simple and intuitive for any user. The design of the application acts as an installation wizard, in which buttons such as *Next* (*Ďalej* in Slovak), *Back* (*Späť* in Slovak) and *Cancel* (*Zrušiť* in Slovak) appear by default. The data preparation process is divided into six steps. The first 5 steps concern the selection of all necessary input parameters for the background functions of the ETL process. In the first step, the application asks the user to choose which ETL process operation he wants to perform. Depending on this selection, the user is obliged in the second step to state the full path to the folder in which the collected measurement data is located in the _*.csv_ format. If the user has chosen the ETL Append operation, he also has the option to specify the path to a single file, ie the full path, including the name and extension of a specific _*.csv_ file. In the third step, the user enters a numerical value that represents a constant time interval of the individual measurements in seconds. If there is also a unit or any other textual data in the column of collected data of numerical values, the user must state this unit in the fourth step. The last input that the user needs to specify is a numeric value that represents the maximum number of consecutive hours or hourly sections. All interrupted time periods whose length in hours is less than or equal to the specified tolerance will be automatically filled in using a moving average. In the last step, the application asks the user to check the data before executing the selected ETL operation. Then the *Start* button (*Spustiť* in Slovak) starts the operation, which may take several hours depending on the amount of data entering the operation. The output of this application are two timetables. Table of structured measurement data and table of calculated statistical parameters. Both of these timetables are necessary for every other application and function of this project.
### Instructions
- Step 1 - Choose operation (*Vyberte operáciu* in Slovak)
  - *ETL Update* - This operation is used for the initial upload of data.
  - *ETL Append* - This operation is used to expand the database.
- Step 2 - Enter the path. (*Vložte cestu* in Slovak)
- Step 3 - Enter measurement step (in seconds). (*Krokovanie merania (s)* in Slovak)
- Step 4 - Enter the units. (*Jednotky* in Slovak)
- Step 5 - Enter the tolerance (in hours). (*Tolerancia (h)* in Slovak)
- Step 6 - Check the input settings. If everything fits, press the Start (*Spustiť* in Slovak) button.
### Preview of ETL Configuration application (Step 5)
![Preview](https://i.imgur.com/oiZHJSx.png)

## 1.2. Descriptive Statistics
### Description
This application is used to visualize the data of the measured signal of the selected day and also to visualize changes in the statistical parameters of that day. The application consists of two tabs that are independent of each other. The first tab shows the statistical parameters of the descriptive statistics and the second tab contains a display of several other statistical parameters, which were mostly derived from the parameters shown in the first tab. An example of an open application is shown in the image below.
### Preview of Descriptive Statistics application (first tab)
![Preview](https://i.imgur.com/37R1m7K.png)
### Preview of Descriptive Statistics application (second tab)
![Preview](https://i.imgur.com/q30U4Jt.png)

## 1.3. Signals
### Description
We can sometimes find interesting insights in the illustrations of the time series themselves. Depending on the shape of the signal, we can sometimes state or estimate the possible causes of this shape. Through an interactive application called *Signals*, we have the ability to view the signals of the measured data. In the application, it is possible to display at one time up to four consecutive time series of measured data with a constant time interval. The example of application usage for 60-minute intervals is shown in the figure below.
### Preview of Signals application
![Preview](https://i.imgur.com/veZUYvU.png)

## 1.4. Statistics
### Description
This application is used for data analysis and offers a closer look at individual samples of signals of the measured quantity. In the upper part, the main control panel is located along the entire application. This panel has the same purpose as the panel in the first application. In the area below the control panel, there is a signal time series plot of the selected sample of measured data marked with the title *Signal*. In the lower left part of the display there is a table of statistical parameters for the currently selected sample. Illustrations of distribution functions are located on the right side of the table. An illustration titled *Probability Density Function* is a function of the probability density. Below this graph is a cumulative distribution function titled *Cumulative Distribution Function*. The illustration located in the lower right part of the application with the title *Actual over estimated observations* was created by a relatively complex process, which is described in detail in the thesis.
### Preview of Statistics application
![Preview](https://i.imgur.com/Uo4YkK7.png)

# 2. Functions
## 2.1. Correlation Diagrams
### Description
The `plot_correlation_diagram()` function provides us an interesting view of the measured data. This visualization illustrates the relationship between the values of two statistical parameters that were calculated from samples of measured data on a given day. These samples have a constant length, which is determined by the first input argument of the function. In the following example of a function call, an interval length of 10 minutes was selected.
### Example Command
`plot_correlation_diagram(stats_10_2019, {'SD', 'Range'}, [4, 7], 3, 1);`
### Preview of Correlation Diagrams function output
![Preview](https://i.imgur.com/A8DIFFR.png)

## 2.2. Correlation Weekdays
### Description
While the previous function illustrated the similarity between the values of two different statistical parameters, the `plot_correlation_weekdays()` function illustrates the similarity between several of the same statistical parameters but calculated from different measurement days. The result of this function is a two-dimensional temperature map (also known as a Heat Map) of a selected statistical parameter, which was calculated from data on the same days in the week of the selected month. In the following example, we call the `plot_correlation_weekdays()` function for range signals calculated from the 10-minute intervals of all Tuesdays (Monday = 1, Tuesday = 2, etc.) in October (January = 1, February = 2, etc.) in 2019.
### Example Command
`plot_correlation_weekdays(stats_10_2019, 'Range', [2, 10]);`
### Preview of Correlation Weekdays function output
![Preview](https://i.imgur.com/nN4mr4P.png)

## 2.3. 2D Maps
### Description
Another function that offers us an interesting way or angle of view of the data is a function called `plot_signal_2D_maps()`. This function illustrates the values of an arbitrarily selected measurement time period placed against the same values shifted one row forward. In this way, a two-dimensional map of the occurrence of values in the specified time series is displayed, which indicates the magnitude of the signal change. In other words, these maps illustrate in an unconventional way the function of the first derivative of the measured signal.
### Example Command
`plot_signal_2D_maps(values_clean_2019, 15, [24, 12, 16, 30], 3, 1);`
### Preview of 2D Maps function output
![Preview](https://i.imgur.com/GK2u7jD.png)

## 2.4. Fast Fourier Transformation (FFT)
### Description
When analyzing time-stamped data, it is in some cases appropriate to examine this data using the fast Fourier transform function. With the help of this visualization we can find out whether the measured signal has a periodic character at some specific frequencies.
### Example Command
`plot_signal_FFT(values_clean_2019, 30, 1, [20, 6, 17, 0], 1);`
### Preview of Fast Fourier Transformation (FFT) function output
![Preview](https://i.imgur.com/pqrIOUb.png)
