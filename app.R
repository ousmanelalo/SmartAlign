# app.R

# Charger les bibliothèques nécessaires
# Si vous n'avez pas ces bibliothèques, installez-les avec install.packages(c("shiny", "geosphere", "leaflet", "shinydashboard"))
library(shiny)
library(geosphere) # Pour les calculs géodésiques (distance et azimut)
library(leaflet)   # Pour les cartes interactives
library(shinydashboard) # Pour l'interface de tableau de bord

# Définition de l'interface utilisateur (UI)
ui <- dashboardPage(
  # En-tête du tableau de bord
  dashboardHeader(title = "SmartAlign"),
  
  # Barre latérale du tableau de bord
  dashboardSidebar(
    # Ajout de balises HTML pour inclure du CSS personnalisé (adapté pour shinydashboard)
    tags$head(
      tags$style(HTML("
        /* Make html and body take full height and hide overall overflow */
        html, body {
          height: 100%;
          overflow: hidden; /* Hide overall scrollbar for the entire page */
          font-family: 'Tahoma', sans-serif; /* Utilisation d'une police moderne */
          color: #333;
        }

        /* Adjust shinydashboard's main content wrapper to take full height */
        .content-wrapper, .right-side {
          min-height: 100%;
          height: calc(100vh - 50px); /* Subtract header height (default 50px) */
          overflow-y: auto; /* Allow scrolling within the main content area if content overflows */
          padding-bottom: 0; /* Remove default padding that might cause scroll */
        }

        /* Allow sidebar to scroll if its content overflows */
        .main-sidebar .sidebar {
          height: calc(100vh - 50px); /* Subtract header height */
          overflow-y: auto; /* Enable vertical scrolling */
          padding-bottom: 0px; /* Add some padding at the bottom for the button */
        }

        /* Ensure tab content and tab pane fill available height */
        .tab-content, .tab-pane {
          height: 100%;
          display: flex; /* Use flexbox for vertical distribution */
          flex-direction: column;
        }

        /* Make fluidRow take available height and use flexbox for horizontal distribution */
        .fluidRow {
          flex-grow: 1; /* Allow fluidRow to grow vertically */
          display: flex;
          flex-wrap: wrap; /* Allow wrapping on smaller screens */
          margin-left: -15px; /* Adjust for shinydashboard's row padding */
          margin-right: -15px;
        }

        /* Panneaux (sidebar and main content boxes) */
        .box {
          border-radius: 0px; /* Coins arrondis pour les boîtes shinydashboard */
          box-shadow: 0 4px 15px rgba(0, 0, 0, 0.08); /* Ombre subtile */
          border-top: 3px solid #3c8dbc; /* Couleur de bordure par default de shinydashboard */
          display: flex; /* Make boxes flex containers */
          flex-direction: column;
          height: 100%; /* Boxes should fill their column height */
          margin-bottom: 0; /* Remove margin that might cause scroll */
        }

        .box-body {
          flex-grow: 1; /* Box body should grow to fill space */
          display: flex;
          flex-direction: column;
          padding: 5px; /* Restore some padding inside the box body */
          overflow: hidden; /* Hide overflow for box body content */
        }

        /* Entrées numériques */
        .form-group.shiny-input-container label {
          font-weight: 400;
          color: #FFF;
          margin-bottom: 0px;
        }
        .form-control {
          border-radius: 0px; /* Coins arrondis pour les champs de saisie */
          border: 1px solid #ccc;
          padding: 10px 15px;
          box-shadow: inset 0 1px 3px rgba(0,0,0,0.06);
        }

        /* Bouton de calcul */
        .btn-default {
          background-color: #3c8dbc; 
          color: white;
          border: none;
          border-radius: 0px;
          padding: 10px 15px;
          font-size: 1.1em;
          cursor: pointer;
          transition: background-color 0.3s ease, transform 0.2s ease;
          box-shadow: 0 4px 10px rgba(76, 175, 80, 0.3);
        }
        .btn-default:hover {
          background-color: #45a049; /* Assombrir au survol */
          transform: translateY(-2px); /* Léger effet de soulèvement */
        }
        .btn-default:active {
          background-color: #3e8e41;
          transform: translateY(0);
          box-shadow: inset 0 2px 5px rgba(0, 0, 0, 0.2);
        }

        /* En-têtes h3 */
        h3 {
          color: #fff;
          border-bottom: 2px solid #e0e0e0;
          padding-bottom: 10px;
          padding-left: 10px;
          margin-top: 10;
          margin-bottom: 5px;
          font-size: 25px;
        }
        /* En-têtes h3 */
        h4 {
          color: red;
          border-bottom: 2px solid #e0e0e0;
          padding-bottom: 10px;
          padding-left: 15px;
          margin-top: 10;
          margin-bottom: 5px;
          font-size: 20px;
        }
        /* Sortie de texte (résultats) */
        pre.shiny-text-output {
          background-color: #ecf0f1;
          border: 1px solid #dcdcdc;
          border-radius: 0px;
          padding: 15px;
          white-space: pre-wrap; /* Pour que le texte s'enroule */
          word-wrap: break-word; /* Pour les longs mots */
          font-size: 1.05em;
          line-height: 1.6;
          color: #2c3e50;
          flex-grow: 1; /* Allow results to grow */
          overflow-y: auto; /* Allow scroll within results if content is too long */
          margin-bottom: 0; /* Remove bottom margin */
        }

        /* Carte Leaflet */
        #mapPlot {
          border-radius: 0px;
          box-shadow: 0 4px 15px rgba(0, 0, 0, 0.08);
          height: 100%; 
         
        }
      "))
    ),
    # Menu de la barre latérale (peut être utilisé pour la navigation si l'app grandit)
    sidebarMenu(
      menuItem("Parametres", tabName = "settings", icon = icon("gears")),
      # Inputs pour le Point A
      h4("Site A"),
      numericInput("lonA", "Longitude (degrés)", value = 2.12, min = -180, max = 180, step = 0.000001),
      numericInput("latA", "Latitude (degrés)", value = 13.51, min = -90, max = 90, step = 0.000001),
      numericInput("altA", "Altitude (metres)", value = 200, min = 0),
      
      # Inputs pour le Point B
      h4("Site B"),
      numericInput("lonB", "Longitude (degrés)", value = 2.15, min = -180, max = 180, step = 0.000001),
      numericInput("latB", "Latitude (degrés)", value = 13.52, min = -90, max = 90, step = 0.000001),
      numericInput("altB", "Altitude (metres)", value = 250, min = 0),
      
      # Bouton de calcul
      actionButton("calculate", "Calculer")
    )
  ),
  
  # Corps du tableau de bord
  dashboardBody(
    tabItems(
      tabItem(tabName = "settings",
              fluidRow(
                # Boîte pour les résultats textuels
                box(
                  title = "Résultats des calculs", status = "primary", solidHeader = TRUE, width = 5,
                  verbatimTextOutput("results")
                ),
                # Boîte pour la carte
                box(
                  title = "Carte des points", status = "primary", solidHeader = TRUE, width = 7,
                  leafletOutput("mapPlot")
                )
              )
      )
    )
  )
)

# Définition de la logique du serveur
server <- function(input, output) {
  
  # Créer un reactiveValues pour stocker les résultats et l'état de la carte
  rv <- reactiveValues(
    results_text = "Cliquez sur 'Calculer' pour voir les resultats.",
    map_data = NULL # Sera initialisé avec une carte par défaut
  )
  
  # Initialisation de la carte par défaut (centrée sur Niamey, Niger)
  output$mapPlot <- renderLeaflet({
    leaflet() %>%
      addTiles() %>%
      setView(lng = 2.10, lat = 13.51, zoom = 12) %>% # Centré sur Niamey
      addPopups(2.10, 13.51, "Niamey, Niger")
  })
  
  # Observer le bouton de calcul
  observeEvent(input$calculate, {
    # Récupérer les valeurs d'entrée
    lonA <- input$lonA
    latA <- input$latA
    altA <- input$altA
    
    lonB <- input$lonB
    latB <- input$latB
    altB <- input$altB
    
    # Créer les vecteurs de coordonnées
    point_A <- c(lonA, latA)
    point_B <- c(lonB, latB)
    
    # --- Calcul de l'azimut (bearing) ---
    azimuth_AB <- bearing(point_A, point_B)
    azimuth_BA <- bearing(point_B, point_A)
    
    # --- Calcul de la distance géodésique ---
    distance_m <- distm(point_A, point_B, fun = distHaversine)
    
    # --- Calcul de l'inclinaison (tilt) ---
    delta_alt <- altB - altA
    tilt_A_rad <- atan2(delta_alt, distance_m)
    tilt_A_deg <- tilt_A_rad * 180 / pi
    tilt_B_rad <- atan2(-delta_alt, distance_m)
    tilt_B_deg <- tilt_B_rad * 180 / pi
    
    # Mettre à jour le texte des résultats
    rv$results_text <- paste(
      "------------------\n",
      sprintf("Coordonnees Point A: Longitude %.6f, Latitude %.6f, Altitude %.2f m\n", lonA, latA, altA),
      sprintf("Coordonnees Point B: Longitude %.6f, Latitude %.6f, Altitude %.2f m\n", lonB, latB, altB),
      "\n",
      sprintf("Distance entre les points: %.2f metres\n", distance_m),
      "\n",
      sprintf("Azimut de l'antenne A (vers B): %.2f degres\n", azimuth_AB),
      sprintf("Inclinaison (Tilt) de l'antenne A: %.2f degres\n", tilt_A_deg),
      "\n",
      sprintf("Azimut de l'antenne B (vers A): %.2f degres\n", azimuth_BA),
      sprintf("Inclinaison (Tilt) de l'antenne B: %.2f degres\n", tilt_B_deg),
      sep = ""
    )
    
    # Mettre à jour les données de la carte
    rv$map_data <- list(
      lonA = lonA, latA = latA, altA = altA,
      lonB = lonB, latB = latB, altB = altB,
      distance_m = distance_m
    )
  })
  
  # Afficher les résultats textuels (réactif aux changements de rv$results_text)
  output$results <- renderPrint({
    cat(rv$results_text)
  })
  
  # Mettre à jour la carte lorsque rv$map_data change (après un clic sur Calculer)
  observeEvent(rv$map_data, {
    req(rv$map_data) # S'assurer que map_data n'est pas NULL
    map_info <- rv$map_data
    
    leafletProxy("mapPlot") %>% # Utiliser leafletProxy pour mettre à jour la carte existante
      clearMarkers() %>%
      clearShapes() %>%
      addMarkers(
        lng = map_info$lonA, lat = map_info$latA,
        popup = paste("<b>Point A</b><br>",
                      "Lon:", map_info$lonA, "<br>",
                      "Lat:", map_info$latA, "<br>",
                      "Alt:", map_info$altA, "m")
      ) %>%
      addMarkers(
        lng = map_info$lonB, lat = map_info$latB,
        popup = paste("<b>Point B</b><br>",
                      "Lon:", map_info$lonB, "<br>",
                      "Lat:", map_info$latB, "<br>",
                      "Alt:", map_info$altB, "m")
      ) %>%
      addPolylines(
        lng = c(map_info$lonA, map_info$lonB),
        lat = c(map_info$latA, map_info$latB),
        color = "blue",
        weight = 3,
        opacity = 1,
        dashArray = "8, 8",
        popup = paste("Distance:", round(map_info$distance_m, 2), "m")
      ) %>%
      fitBounds(
        min(map_info$lonA, map_info$lonB), min(map_info$latA, map_info$latB),
        max(map_info$lonA, map_info$lonB), max(map_info$latA, map_info$latB)
      )
  })
}

# Exécuter l'application Shiny
shinyApp(ui = ui, server = server)
