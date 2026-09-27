library(shiny)
library(shinydashboard)
library(shinyjs)

ui <- dashboardPage(
  dashboardHeader(title = "RNA-seqWorkbench",
                  dropdownMenu(type = "messages",
                               tags$li(HTML('<li><a href="mailto:hitesh.kore22@gmail.com" target="_blank"><i class="fa fa-question"></i><h4>Support</h4><p>hitesh.kore22@gmail.com</p></a></li>'))
                  )),
  # tabs
  dashboardSidebar(
    sidebarMenu(menuItem("Welcome", tabName = "welcome", icon = icon("house")),
                menuItem("Differential expression", tabName = "de_analysis", icon = icon("dna")),
                menuItem("GSEA visualisations", tabName = "gsea_visualisations", icon = icon("chart-line"))
    )
  ),
  # body
  dashboardBody(
    useShinyjs(),  # shinyjs
    tags$head(
      tags$link(rel = "shortcut icon", href = "favicon.ico"),
      tags$link(rel = "apple-touch-icon", sizes = "180x180", href = "favicon.ico"),
      tags$link(rel = "icon", type = "image/png", sizes = "32x32", href = "/favicon-32x32.png"),
      tags$link(rel = "icon", type = "image/png", sizes = "16x16", href = "/favicon-16x16.png"),
      tags$style(HTML("
        .spinner {
          margin: 0 auto;
          width: 30px;
          height: 30px;
          border: 6px solid #ccc;
          border-top: 6px solid #333;
          border-radius: 50%;
          animation: spin 1s linear infinite;
        }
  
        @keyframes spin {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
  
        .loading-container {
          display: none;
          text-align: center;
          margin-top: 20px;
        }
        
        #downloadResults {
          background-color: #4CAF50; /* Green */
          border: none;
          color: white;
          padding: 15px 32px;
          text-align: center;
          text-decoration: none;
          display: inline-block;
          font-size: 12px;
        }
        
        #downloadResults:disabled {
          background-color: #d3d3d3; /* Gray */
          color: #a9a9a9; /* Dark gray */
        }
        
        .spacing {
          margin-top: 20px;
        }
      ")),
      tags$script(HTML("
        Shiny.addCustomMessageHandler('disableButton', function(params) {
          var button = document.getElementById(params.id);
          button.disabled = true;
          button.style.backgroundColor = 'grey';
          button.style.borderColor = 'grey';
          document.getElementById(params.spinnerId).style.display = 'block';
        });
  
        Shiny.addCustomMessageHandler('enableButton', function(params) {
          var button = document.getElementById(params.id);
          button.disabled = false;
          button.style.backgroundColor = '';
          button.style.borderColor = '';
          document.getElementById(params.spinnerId).style.display = 'none';
        });
      "))
    ),
    tabItems(
      tabItem(tabName = "welcome",
              fluidRow(
                column(12,
                       div(class = "box box-primary", style = "padding-right: 5%; padding-left: 5%; font-size:110%", 
                           div(class = "box-body", shiny::includeMarkdown("welcome-page-text.md")),
                           
                       )
                )
              )
      ),
      tabItem(tabName = "de_analysis", 
              h2("Differential expression of transcripts/genes based on RNA-Seq data"),
              fluidRow(
                column(6,
                       fileInput("de_excel", "Upload Excel file (count_data, sample_information, comparisons tabs):",
                                 NULL, buttonLabel = "Browse...", multiple = FALSE, accept = c(".xlsx", ".xls")),
                       
                       # Quick inline reminder + link to the full format guide
                       tags$div(style = "margin-bottom: 15px; font-size: 90%; color: #555;",
                                tags$p(
                                  "The workbook must contain exactly three sheets named ",
                                  tags$b("count_data"), ", ", tags$b("sample_information"), ", and ",
                                  tags$b("comparisons"), "."
                                ),
                                actionLink("show_format_help", label = tagList(icon("circle-info"), "View format guide"))
                       ),
                       
                       fileInput("GTF", "Upload GTF file:", NULL, buttonLabel = "Browse...", multiple = FALSE),
                       selectInput("detool", label = "Select differential expression package:", 
                                   choices = list("DeSeq2" = "DeSeq2","edgeR" = "edgeR"),selected = "DeSeq2"),
                       numericInput("group_size",label = "Smallest group size:", value = 4),
                       checkboxInput("batch_effect", label = "Batch effect",
                                     value = FALSE, width = NULL),
                       selectInput("DE_type", label = "Differential analysis type:", 
                                   choices = list("transcript" = "transcript","gene" = "gene"),selected = "gene"),
                       selectInput("annotations", label = "Annotations:", 
                                   choices = list("refseq" = "refseq","gencode" = "gencode"),selected = "gencode"),
                       
                       actionButton("de_submit_button", "Submit", class = "btn btn-primary")
                )
    )
  ),
  tabItem(tabName = "gsea_visualisations", 
          h2("Gene set enrichment analysis"),
          fluidRow(
            column(6,
                   fileInput("DE_GSEA_results","Upload DE and GSEA results Excel file:",NULL,buttonLabel = "Browse...",multiple = FALSE,accept = c(".xlsx")),
                   selectInput("gsea_method", label = "Differential expression method used:",
                               choices = list("DeSeq2" = "deseq", "edgeR" = "edger"), selected = "deseq"),
                   actionButton("gsea_submit_button", "Submit", class = "btn btn-primary")
                   
            )
          )
  )
  
  ) #tab items closes
  ), #dashboard body closes
    
  skin = "green"
)
