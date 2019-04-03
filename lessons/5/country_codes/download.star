load("http.star", "http")

def download(ctx):
  res = http.get("https://datahub.io/core/country-codes/r/country-codes.csv")
  return res.body()

def transform(ds,ctx):
  ds.set_body(ctx.download, data_format="csv", raw=True)