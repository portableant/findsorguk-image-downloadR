# Set your working directory
setwd("/Users/danielpett/Documents/research/electricarchaeo")

# Use the following libraries
library(jsonlite)
library(RCurl)

# The base URL for PAS
base <- 'https://finds.org.uk/'

## Set your query up 
# The important parameters for you to include in a search are:
# q/{queryString} - which has your free text or parameterised search e.g. q/gold/broadperiod/BRONZE+AGE
# /thumbnail/1 - ask for records with images
# /format/json - ask for json response
##
url <- "https://finds.org.uk/database/search/results/q/institution%3ANMGW/thumbnail/1/format/json"

# Get your JSON and parse
json <- fromJSON(url)
total <- json$meta$totalResults
results <- json$meta$resultsPerPage
pagination <- ceiling(total/results)

# Set which fields to keep - I made a mistake when building PAS and removed NULL Key:Values
keeps <- c(
  "id", "objecttype", "old_findID",
  "broadperiod", "institution", "imagedir", 
  "filename"
)

data <- json$results

data <- data[,(names(data) %in% keeps)]

for (i in seq(from=2, to=3, by=1)){
  urlDownload <- paste(url, '/page/', i, sep='')
  pagedJson <- fromJSON(urlDownload)
  records <- pagedJson$results
  records <- records[,(names(records) %in% keeps)]
  data <-rbind(data,records)
}

# Write a csv file of the data you want
write.csv(data, file='data.csv',row.names=FALSE, na="")
# Throw in a log file
failures <- "failures.log"
log_con <- file(failures)

# Download function with test for URL
download <- function(data){
  object = data[3]
  record = data[2]
  # Check and create a folder for that object type if does not exist
  if (!file.exists(object)){
    dir.create(object)
  }
  # Create image url
  URL = paste0(base,data[7],data[6])
  
  # Test the file exists
  exist <- url.exists(URL) 
  
  # If it does, download. If not say 404
  if(exist == TRUE){
    download.file(URLencode(URL), destfile = paste(object,basename(URL), sep = '/'))
  } else {
    print("That file is a 404")
    # Log the errors for sending back to PAS to fix
    message <- paste0(record,"|",URL,"|","404 \n")
    cat(message, file = failures, append = TRUE)
    
  }
}

# Apply the function
apply(data, 1, download)

# Show me the money