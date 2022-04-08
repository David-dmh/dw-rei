library(shinydashboard)

ui <- dashboardPage(
        dashboardHeader(
          title="R.E.I. DW Dashboard"
        ), 
        dashboardSidebar(
          sidebarMenu(
            menuItem(
              "Overview",
              tabName="1Overview",
              icon=icon("dashboard")
            ),
            menuItem(
              "Detailed", 
              tabName="2Detailed", 
              icon=icon("th")
            ),
            menuItem(
              "Map", 
              tabName="3Map", 
              icon=icon("map-pin")
            )
          )
        ),
        dashboardBody(
          tabItems(
            # First tab content
            tabItem(
              tabName="1Overview",
              fluidRow(
                box(
                  plotOutput(
                    "plot1", 
                    height=250
                  )
                ),
                box(
                  title="Controls",
                  sliderInput(
                    "slider", 
                    "Number of observations:", 
                    1, 
                    100, 
                    50
                  )
                )
              )
            ),
            # second tab content
            tabItem(
              tabName="2Detailed",
              h2("tab 2 content")
            )
            ,
            # third tab content
            tabItem(
              tabName="3Map",
              h2("tab 3 content")
            )
        )
        )
      )

server <- function(input, output){
            set.seed(122)
            histdata <- rnorm(500)
            output$plot1 <- renderPlot({
              data <- histdata[seq_len(input$slider)]
              hist(data)
            })
          }

shinyApp(ui, server)
