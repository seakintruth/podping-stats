# Database reading functions
authenticate_with_postgres <- function() {
  # Prompt user if password is not yet set
  if (! Sys.getenv("PGPASSWORD") == "") {
    # This user only has read access to the database
    Sys.setenv(PGPASSWORD = readLines(file("~/env/read_all_user_access.txt")))
  }
  # Set environment variables for pgsql connection
  if (! Sys.getenv("PGHOST") == "127.0.0.1") {
    Sys.setenv(PGHOST = "127.0.0.1")
  }
  if (! Sys.getenv("PGPORT") == "5432") {
    Sys.setenv(PGPORT = "5432")
  }
  if (! Sys.getenv("PGUSER") == "read_all") {
    Sys.setenv(PGUSER = "read_all")
  }
  if (! Sys.getenv("PGDBNAME") == "plug_play") {
    Sys.setenv(PGDBNAME = "plug_play")
  }
}


dbfetch_table_podping <- function(table_name) {
  dbfetch_query_podping(paste0("SELECT * FROM ", table_name))  
}

dbfetch_query_podping <- function(query_sql) {
  authenticate_with_postgres()
  # If password environment variable isn't set, then perform authentication
  if (Sys.getenv("PGPASSWORD") == "") {
    authenticate_with_postgres()
  }

  # Connect to the default postgres database
  connection <- DBI::dbConnect(
    RPostgres::Postgres(),
    dbname = Sys.getenv("PGDBNAME")
  )

  # Send the Query
  table_con <- DBI::dbSendQuery(connection, query_sql)

  # Fetch results
  table_results <- DBI::dbFetch(table_con)
 
  # Close the connection
  DBI::dbClearResult(table_con)
  DBI::dbDisconnect(connection)

  # Return results
  table_results
}


# When this changes we need to get new data
get_last_hive_block_num <-function() {
  dbfetch_query_podping(
    "SELECT block_num FROM custom_json_ops ORDER BY id DESC LIMIT 1;"
  )
}
get_podpings_served <- function() {
  dbfetch_query_podping(
    "SELECT count(*) FROM public.podping_urls;"
  )
}
get_host_summary <- function(number_of_days) {
  dbfetch_table_podping("podping_host_summary_last_day_sub_example")
}
get_url_timestamp <- function() {
  dbfetch_table_podping("podping_url_timestamp")
}
get_url_count_by_day <- function() {
  dbfetch_table_podping("podping_url_count_by_day")
}
get_url_count_by_hour <- function() {
  dbfetch_table_podping("podping_url_count_by_hour")
}
get_url_count_by_minute <- function() {
  dbfetch_table_podping("podping_url_count_by_minute")
}