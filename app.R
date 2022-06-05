setwd(Sys.getenv("dw-rei"))

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
library(ggthemes)
library(ggplot2)
library(formattable)

ui <- dashboardPage(
  dashboardHeader(title = "REI AU"),
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
  dashboardBody(
    # shinyDashboardThemes(theme = "grey_dark"),
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
        fluidRow(column(
          width = 8,
          
          box(
            # title = "",
            width = NULL,
            solidHeader = TRUE,
            plotOutput("PriceGraph")
          ),
          
        ),
        
        
        column(
          width = 4,
          box(
            title = "Slicer",
            width = NULL,
            solidHeader = TRUE,
            status = "primary",
            # background = "light-blue",
            
            radioButtons(
              "region",
              "Region:",
              c(
                "Australia" = "",
                "Australian Capital Territory" = 0,
                "New South Wales" = 1,
                "Northern Territory" = 2,
                "Queensland" = 3,
                "South Australia" = 4,
                "Tasmania" = 5,
                "Victoria" = 6,
                "Western Australia" = 7
              )
            )
          ),
          
        ))
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
  
  ################
  # GET DATA
  ##################
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
  
  df_price_graph <- sqldf(
    "
    SELECT
    listing_download_date AS Listing_Date
    ,median(price) AS Median_Price
    FROM
    factListings
    GROUP BY
    listing_download_date
    ;
    "
  )
  
  df_median_price <- sqldf("
    SELECT
    median(price)
    FROM
    factListings
    ;
    ")
  
  
  df_median_land_size <- sqldf("
    SELECT
    median(land_size)
    FROM
    factListings
    WHERE
    land_size_unit = 'm²'
    ;
    ")
  
  
  #####################
  
  # put a card of number of listings - slice by states - 1 query modifying where clause

  # OLD #########################################
    # output$listingNumberBox <- renderValueBox({
  #   valueBox(
  #     currency(
  #       dim(factListings)[1],
  #       big.mark = " ",
  #       digits = 0L,
  #       symbol = ""
  #     ),
  #     "Listings",
  #     icon = icon("home"),
  #     color = "blue"
  #   )
  # })
  
  # NEW #########################################
  query_fact_count <- paste0("
  SELECT
  count(*)
  FROM
  public.\"factListings\"
  ;
  "
  , 
  "variable")
  fact_count <- dbGetQuery(con, "
  SELECT
  count(*)
  FROM
  public.\"factListings\"
  ;
  "
  )
  
  output$listingNumberBox <- renderValueBox({
    valueBox(
        dim(factListings)[1],
      "Listings",
      icon = icon("home"),
      color = "blue"
    )
  })
  ##############################################
  output$listingMedianPriceBox <- renderValueBox({
    valueBox(
      currency(df_median_price[1, 1],
               digits = 0L,
               symbol = ""),
      "Median price",
      icon = icon("dollar-sign"),
      color = "blue"
    )
  })
  
  output$listingMedianLandSizeBox <- renderValueBox({
    valueBox(
      paste0(
        currency(
          df_median_land_size[1, 1],
          big.mark = " ",
          digits = 0L,
          symbol = ""
        ),
        " m²"
      ),
      "Median land size",
      icon = icon("resize-full", lib = "glyphicon"),
      color = "blue"
    )
  })
  
  output$PriceGraph <- renderPlot({
    ggplot(df_price_graph,
           aes(x = Listing_Date,
               y = Median_Price,
               group = 1))  +
      geom_line() +
      geom_point() +
      ggthemes::theme_fivethirtyeight() +
      theme(axis.text.x = element_text(
        angle = -270,
        hjust = 0,
        vjust = -0.1
      ))
  })
  
  ##########################################
  # tab 2 - Map
  ##########################################
  
  dimProperty_coords <- read.csv(paste0(
    Sys.getenv("dw-rei"),
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


################

shinyApp(ui, server)
