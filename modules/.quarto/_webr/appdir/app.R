library(shiny)

data_points <- data.frame(x = c(1, 2, 3), y = c(1, 2, 3))

ui <- fluidPage(
  titlePanel("Interactive Cost Function Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      sliderInput("slope", 
                  "Slope Parameter:", 
                  min = -2, max = 4, value = 1, step = 0.1),
      br(),
      h4("Current Values:"),
      textOutput("current_slope"),
      textOutput("current_equation"),
      textOutput("current_ssr"),
      br(),
      p("Move the slider to see how the slope affects:"),
      tags$ul(
        tags$li("The regression line (left plot)"),
        tags$li("Your position on the cost function (right plot)")
      )
    ),
    
    mainPanel(
      plotOutput("combined_plot", height = "400px")
    )
  )
)

server <- function(input, output) {
  
  # Fixed: Calculate predictions and residuals properly
  current_calculations <- reactive({
    predictions <- input$slope * data_points$x
    residuals <- data_points$y - predictions
    ssr <- sum(residuals^2)
    list(predictions = predictions, residuals = residuals, ssr = ssr)
  })
  
  cost_data <- reactive({
    slopes <- seq(-2, 4, by = 0.1)
    ssr_values <- sapply(slopes, function(b) {
      preds <- b * data_points$x
      resids <- data_points$y - preds
      sum(resids^2)
    })
    list(slopes = slopes, ssr = ssr_values)
  })
  
  output$current_slope <- renderText({
    paste("Slope:", round(input$slope, 2))
  })
  
  output$current_equation <- renderText({
    paste0("Equation: Ŷ = 0 + ", round(input$slope, 2), " * X")
  })
  
  # Fixed: Use the corrected reactive calculations
  output$current_ssr <- renderText({
    calc <- current_calculations()
    ssr_terms <- paste0("(", data_points$y, " - ", round(calc$predictions, 2), ")^2", collapse = " + ")
    ssr_value <- round(calc$ssr, 2)
    paste0("SSR: ", ssr_terms, " = ", ssr_value)
  })
  
  output$combined_plot <- renderPlot({
    par(mfrow = c(1, 2), mar = c(4, 4, 2, 1))
    
    # Left: Regression plot
    plot(data_points$x, data_points$y, pch = 19, col = "blue",
         xlim = c(0, 4), ylim = c(-2, 6),
         xlab = "x", ylab = "y", main = "Regression Line")
    abline(0, input$slope, col = "red", lwd = 2)
    
    # Add residual lines for visualization
    calc <- current_calculations()
    segments(data_points$x, data_points$y, data_points$x, calc$predictions, 
             col = "gray", lty = 2)
    
    # Right: Cost function
    cost <- cost_data()
    plot(cost$slopes, cost$ssr, type = "l", col = "darkred", lwd = 2,
         xlab = "Slope Parameter", ylab = "Sum of Squared Residuals",
         main = "Cost Function")
    points(input$slope, calc$ssr, col = "red", pch = 19, cex = 1.5)
  })
}

shinyApp(ui = ui, server = server)
