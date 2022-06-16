setwd(Sys.getenv("dw-rei"))

renv::activate()

library(shiny)
library(shinydashboard)
library(mapview)
library(dashboardthemes)
library(RPostgres)
library(leaflet)
library(sqldf)
library(sf)
library(ggthemes)
library(ggplot2)
library(formattable)

options(scipen = 999)

dynamic_query <- function(con, state){
  state_id <- base::switch(
    state,
    "Australia" = "(0, 1 ,2 ,3, 4, 5, 6, 7)",
    "ACT" = "(0)",
    "NSW" = "(1)",
    "NT" = "(2)",
    "QLD" = "(3)",
    "SA" = "(4)",
    "TAS" = "(5)",
    "VIC" = "(6)",
    "WA" = "(7)"
    
  )
  query_results <- list(
    toString(dbGetQuery(con, sprintf(
      paste0("SELECT ", 
             "count(*) ",
             "FROM ",
             "public.\"factListings\" fl ",
             "LEFT OUTER JOIN ",
             "public.\"dimProperty\" dp ",
             "ON ",
             "fl.\"property_id\" = dp.\"property_id\" ",
             "WHERE ",
             "dp.\"state_id\" IN %s",
             ";"),
      state_id))[1, 1])
    ,
    toString(dbGetQuery(con, sprintf(
      paste0("WITH ",
             "fl_price AS ",
             "( ",
             "SELECT ",
             "1 ",
             "UNION ALL ",
             "SELECT ",
             "2 ",
             "UNION ALL ",
             "SELECT ", 
             "100 ",
             ") ",
             "SELECT ",
             "percentile_cont(0.5) WITHIN GROUP ", 
             "( ",
             "ORDER BY fl.\"price\" ",
             ") ",
             "FROM ",
             "PUBLIC.\"factListings\" fl ",
             "LEFT OUTER JOIN ",
             "PUBLIC.\"dimProperty\" dp ",
             "ON ",
             "fl.\"property_id\" = dp.\"property_id\" ", 
             "WHERE dp.\"state_id\" IN %s ",
             ";"),
      state_id))[1, 1])
    ,
    toString(dbGetQuery(con, sprintf(
      paste0("WITH ",
             "fl_land_size AS ",
             "( ",
             "SELECT ",
             "1 ",
             "UNION ALL ",
             "SELECT ",
             "2 ",
             "UNION ALL ",
             "SELECT ", 
             "100 ",
             ") ",
             "SELECT ",
             "percentile_cont(0.5) WITHIN GROUP ", 
             "( ",
             "ORDER BY fl.\"land_size\" ",
             ") ",
             "FROM ",
             "PUBLIC.\"factListings\" fl ",
             "LEFT OUTER JOIN ",
             "PUBLIC.\"dimProperty\" dp ",
             "ON ",
             "fl.\"property_id\" = dp.\"property_id\" ", 
             "WHERE dp.\"state_id\" IN %s ",
             ";"),
      state_id))[1, 1])
    ,
    dbGetQuery(con, sprintf(
      paste0("WITH ",
             "fl_price AS ", 
             "( ",
             "SELECT ", 
             "1 ",   
             "UNION ALL ",
             "SELECT ", 
             "2 ",
             "UNION ALL ",
             "SELECT ", 
             "100 ",
             ") ",
             "SELECT ",
             "listing_download_date AS Listing_Date ",
             ",percentile_cont(0.5) WITHIN GROUP (ORDER BY fl.price) AS Median_Price ",
             "FROM ",
             "public.\"factListings\" fl ", 
             "LEFT OUTER JOIN ", 
             "public.\"dimProperty\" dp ", 
             "ON ", 
             "fl.\"property_id\" = dp.\"property_id\" ", 
             "WHERE dp.\"state_id\" IN %s ",
             "GROUP BY ",
             "fl.listing_download_date ",
             ";"),
      state_id))
  )
  return(query_results) 
}

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

ui <- dashboardPage(
  dashboardHeader(title = "AU Property App"),
  dashboardSidebar(sidebarMenu(
    menuItem(
      "Dashboard",
      tabName = "1Dashboard",
      icon = icon("dashboard", verify_fa = FALSE)
    ),
    menuItem("Map",
             tabName = "2Map",
             icon = icon("map-pin"))
    ,
    menuItem("Criteria",
             tabName = "3Criteria",
             icon = icon("filter", lib = "glyphicon"))
    ,
    menuItem("Leads",
             tabName = "4Leads",
             icon = icon("eye-open", lib = "glyphicon"))
    ,
    menuItem("Calculator",
             tabName = "5Calculator",
             icon = icon("calculator"))
  )),
  dashboardBody(
    shinyDashboardThemes(
      theme = "grey_light"
    ),
    tabItems(
      # tab 1 content
      tabItem(
        tabName = "1Dashboard",
        fluidRow(
          # dynamic valueBoxes
          valueBoxOutput("listingNumberBox"),
          valueBoxOutput("listingMedianPriceBox"),
          valueBoxOutput("listingMedianLandSizeBox")
        ),
        fluidRow(column(
          width = 8,
          box(
            width = NULL,
            solidHeader = TRUE,
            plotOutput("PriceGraph")
          ),
          
        ),
        
        column(
          width = 4,
          box(
            width = NULL,
            solidHeader = TRUE,
            radioButtons(
              "region",
              "Region:",
              c(
                "Australia" = "Australia",
                "Australian Capital Territory" = "ACT",
                "New South Wales" = "NSW",
                "Northern Territory" = "NT",
                "Queensland" = "QLD",
                "South Australia" = "SA",
                "Tasmania" = "TAS",
                "Victoria" = "VIC",
                "Western Australia" = "WA"
              )
            )
          ),
        ))
      ),
      
      # tab 2 content
      tabItem(tabName = "2Map",
              leafletOutput("map", height = "89vh"))
      ,
      # tab 3 content
      tabItem(tabName = "3Criteria",
              )
      ,
      # tab 4 content
      tabItem(tabName = "4Leads",
              sidebarLayout(position = "right",
                            sidebarPanel(h3("Filters")),
                            mainPanel(
                              h3("Investment Leads"),
                              HTML("<br>"),
                              dataTableOutput("leadsdf_test")
                            ))
      )
      ,
      # tab 5 content
      tabItem(tabName = "5Calculator",
              sidebarLayout(position = "right",
                            sidebarPanel(h3("Output")),
                            mainPanel(
                              h3("Rental Property Investment"),
                              fluidRow(
                                HTML("<br>"),
                                column(
                                  width = 3,
                                  numericInput(
                                    "test1",
                                    "TestL",
                                    0,
                                    min = 0,
                                    step = 100,
                                    width = "70%"
                                  ),
                                  numericInput(
                                    "test4",
                                    "TestL",
                                    0,
                                    min = 0,
                                    step = 100,
                                    width = "70%"
                                  )
                                ),
                                column(
                                  width = 3,
                                  numericInput(
                                    "test2",
                                    "TestM",
                                    0,
                                    min = 0,
                                    step = 100,
                                    width = "70%"
                                  ),
                                  numericInput(
                                    "test5",
                                    "TestM",
                                    0,
                                    min = 0,
                                    step = 100,
                                    width = "70%"
                                  )
                                ),
                                column(
                                  width = 3,
                                  numericInput(
                                    "test3",
                                    "TestR",
                                    0,
                                    min = 0,
                                    step = 100,
                                    width = "70%"
                                  ),
                                  numericInput(
                                    "test6",
                                    "TestR",
                                    0,
                                    min = 0,
                                    step = 100,
                                    width = "70%"
                                  )
                                )
                              )
                            ),))
    ))
)

server <- function(input, output) {
  ###################
  # tab 1 - dashboard
  ###################
  output$listingNumberBox <- renderValueBox({
    valueBox(
      currency(
        dynamic_query(con, input$region)[[1]],
        big.mark = " ",
        digits = 0L,
        symbol = ""
      ),
      "Listings",
      icon = icon("home"),
      color = "blue"
    )
  })
  
  output$listingMedianPriceBox <- renderValueBox({
    valueBox(
      currency(
        dynamic_query(con, input$region)[[2]],
        digits = 0L,
        symbol = "",
      ),
      "Median price",
      icon = icon("dollar-sign"),
      color = "olive"
    )
  })

  output$listingMedianLandSizeBox <- renderValueBox({
    valueBox(
      paste0(
        currency(
          dynamic_query(con, input$region)[[3]],
          big.mark = " ",
          digits = 0L,
          symbol = ""
        ),
        " m²"
      ),
      "Median land size",
      icon = icon("resize-full", lib = "glyphicon"),
      color = "orange"
    )
  })
  
  output$PriceGraph <- renderPlot({
    ggplot(dynamic_query(con, input$region)[[4]],
           aes(x = listing_date,
               y = median_price,
               group = 1))  +
      geom_line() +
      geom_point() +
      xlab("Listing Date") + 
      ylab("Median Price") +
      ggthemes::theme_fivethirtyeight() +
      theme(axis.text.x = element_text(
        angle = -270,
        hjust = 0,
        vjust = -0.1
      ),
      axis.title = element_text())
  })
  
  #############
  # tab 2 - map
  #############
  dimProperty_coords <- read.csv(
    paste0(Sys.getenv("dw-rei"),
           "/data/geocoded_loc_ref.csv"
    )
  )
  
  # remove nulls if nulls in cache
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
  
  # AU coordinate boundaries
  # UB and LB = -10.360438 <-> -45.599262 
  # (latitude range)
  # LB and RB = 111.861226 <-> 155.542866 
  # (longitude range)
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
  
  listed_map <- st_as_sf(
    listed,
    coords = c("longitude", "latitude"),
    crs = 4326)
  
  output$map <- renderLeaflet({
    mapview(listed_map,
            legend = NULL,
            alpha.regions = 0.2)@map
  })
  
  ##################
  # tab 3 - criteria
  ##################
  
  
  ###############
  # tab 4 - leads
  ###############
  output$leadsdf_test <- renderDataTable(iris)
  
  ####################
  # tab 5 - calculator
  ####################
  
  
}




shinyApp(ui, server)
