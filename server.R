
library(shiny)
library(shinyjs)
#2000mb upload size
options(shiny.maxRequestSize = 2000*1024^2)

# internal server functions
server_differential_expr <- function(input, output, session) {
  
  req(input$de_excel$datapath, input$GTF$datapath)  # required
  
  # store session ID
  session_id <- session$token
  
  outdir_de <- paste0(session_id, "/de_results")
  dir.create(outdir_de, recursive = TRUE, showWarnings = FALSE)
  
  # ---- Collect all options from the UI (even ones not yet wired into the
  # analysis logic itself — DE_type, annotations, batch_effect — are still
  # gathered and passed through as params so the Rmd/pipeline can pick them
  # up later without another round of server.R changes) ----
  data_file    <- input$de_excel$datapath
  gtf_file     <- input$GTF$datapath
  method       <- input$detool
  group_size   <- input$group_size
  batch_effect <- input$batch_effect      # not yet functional downstream
  DE_type      <- input$DE_type           # not yet functional downstream
  annotations  <- input$annotations       # not yet functional downstream
  
  # Original hardcoded working directory — kept for reference, commented out.
  # setwd("/Users/hiteshkore/Library/CloudStorage/OneDrive-TheUniversityofMelbourne/Hitesh_parker_lab/github/downstream_transcriptome_analysis/Differential_expression")
  
  working_dir <- getwd()
  rmd_path    <- file.path(working_dir, "bin", "DE_analysis.Rmd")
  outdir_full <- file.path(working_dir, outdir_de)
  output_file <- file.path(outdir_full, "summary_report.html")
  
  print(rmd_path)
  print(outdir_full)
  print(output_file)
  print(gtf_file)
  print(method)
  print(group_size)
  print(batch_effect)
  print(DE_type)
  print(annotations)
  print(data_file)
  
  # ---- Build the params list that will be passed into DE_analysis.Rmd ----
  render_params <- list(
    directory    = outdir_full,
    data_file    = data_file,
    gtf_file     = gtf_file,
    method       = method,
    group_size   = group_size,
    batch_effect = batch_effect,
    DE_type      = DE_type,
    annotations  = annotations
  )
  
  # ---- Build the R expression that will be run in a separate Rscript
  # process. deparse() is used (not shQuote) because this text needs to be
  # valid R source code, not a shell-quoted string — each path/value is
  # turned into a properly escaped R literal so paths containing spaces
  # (very likely, given these OneDrive paths) or special characters are
  # never misinterpreted. ----
  render_expr <- sprintf(
    "rmarkdown::render(input=%s, output_file=%s, output_format='html_document', params=list(directory=%s, data_file=%s, gtf_file=%s, method=%s, group_size=%s, batch_effect=%s, DE_type=%s, annotations=%s))",
    deparse(rmd_path),
    deparse(output_file),
    deparse(render_params$directory),
    deparse(render_params$data_file),
    deparse(render_params$gtf_file),
    deparse(render_params$method),
    deparse(render_params$group_size),
    deparse(render_params$batch_effect),
    deparse(render_params$DE_type),
    deparse(render_params$annotations)
  )
  
  # ---- Assemble the full command as a single string, purely for logging/
  # inspection — this is what conceptually "runs", even though execution
  # below uses an argument vector (safer than a shell string) ----
  full_command <- paste("Rscript -e", shQuote(render_expr))
  message("Prepared command:\n", full_command)
  
  # ---- Execute the command in a separate R process ----
  # Using system2() with args as a vector (not a single shell string) avoids
  # any shell re-quoting/escaping issues with the paths and expression above.
  
  result <- system2(
    command = "Rscript",
    args    = c("-e", shQuote(render_expr)),
    stdout  = TRUE,
    stderr  = TRUE
  )
  exit_status <- attr(result, "status")
  if (!is.null(exit_status) && exit_status != 0) {
    warning("DE_analysis.Rmd render failed (exit status ", exit_status, "):\n",
            paste(result, collapse = "\n"))
  } else {
    message("DE_analysis.Rmd render completed.\n", paste(result, collapse = "\n"))
  }
  
  invisible(list(command = full_command, log = result, status = exit_status))
}
#gsea analysis server
server_gsea_analysis<-function(input, output, session){
  req("DE_GSEA_results")
  
  # store session ID
  session_id <- session$token
  outdir_gsea <- paste0(session_id, "/gsea_results_visualisations")
  dir.create(outdir_gsea, recursive = TRUE, showWarnings = FALSE)
  
  # ---- Collect all options from the UI ----
  de_res_fn <- input$DE_GSEA_results$datapath
  method    <- input$gsea_method

  working_dir <- getwd()
  rmd_path    <- file.path(working_dir, "bin", "DE_GSEA_plotting.Rmd")
  outdir_full <- file.path(working_dir, outdir_gsea)
  output_file <- file.path(outdir_full, "DE_GSEA_plotting_report.html")
  
  print(rmd_path)
  print(outdir_full)
  print(output_file)
  print(de_res_fn)
  print(method)

  # ---- Build the params list that will be passed into DE_GSEA_plotting.Rmd ----
  render_params <- list(
    de_res_fn = de_res_fn,
    method    = method,
    outdir    = outdir_full
  )
  
  # ---- Build the R expression that will be run in a separate Rscript
  # process. deparse() is used (not shQuote) for the same reason as in
  # server_differential_expr(): this text needs to be valid R source code,
  # and paths (e.g. these OneDrive paths) may contain spaces or special
  # characters that must be correctly escaped as R literals. ----
  render_expr <- sprintf(
    "rmarkdown::render(input=%s, output_file=%s, output_format='html_document', params=list(de_res_fn=%s, method=%s, outdir=%s), quiet=TRUE)",
    deparse(rmd_path),
    deparse(output_file),
    deparse(render_params$de_res_fn),
    deparse(render_params$method),
    deparse(render_params$outdir)
  )
  
  # ---- Assemble the full command as a single string, purely for logging/
  # inspection — this is what conceptually "runs", even though execution
  # below uses an argument vector (safer than a shell string) ----
  full_command <- paste("Rscript -e", shQuote(render_expr))
  message("Prepared command:\n", full_command)
  
  # ---- Execute the command in a separate R process ----
  result <- system2(
    command = "Rscript",
    args    = c("-e", shQuote(render_expr)),
    stdout  = TRUE,
    stderr  = TRUE
  )
  
  exit_status <- attr(result, "status")
  if (!is.null(exit_status) && exit_status != 0) {
    warning("DE_GSEA_plotting.Rmd render failed (exit status ", exit_status, "):\n",
            paste(result, collapse = "\n"))
  } else {
    message("DE_GSEA_plotting.Rmd render completed.\n", paste(result, collapse = "\n"))
  }
  
  invisible(list(command = full_command, log = result, status = exit_status))
  
}



# shiny app server
server <- function(input, output, session) {
  
  # store session ID
  # create session id tmp directory each time app is run
  session_id <- session$token
  print(paste0("Session: ", session_id))
  system(paste0("mkdir ", session_id))
  
  # DATABASE MODULE
  
  # create reactive value for the database zip
  file_available_db <- reactiveVal(FALSE)
  
  # run database function when submit is pressed
  observeEvent(input$de_submit_button, {
    
    
    # run different servers depending on input type selected
    
    server_differential_expr(input, output, session)
    
    
  })
    
  # run integration function when submit is pressed
  observeEvent(input$gsea_submit_button, { 
    # run integration server
    server_gsea_analysis(input, output, session)
      
    
  })
  
  
  
  
}
