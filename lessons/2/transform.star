load("http.star", "http")
load("encoding/csv.star", "csv")
load("zipfile.star", "ZipFile")
load("qri.star", "qri")

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
  # assign csv data from download to a variable
  rawCsvData = ctx.download

  # data comes with two citation-oriented header rows, let's lop them off by reading csv data
  parsedCsv = csv.read_all(rawCsvData, lazy_quotes=True, fields_per_record=-1, skip=2)
  # convert back to csv data without header row
  csvString = csv.write_all(parsedCsv)
  
  ds.set_body(csvString,raw=True,data_format='csv')