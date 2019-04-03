# Lesson 1: Creating a Dataset from a CSV file

### Let's look at the world bank dataset:
https://data.worldbank.org/indicator/SP.POP.TOTL

```
http://api.worldbank.org/v2/en/indicator/SP.POP.TOTL?downloadformat=csv
```

```
$ qri save --body API_SP.POP.TOTL_DS2_en_csv_v2_10473719.csv me/world_bank_population
```