setwd(Sys.getenv("dw-rei"))

renv::activate()

####LIBS####

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
library(shinyBS)
library(shinyscreenshot)

options(scipen = 999)

deliver_df <- function(){}

weekly_repayment <- function(PV, r, n) {
  # PV: loan amount (principal)
  # r: rate divided by 100 (decimal)
  # n: number of payment periods based on compound frequency and loan duration
  
  r <- r / 12 / 4
  
  numer <- PV * r
  denom1 <- 1 + r
  denom2 <- denom1 ^ (-n)
  denom <- 1 - denom2
  P <- numer / denom
  
  return(P)
}

dynamic_query <- function(con, state) {
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
      paste0(
        "SELECT ",
        "count(*) ",
        "FROM ",
        "public.\"factListings\" fl ",
        "LEFT OUTER JOIN ",
        "public.\"dimProperty\" dp ",
        "ON ",
        "fl.\"property_id\" = dp.\"property_id\" ",
        "WHERE ",
        "dp.\"state_id\" IN %s",
        ";"
      ),
      state_id
    ))[1, 1])
    ,
    toString(dbGetQuery(con, sprintf(
      paste0(
        "WITH ",
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
        ";"
      ),
      state_id
    ))[1, 1])
    ,
    toString(dbGetQuery(con, sprintf(
      paste0(
        "WITH ",
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
        ";"
      ),
      state_id
    ))[1, 1])
    ,
    dbGetQuery(con, sprintf(
      paste0(
        "WITH ",
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
        ";"
      ),
      state_id
    ))
  )
  
  return(query_results)
}

####GET DATA####

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

####UI####
ui <- dashboardPage(
  dashboardHeader(title = "AU Property App"),
  dashboardSidebar(
    sidebarMenu(
      menuItem(
        "Dashboard",
        tabName = "1Dashboard",
        icon = icon("dashboard", verify_fa = FALSE)
      ),
      menuItem("Map",
               tabName = "2Map",
               icon = icon("map-pin"))
      ,
      menuItem(
        "Criteria",
        tabName = "3Criteria",
        icon = icon("filter", lib = "glyphicon")
      )
      ,
      menuItem(
        "Leads",
        tabName = "4Leads",
        icon = icon("eye-open", lib = "glyphicon")
      )
      ,
      menuItem(
        "Calculator",
        tabName = "5Calculator",
        icon = icon("calculator")
      )
    )
  ),
  dashboardBody(
    shinyDashboardThemes(theme = "grey_light"),
    
    ####Inline CSS####
    # change heights to percentages?
    tags$head(tags$style(
      HTML(
        "#calcInputLoanLoanPercent {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#calcInputLoanDurationYrs {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#calcInputExpensesWeekWaterSewer {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 100%;
        }"
        ,
        "#calcInputExpensesWeekVacancy {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 100%;
        }"
        ,
        "#calcInputExpensesWeekTaxes {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 100%;
        }"
        ,
        "#calcInputExpensesWeekInsurance {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 100%;
        }"
        ,
        "#calcInputExpensesWeekElectricity {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 100%;
        }"
        ,
        "#calcInputExpensesWeekManagement {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 100%;
        }"
        ,
        "#calcInputExpensesWeekMaintainance {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 100%;
        }"
        ,
        "#calcInputExpensesWeekCapex {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 100%;
        }"
        ,
        "#calcInputIncomeWeekUnits {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#calcInputIncomeWeekUnitCostPW {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#calcInputGeneralDown {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#calcInputGeneralBuild {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#calcInputGeneralPurchase {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#calcInputGeneralClosing {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#calcInputGeneralBath {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#calcInputGeneralBed {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#calcInputGeneralAddress {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#calcOutputLoanTotalInvest {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#calcOutputGeneralTotal {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#calcOutputGeneralTotInvest {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#calcOutputGeneralBorrowed {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#IncomeWeekWeekTotal {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#IncomeWeekYearTotal {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#InputLoanTotalInvest {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#calcOutputLoanBorrowed {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#LoanWeeklyPayment {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 70%;
        }"
        ,
        "#calcRes1 {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 100%;
        }"
        ,
        "#calcRes2 {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 100%;
        }",
        "#calcRes3 {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 100%;
        }",
        "#calcRes4 {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 100%;
        }",
        "#calcRes5 {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 100%;
        }",
        "#calcRes6 {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 100%;
        }",
        "#calcRes7 {
       font-family: 'Source Sans Pro','Helvetica Neue',Helvetica,Arial,sans-serif;
       font-size: 15px;
       height: 43px;
       width: 100%;
        }"
      )
    )),
    
    tabItems(
      ####Tab 1 - Dashboard####
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
      
      ####Tab 2 - Map####
      tabItem(tabName = "2Map",
              leafletOutput("map", height = "89vh"))
      ,
      ####Tab 3 - Criteria####
      tabItem(
        tabName = "3Criteria",
        mainPanel(
          fluidRow(h2("View & Edit")),
          HTML("<br>"),
          
          tabsetPanel(
            type = "tabs",
            tabPanel("Acceptance Criteria",
                     HTML("<br>")),
            tabPanel("Expense Percentages",
                     HTML("<br>")),
            tabPanel("Loan Terms",
                     HTML("<br>")),
            tabPanel("Purchase Terms",
                     HTML("<br>"))
          ),
          actionButton("goUpdate",
                       "Update",
                       width = "20.7%")
          
          ,
        )
      )
      ,
      ####Tab 4 - Leads####
      tabItem(
        tabName = "4Leads",
        sidebarLayout(
          position = "right",
          sidebarPanel(
            h3("Options"),
            checkboxInput("enableML",
                          "Enable market value predictions",
                          FALSE,
                          width = "100%")
          ),
          mainPanel(
            h2("Investment Leads"),
            HTML("<br>"),
            ####
            dataTableOutput("leadsdf_test")
            ####
            
            ####
          )
        )
      )
      ,
      ####Tab 5 - Calculator####
      tabItem(
        tabName = "5Calculator",
        sidebarLayout(
          position = "right",
          sidebarPanel(
            h3("Results"),
            HTML("<br>"),
            HTML("
            <b>Weekly Income ($)</b>
            "),
            verbatimTextOutput("calcRes1"),
            
            HTML("
            <b>Weekly Expense ($)</b>
            "),
            verbatimTextOutput("calcRes2"),
            
            HTML("
            <b>Loan ($)</b>
            "),
            verbatimTextOutput("calcRes3"),
            
            HTML("
            <b>Weekly Cashflow ($)</b>
            "),
            verbatimTextOutput("calcRes4"),
            
            HTML("
            <b>Yearly Cashflow ($)</b>
            "),
            verbatimTextOutput("calcRes5"),
            
            HTML("
            <b>ROI (%)</b>
            "),
            verbatimTextOutput("calcRes6"),
            
            HTML("
            <b>Action</b>
            "),
            verbatimTextOutput("calcRes7"),
            
            ####Tooltips - Results####
            # ,
            # bsTooltip(
            #   id = "calcRes3",
            #   title = "Amount borrowed to fund deal",
            #   placement = "left",
            #   trigger = "hover"
            # )
            # ,
            # bsTooltip(
            #   id = "calcRes4",
            #   title = "Weekly net profit/loss",
            #   placement = "left",
            #   trigger = "hover"
            # )
            # ,
            # bsTooltip(
            #   id = "calcRes5",
            #   title = "Annual net profit/loss",
            #   placement = "left",
            #   trigger = "hover"
            # )
            # ,
            # bsTooltip(
            #   id = "calcRes6",
            #   title = "Return on investment",
            #   placement = "left",
            #   trigger = "hover"
            # )
            # ,
            # bsTooltip(
            #   id = "calcRes7",
            #   title = "Best course of action based on your criteria",
            #   placement = "left",
            #   trigger = "hover"
            # )
            
          ),
          mainPanel(
            h2("Deal Analysis"),
            HTML("<br>"),
            tabsetPanel(
              type = "tabs",
              ####General####
              tabPanel("General",
                       HTML("<br>"),
                       fluidRow(
                         column(
                           width = 3,
                           textInput("calcInputGeneralAddress",
                                     "Address"),
                           numericInput(
                             "calcInputGeneralBed",
                             "Bedrooms",
                             1,
                             min = 0.5,
                             step = 0.5
                           ),
                           numericInput(
                             "calcInputGeneralBath",
                             "Bathrooms",
                             1,
                             min = 0.5,
                             step = 0.5
                           ),
                           numericInput(
                             "calcInputGeneralBuild",
                             "Build. size (m²)",
                             0,
                             min = 0,
                             step = 1
                           )
                         ),
                         column(
                           width = 3,
                           numericInput(
                             "calcInputGeneralPurchase",
                             "Pch. price ($)",
                             0,
                             min = 0,
                             step = 1
                           ),
                           numericInput(
                             "calcInputGeneralClosing",
                             "Closing costs ($)",
                             0,
                             min = 0,
                             step = 1
                           ),
                           HTML("
                           <b>Total cost ($)</b>
                            ")
                           ,
                           verbatimTextOutput("calcOutputGeneralTotal")
                         ),
                         column(
                           width = 3,
                           numericInput(
                             "calcInputGeneralDown",
                             "Down pmt. ($)",
                             0,
                             min = 0.5,
                             step = 1
                           ),
                           HTML("
                           <b>Total invest. ($)</b>
                            ")
                           ,
                           verbatimTextOutput("calcOutputGeneralTotInvest")
                           ,
                           HTML("
                           <b>Amt borrowed ($)</b>
                            ")
                           ,
                           verbatimTextOutput("calcOutputGeneralBorrowed")
                         )
                       )
                       
                       ,
                       HTML("<br>")
                       ,
                       screenshotButton(
                         selector = "body",
                         filename = "AU_Property_App_DIY_calculator",
                         scale = 1
                       )
                       
              ),
              ####Income (weekly)####
              tabPanel("Income (weekly)",
                       HTML("<br>"),
                       fluidRow(
                         column(
                           width = 3,
                           numericInput(
                             "calcInputIncomeWeekUnits",
                             "Units",
                             1,
                             min = 1,
                             step = 0.5
                           ),
                           numericInput(
                             "calcInputIncomeWeekUnitCostPW",
                             "Unit cost p.w ($)",
                             0,
                             min = 0,
                             step = 1
                           ),
                           HTML("
                           <b>Weekly total ($)</b>
                            "),
                           verbatimTextOutput("IncomeWeekWeekTotal"),
                           HTML("
                           <b>Yearly total ($)</b>
                            "),
                           verbatimTextOutput("IncomeWeekYearTotal")
                         )
                       )
                       
                       ,
                       HTML("<br>")
                       ,
                       screenshotButton(
                         selector = "body",
                         filename = "AU_Property_App_DIY_calculator",
                         scale = 1
                       )
                       
              ),
              ####Expenses (weekly)####
              tabPanel("Expenses (weekly)",
                       HTML("<br>"),
                       fluidRow(
                         column(
                           width = 3,
                           numericInput(
                             "calcInputExpensesWeekWaterSewer",
                             "Water/sewer ($)",
                             0,
                             min = 0,
                             step = 1,
                             width = "70%"
                           ),
                           numericInput(
                             "calcInputExpensesWeekVacancy",
                             "Vacancy (%)",
                             0,
                             min = 0,
                             step = 1,
                             width = "70%"
                           ),
                           numericInput(
                             "calcInputExpensesWeekTaxes",
                             "Taxes ($)",
                             0,
                             min = 0,
                             step = 1,
                             width = "70%"
                           ),
                           numericInput(
                             "calcInputExpensesWeekInsurance",
                             "Insurance ($)",
                             0,
                             min = 0,
                             step = 1,
                             width = "70%"
                           )
                         ),
                         column(
                           width = 3,
                           numericInput(
                             "calcInputExpensesWeekElectricity",
                             "Electricity ($)",
                             0,
                             min = 0,
                             step = 1,
                             width = "70%"
                           ),
                           numericInput(
                             "calcInputExpensesWeekManagement",
                             "Management ($)",
                             0,
                             min = 0,
                             step = 1,
                             width = "70%"
                           ),
                           numericInput(
                             "calcInputExpensesWeekMaintainance",
                             "Maintainance ($)",
                             0,
                             min = 0,
                             step = 1,
                             width = "70%"
                           ),
                           numericInput(
                             "calcInputExpensesWeekCapex",
                             "Capex ($)",
                             0,
                             min = 0,
                             step = 1,
                             width = "70%"
                           )
                         )
                       )
                       ,
                       HTML("<br>")
                       ,
                       screenshotButton(
                         selector = "body",
                         filename = "AU_Property_App_DIY_calculator",
                         scale = 1
                       )
              ),
              ####Loan####
              tabPanel("Loan",
                       HTML("<br>"),
                       fluidRow(
                         column(
                           width = 3,
                           # <br style=\"line-height: 0.5px;\">
                           HTML("
                           <b>Total invest. ($)</b>
                            ")
                           ,
                           # same as general tot invest
                           verbatimTextOutput("calcOutputLoanTotalInvest")
                           ,
                           HTML("
                           <b>Loan amt ($)</b>
                            "),
                           verbatimTextOutput("calcOutputLoanBorrowed")
                           ,
                           numericInput(
                             "calcInputLoanLoanPercent",
                             "Loan (%)",
                             0,
                             min = 1,
                             step = 0
                           ),
                           numericInput(
                             "calcInputLoanDurationYrs",
                             "Duration (years)",
                             0,
                             min = 0,
                             step = 1
                           ),
                           HTML("
                           <b>Weekly pay. ($)</b>
                            "),
                           verbatimTextOutput("LoanWeeklyPayment")
                         )
                       )
                       #####Screenshot - Calc tab Loan####
                       ,
                       HTML("<br>")
                       ,
                       screenshotButton(
                         selector = "body",
                         filename = "AU_Property_App_DIY_calculator",
                         scale = 1
                       )
              )
              # actionButton("btn", "myBtn")
              
              
            )
            ####Tooltips - General####
            ,
            bsTooltip(
              id = "calcInputGeneralAddress",
              title = "Address (not used in calculation)",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcInputGeneralBed",
              title = "Number of bedrooms for property",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcInputGeneralBath",
              title = "Number of bathrooms for property",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcInputGeneralBuild",
              title = "Property building size",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcInputGeneralPurchase",
              title = "Property purchase price",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcInputGeneralClosing",
              title = "Fees paid at of the transaction",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcOutputGeneralTotal",
              title = "Sum of purchase price and closing costs (read-only)",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcInputGeneralDown",
              title = "Amount paid upfront in the transaction",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcOutputGeneralTotInvest",
              title = "Upfront Amount put into deal (read-only)",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcOutputGeneralBorrowed",
              title = "Difference between total cost and total investment (read-only)",
              placement = "right",
              trigger = "hover"
            )
            
            ####Tooltips - Income (weekly)####
            ,
            bsTooltip(
              id = "calcInputIncomeWeekUnits",
              title = "Number of income-generating units",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcInputIncomeWeekUnitCostPW",
              title = "Weekly income per unit",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcInputExpensesWeekVacancy",
              title = "% of income to reserve for vacant property periods",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcInputExpensesWeekTaxes",
              title = "Property tax expense",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcInputExpensesWeekInsurance",
              title = "Property insurance cost",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcInputExpensesWeekManagement",
              title = "Property manager fees if applicable",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcInputExpensesWeekMaintainance",
              title = "Cost to maintain property",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcInputExpensesWeekCapex",
              title = "Amount set aside to acquire or upgrade non-consumable assets",
              placement = "right",
              trigger = "hover"
            )
            
            ####Tooltips - Loan####
            # Loan
            ,
            bsTooltip(
              id = "calcInputLoanTotalInvest",
              title = "Upfront Amount put into deal (read-only) (duplicate)",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcInputLoanLoanAmount",
              title = "Difference between total cost and total investment (read-only) (duplicate)",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcInputLoanLoanPercent",
              title = "Loan interest percentage",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcInputLoanDurationYrs",
              title = "Length of loan term",
              placement = "right",
              trigger = "hover"
            )
            ,
            bsTooltip(
              id = "calcInputLoanWeeklyPayment",
              title = "Weekly payment towards loan",
              placement = "right",
              trigger = "hover"
            )
            
          ),
          
        )
      )
    )
  )
)

####SERVER####
server <- function(input, output, session) {
  ####Tab 1 - Dashboard####
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
    ggplot(
      dynamic_query(con, input$region)[[4]],
      aes(x = listing_date,
          y = median_price,
          group = 1)
    )  +
      geom_line() +
      geom_point() +
      xlab("Listing Date") +
      ylab("Median Price") +
      ggthemes::theme_fivethirtyeight() +
      theme(
        axis.text.x = element_text(
          angle = -270,
          hjust = 0,
          vjust = -0.1
        ),
        axis.title = element_text()
      )
  })
  
  ####Tab 2 - Map####
  dimProperty_coords <- read.csv(paste0(Sys.getenv("dw-rei"),
                                        "/data/geocoded_loc_ref.csv"))
  
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
  
  listed_map <- st_as_sf(listed,
                         coords = c("longitude", "latitude"),
                         crs = 4326)
  
  output$map <- renderLeaflet({
    mapview(listed_map,
            legend = NULL,
            alpha.regions = 0.2)@map
  })
  
  ####Tab 3 - Criteria####
  
  
  ####Tab 4 - Leads####
  output$leadsdf_test <- renderDataTable(iris)
  
  ####Tab 5 - Calculator####
  
  # General
  InputGeneralPurchase <- reactive(input$calcInputGeneralPurchase)
  InputGeneralClosing <- reactive(input$calcInputGeneralClosing)
  output$calcOutputGeneralTotal <- renderText(InputGeneralPurchase() + InputGeneralClosing())
  InputGeneralDown <- reactive(input$calcInputGeneralDown)
  output$calcOutputGeneralTotInvest <-
    renderText(InputGeneralDown())
  output$calcOutputGeneralBorrowed <- renderText((InputGeneralPurchase() + InputGeneralClosing()) - InputGeneralDown())
  
  # Income
  InputIncomeWeekUnits <- reactive(input$calcInputIncomeWeekUnits)
  InputIncomeWeekUnitCostPW <-
    reactive(input$calcInputIncomeWeekUnitCostPW)
  output$IncomeWeekWeekTotal <- renderText(InputIncomeWeekUnits() * InputIncomeWeekUnitCostPW())
  
  output$IncomeWeekYearTotal <- renderText(InputIncomeWeekUnits() * InputIncomeWeekUnitCostPW() * 52)
  
  # Expenses
  # N/A
  # capture reactive expenses
  InputExpensesWaterSewer <-
    reactive(input$calcInputExpensesWeekWaterSewer)
  InputExpensesVacancy <-
    reactive(input$calcInputExpensesWeekVacancy)
  InputExpensesTaxes <- reactive(input$calcInputExpensesWeekTaxes)
  InputExpensesInsurance <-
    reactive(input$calcInputExpensesWeekInsurance)
  InputExpensesElectricity <-
    reactive(input$calcInputExpensesWeekElectricity)
  InputExpensesManagement <-
    reactive(input$calcInputExpensesWeekManagement)
  InputExpensesMaintainance <-
    reactive(input$calcInputExpensesWeekMaintainance)
  InputExpensesCapex <- reactive(input$calcInputExpensesWeekCapex)
  
  # Loan
  output$calcOutputLoanTotalInvest <- renderText(InputGeneralDown())
  
  output$calcOutputLoanBorrowed <- renderText((InputGeneralPurchase() + InputGeneralClosing()) - InputGeneralDown())
  
  # capture loan per and dur
  InputLoanPercent <- reactive(input$calcInputLoanLoanPercent)
  InputLoanDurationYrs <-
    reactive(input$calcInputLoanLoanDurationYrs)
  
  output$LoanWeeklyPayment <- renderText(
    weekly_repayment(
      ((InputGeneralPurchase() + InputGeneralClosing()) - InputGeneralDown()
      ),
      input$calcInputLoanLoanPercent / 100,
      input$calcInputLoanDurationYrs * 12 * 4
    )
  )
  
  # Results
  output$calcRes1 <- renderText(
    InputIncomeWeekUnits() * InputIncomeWeekUnitCostPW()
  )
  
  output$calcRes2 <- renderText(
    InputExpensesWaterSewer()
    + InputExpensesVacancy()
    + InputExpensesTaxes()
    + InputExpensesInsurance()
    + InputExpensesElectricity()
    + InputExpensesManagement()
    + InputExpensesMaintainance()
    + InputExpensesCapex()
  )
  
  output$calcRes3 <- renderText((InputGeneralPurchase() + InputGeneralClosing()) - InputGeneralDown())
  
  # = weekly inc - " exp - " loan payment (formula for loan weekly payment)
  output$calcRes4 <- renderText(
    # weekly income
    (InputIncomeWeekUnits() * InputIncomeWeekUnitCostPW()) 
    # weekly expenses
    - (
      InputExpensesWaterSewer()
      + InputExpensesVacancy()
      + InputExpensesTaxes()
      + InputExpensesInsurance()
      + InputExpensesElectricity()
      + InputExpensesManagement()
      + InputExpensesMaintainance()
      + InputExpensesCapex()
    )
    # minus weekly loan payment
    - (
      weekly_repayment(
        (
          (InputGeneralPurchase() + InputGeneralClosing()) - InputGeneralDown()
        ),
        input$calcInputLoanLoanPercent / 100,
        input$calcInputLoanDurationYrs * 12 * 4
      )
    )
  )
  
  # = yearly inc - " exp - " loan payment(formula for loan weekly payment)
  output$calcRes5 <- renderText(
    ((InputIncomeWeekUnits() * InputIncomeWeekUnitCostPW()) - (
      InputExpensesWaterSewer()
      + InputExpensesVacancy()
      + InputExpensesTaxes()
      + InputExpensesInsurance()
      + InputExpensesElectricity()
      + InputExpensesManagement()
      + InputExpensesMaintainance()
      + InputExpensesCapex()
    )
    - (
      weekly_repayment(
        ((InputGeneralPurchase() + InputGeneralClosing()) - InputGeneralDown()
        ),
        input$calcInputLoanLoanPercent / 100,
        input$calcInputLoanDurationYrs * 12 * 4
      )
    )
    ) * 12
  )
  
  # ROI = yearly cashflow / total investment
  output$calcRes6 <- renderText(((
    (InputIncomeWeekUnits() * InputIncomeWeekUnitCostPW()) - (
      InputExpensesWaterSewer()
      + InputExpensesVacancy()
      + InputExpensesTaxes()
      + InputExpensesInsurance()
      + InputExpensesElectricity()
      + InputExpensesManagement()
      + InputExpensesMaintainance()
      + InputExpensesCapex()
    )
    - (
      weekly_repayment(
        ((InputGeneralPurchase() + InputGeneralClosing()) - InputGeneralDown()
        ),
        input$calcInputLoanLoanPercent / 100,
        input$calcInputLoanDurationYrs * 12 * 4
      )
    )
  ) * 12)
  
  / InputGeneralDown() * 100)
  
  # Action: if ROI > min ROI then BUY ELSE PASS
  output$calcRes7 <- renderText(ifelse(
    
    ((
      (InputIncomeWeekUnits() * InputIncomeWeekUnitCostPW()) - (
        InputExpensesWaterSewer()
        + InputExpensesVacancy()
        + InputExpensesTaxes()
        + InputExpensesInsurance()
        + InputExpensesElectricity()
        + InputExpensesManagement()
        + InputExpensesMaintainance()
        + InputExpensesCapex()
      )
      - (
        weekly_repayment(
          ((InputGeneralPurchase() + InputGeneralClosing()) - InputGeneralDown()
          ),
          input$calcInputLoanLoanPercent / 100,
          input$calcInputLoanDurationYrs * 12 * 4
        )
      )
    ) * 12)
    
    / InputGeneralDown() * 100
    
    > 25
    ,
    "BUY"
    ,
    "PASS"
  )
  )
}

shinyApp(ui, server)
