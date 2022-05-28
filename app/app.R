renv::activate()

library(shiny)
library(shinydashboard)
library(mapview)
library(shinythemes)
library(dashboardthemes)
library(RPostgres)


ui <- dashboardPage(
  dashboardHeader(title = "REI Data Warehouse"),
  dashboardSidebar(sidebarMenu(
    menuItem("Overview",
             tabName = "1Overview",
             icon = icon("dashboard")),
    menuItem("Detailed",
             tabName = "2Detailed",
             icon = icon("th")),
    menuItem("Map",
             tabName = "3Map",
             icon = icon("map-pin"))
  )),
  dashboardBody(
    shinyDashboardThemes(
      theme = "poor_mans_flatly"
    ),
    tabItems(
    # First tab content
    tabItem(tabName = "1Overview",
            fluidRow()),
    
    # second tab content
    tabItem(tabName = "2Detailed",
            h2("*factListings analysis*"))
    ,
    
    # third tab content
    tabItem(tabName = "3Map",
            h2("dimProperty Locations"),
          
              leafletOutput("map")
            )
  ))
)

server <- function(input, output) {
  
  ##########################################
  # tab 1 - Australia housing outlook - slice by state
  ##########################################
  # - median house price
  # - bar graph with no. bedrooms, bath, parking
  # - median house/land size
  # - 'hottest' suburbs 
  # - slicer to slice above by state
  
  ##########################################
  con <- dbConnect(RPostgres::Postgres(),
                   host="localhost",
                   port="5432",
                   dbname="REI_Prod",
                   user="postgres",
                   password=Sys.getenv("REI_Prod_password"))
  
  factListings <- dbGetQuery(con, "
  SELECT
  *
  FROM
  public.\"factListings\"
  ;
  ")
  
  # put a card of number of listings - slice by states - 1 query modifying where clause
  factListings[1]
 
  dimProperty <- dbGetQuery(con, "
  SELECT
  *
  FROM
  public.\"dimProperty\"
  ;
  ")

  ##########################################
  # tab 2 - map only - change to FL
  ##########################################
  ref_df <-
    read.csv(paste0(
      Sys.getenv("Backend_API_v2"),
      "/data/geocoded_loc_ref.csv"
    ))
  
  # remove nulls (if blanks in cache)
  ref_df <- sqldf(
    "
            SELECT
            *
            FROM
            ref_df
            WHERE
            (longitude IS NOT NULL OR latitude IS NOT NULL)
            AND
            (latitude < -10.360438)
            AND
            (latitude < -10.360438)
            AND
            (latitude > -45.599262)
            AND
            (longitude > 111.861226)
            AND
            (longitude < 155.542866)
            ;
            "
  )
  # AU
  # UB and LB = -10.360438 <-> -45.599262 (latitude range)
  # LB and RB = 111.861226 <-> 155.542866 (longitude range)
  
  locations <- st_as_sf(ref_df,
                        coords = c("longitude", "latitude"),
                        crs = 4326)
  
  
  output$map <- renderLeaflet({
    mapview(locations, legend = NULL)@map
  })
}

shinyApp(ui, server)
