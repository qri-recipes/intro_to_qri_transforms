load("http.star", "http")
load("encoding/csv.star", "csv")
load("zipfile.star", "ZipFile")
load("qri.star", "qri")

countryCodes = load_dataset("b5/country_codes")

# download is a special function called automatically by Qri if defined
def download(ctx):
  # perform a HTTP GET request to the world bank API
  res = http.get("http://api.worldbank.org/v2/en/indicator/SP.POP.TOTL?downloadformat=csv")

  # response is a zip file with names that change on each download. first, open the zip archive:
  zf = ZipFile(res.body())

  # grab the 2nd file of three files, which contains the data we're after
  nl = zf.namelist()
  if len(nl) != 3:
    error("expected list of files to equal 3")

  # read raw data into a string
  rawCsvData = zf.open(nl[1]).read()
  # pass raw CSV data to the transform step
  return rawCsvData


# transform is a special function called automatically by Qri if defined
def transform(ds, ctx):
  # world bank api only gives us access to country codes mixed with other (often useful!) country-like
  # entities like "upper middle class" and "Sub-Saharan Africa (excluding high income)"
  # we need a list of actual ISO 3166 alpha_3 country codes, which this dataset provides on column index 7
  threeLetterCountryCodes = [cc[7] for cc in countryCodes.get_body()]
  
  # assign csv data from download to a variable
  rawCsvData = ctx.download
  # data comes with two citation-oriented header rows, let's lop them off by reading csv data
  parsedCsv = csv.read_all(rawCsvData, lazy_quotes=True, fields_per_record=-1, skip=2)
  
  # construct dataset structure
  st = structure(parsedCsv[0])
  ds.set_structure(st)

  # filter out "countries" that aren't valid ISO 3116 alpha 3 country codes
  onlyContries = [x for x in parsedCsv if x[1] in threeLetterCountryCodes]

  # convert back to csv data without header row
  csvString = csv.write_all(onlyContries)
  ds.set_body(csvString,raw=True,data_format='csv')


"""
Helper functions
"""

# structure is a custom function for extracting a dataset structure.
# we need this this because Qri doesn't guess the schema correctly for us
# so we build one by hand
def structure(header_row):
  # construct baseline schema with titles, all types as integer
  items = [{ 'title': title, 'type': 'integer' } for title in header_row]
  
  # first three columns are string type
  for i in range(0,4):
    items[i]['type'] = 'string'

  # return a full structure component that includes the custom schema
  return {
    'format': 'csv',
    'formatConfig': {
      'lazyQuotes' : True,
      'headerRow' : True,
    },
    'schema' : {
      'type' : 'array',
      'items' : {
        'type' : 'array',
        'items' : items
      }
    }
  }
