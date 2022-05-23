renv::activate()

library(shiny)
library(shinydashboard)
library(mapview)

ui <- dashboardPage(
  dashboardHeader(title = "test"),
  dashboardSidebar(),
  dashboardBody(
    leafletOutput("map")
  )
)

server <- function(input, output) {
  
  # plot 3
  ref_df <- read.csv(paste0(Sys.getenv("Backend_API_v2"), "/data/geocoded_loc_ref.csv"))
  
  # remove nulls (if blanks in cache)
  ref_df <- sqldf("
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
            ")
  # AU
  # UB and LB = -10.360438 <-> -45.599262 (latitude range)
  # LB and RB = 111.861226 <-> 155.542866 (longitude range)

  locations <- st_as_sf(ref_df,
                        coords=c("longitude", "latitude"),
                        crs=4326)

  
  output$map <- renderLeaflet({
    mapview(locations)@map
  })
}

shinyApp(ui, server)





# library(shinydashboard)
# library(sqldf)
# library(leaflet)
# 
# # setwd(Sys.getenv("Backend_API_v2"))
# 
# ui <- dashboardPage(
#         dashboardHeader(
#           title="REI Data Warehouse"
#         ),
#         dashboardSidebar(
#           sidebarMenu(
#             menuItem(
#               "Overview",
#               tabName="1Overview",
#               icon=icon("dashboard")
#             ),
#             menuItem(
#               "Detailed",
#               tabName="2Detailed",
#               icon=icon("th")
#             ),
#             menuItem(
#               "Map",
#               tabName="3Map",
#               icon=icon("map-pin")
#             )
#           )
#         ),
#         dashboardBody(
#           tabItems(
# 
#             # First tab content
#             tabItem(
#               tabName="1Overview",
#               fluidRow(
#                 box(
#                   plotOutput(
#                     "plot1",
#                     height=250
#                   )
#                 ),
#                 box(
#                   title="Controls",
#                   sliderInput(
#                     "slider",
#                     "Number of observations:",
#                     1,
#                     100,
#                     50
#                   )
#                 )
#               )
#             ),
# 
#             # second tab content
#             tabItem(
#               tabName="2Detailed",
#               h2("tab 2 content")
#             )
#             ,
# 
#             # third tab content
#             tabItem(
#               tabName="3Map",
#               h2("tab 3 content"),
#               fluidPage(
#                 mainPanel(
#                   leafletOutput("plot3")
#                 ))
#             )
#         )
#         )
#       )
# 
# server <- function(input, output){
# 
#             # plot 1
#             set.seed(122)
#             histdata <- rnorm(500)
#             output$plot1 <- renderPlot({
#               data <- histdata[seq_len(input$slider)]
#               hist(data)
#             })
# 
#             # plot 3
#             ref_df <- read.csv(paste0(Sys.getenv("Backend_API_v2"), "/data/geocoded_loc_ref.csv"))
# 
#             # remove nulls (if blanks in cache)
#             ref_df <- sqldf("
#                       SELECT
#                       *
#                       FROM
#                       ref_df
#                       WHERE
#                       (longitude IS NOT NULL OR latitude IS NOT NULL)
#                       AND
#                       (latitude < -10.360438)
#                       AND
#                       (latitude < -10.360438)
#                       AND
#                       (latitude > -45.599262)
#                       AND
#                       (longitude > 111.861226)
#                       AND
#                       (longitude < 155.542866)
#                       ;
#                       ")
#             # AU
#             # UB and LB = -10.360438 <-> -45.599262 (latitude range)
#             # LB and RB = 111.861226 <-> 155.542866 (longitude range)
# 
#             locations <- st_as_sf(ref_df,
#                                   coords=c("longitude", "latitude"),
#                                   crs=4326)
#             output$plot3 <- renderLeaflet({
#               mapview(breweries)@plot3
#                   })
# 
# 
#           }
# 
# shinyApp(ui, server)
# 
