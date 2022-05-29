setwd(Sys.getenv("Backend_API_v2"))

renv::activate()

library(shiny)
library(shinydashboard)
library(mapview)
library(shinythemes)
library(dashboardthemes)
library(RPostgres)
library(leaflet)
library(sqldf)
library(sf)
library(gapminder)
library(ggplot2)

ui <- dashboardPage(
  # theme = shinytheme("united"),
  dashboardHeader(title = "AU Properties"),
  dashboardSidebar(sidebarMenu(
    menuItem(
      "Dashboard",
      tabName = "1Dashboard",
      icon = icon("dashboard", verify_fa = FALSE)
    ),
    menuItem("Map",
             tabName = "3Map",
             icon = icon("map-pin"))
  )),
  dashboardBody(# shinyDashboardThemes(theme = "grey_dark"),
    tabItems(
      # First tab content
      tabItem(
        tabName = "1Dashboard",
        fluidRow(
          # Dynamic valueBoxes
          valueBoxOutput("listingNumberBox"),
          
          valueBoxOutput("listingMedianPriceBox"),
          
          valueBoxOutput("listingMedianLandSizeBox")
        ),
        fluidRow(
          column(
            width = 8,
            
            box(
              title = "Number of listings",
              width = NULL,
              solidHeader = TRUE,
              plotOutput("graph1")
            ),
            # box(
            #   title = "Title",
            #   width = NULL,
            #   solidHeader = TRUE,
            #   "Box content"
            # ),
            # box(
            #   title = "Title",
            #   width = NULL,
            #   solidHeader = TRUE,
            #   "Box content"
            # )
          ),
          
          # column(
          #   width = 4,
          #   box(
          #     title = "Median price",
          #     width = NULL,
          #     solidHeader = TRUE,
          #     "Box content"
          #   ),
          #   box(
          #     title = "Title",
          #     width = NULL,
          #     solidHeader = TRUE,
          #     "Box content"
          #   ),
          #   box(
          #     title = "Title",
          #     width = NULL,
          #     solidHeader = TRUE,
          #     "Box content"
          #   )
          # ),
          
          column(
            width = 4,
            box(
              title = "Slicer",
              width = NULL,
              solidHeader = TRUE,
              status = "primary",
              # background = "light-blue",
              
              radioButtons("dist", "Region:",
                           c("Australia" = "Australia",
                             "Australian Capital Territory" = "Australian Capital Territory",
                             "New South Wales" = "New South Wales",
                             "Northern Territory" = "Northern Territory",
                             "Queensland" = "Queensland",
                             "South Australia" = "South Australia",
                             "Tasmania" = "Tasmania",
                             "Victoria" = "Victoria",
                             "Western Australia" = "Western Australia"))
            )
            
          )
        )
      ),
      
      # second tab content
      tabItem(tabName = "3Map",
              
              leafletOutput("map"))
    ))
)

server <- function(input, output) {
  ##########################################
  # tab 1 - Australia housing outlook - slice by state
  ##########################################
  # - median house price
  # - # props
  # median house price over time (seperate slicer)
  # - bar graph with no. bedrooms, bath, parking?
  # - median house/land size
  # - 'hottest' suburbs
  # - slicer to slice above by state
  # - slice by time period (download date)
  
  con <- dbConnect(
    RPostgres::Postgres(),
    host = "localhost",
    port = "5432",
    dbname = "REI_Prod",
    user = "postgres",
    password = Sys.getenv("REI_Prod_password")
  )
  
  factListings <- dbGetQuery(con, "
  SELECT
  *
  FROM
  public.\"factListings\"
  ;
  ")
  
  dimProperty <- dbGetQuery(con, "
  SELECT
  *
  FROM
  public.\"dimProperty\"
  ;
  ")
  
  # put a card of number of listings - slice by states - 1 query modifying where clause
  output$listingNumberBox <- renderValueBox({
    valueBox(
      10000,
      "Listings",
      icon = icon("home"),
      color = "green"
    )
  })
  
  output$listingMedianPriceBox <- renderValueBox({
    valueBox(
      0.5,
      "Median price",
      icon = icon("dollar-sign"),
      color = "yellow"
    )
  })
  
  output$listingMedianLandSizeBox <- renderValueBox({
    valueBox(
      paste0(500, " m2"),
      "Median land size",
      icon = icon("resize-full", lib = "glyphicon"),
      color = "red"
    )
  })
  
  usa <- dplyr::filter(gapminder, continent=="Americas", country=="United States")

  output$graph1 <- renderPlot({
      ggplot(usa, aes(x = year, y = pop)) +
      geom_line()
    
  })
  
  ##########################################
  # tab 2 - Map
  ##########################################
  
  dimProperty_coords <- read.csv(paste0(
    Sys.getenv("Backend_API_v2"),
    "/data/geocoded_loc_ref.csv"
  ))
  
  # remove nulls (if blanks in cache)
  dimProperty_coords <- sqldf(
    "
  SELECT
  *
  FROM
  dimProperty_coords
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
  
  listed <- sqldf(
    "
    SELECT
    dpc.full_address
    ,dpc.longitude
    ,dpc.latitude
    FROM
    dimProperty_coords dpc
    LEFT JOIN
    dimProperty dp
    ON
    dpc.full_address = dp.full_address
    INNER JOIN
    factListings fl
    ON
    dp.property_id = fl.property_id
    ;

    "
  )
  
  listed_map <- st_as_sf(listed,
                         coords = c("longitude", "latitude"),
                         crs = 4326)
  
  
  output$map <- renderLeaflet({
    mapview(listed_map,
            legend = NULL,
            alpha.regions = 0.2)@map
  })
}

shinyApp(ui, server)
