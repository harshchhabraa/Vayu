# VAYU — Breathe Intelligence

VAYU is a premium air quality and respiratory wellness dashboard. This application is a fully client-side web application designed to track localized air quality, recommend clean transit routes, and simulate protective personal strategies.

## Project Structure

The project has been cleaned up to keep only the frontend:

```text
Vayu/
├── frontend/
│   ├── assets/            # Static media, icons, and image assets
│   ├── css/
│   │   └── style.css      # Core styles & layout rules
│   ├── js/
│   │   └── app.js         # Client-side controllers, simulations, & routing engine
│   ├── index.html         # Main dashboard HTML structure
│   └── package.json       # Startup scripts for local serving
└── README.md              # Project documentation
```

## Features

- **Real-Time Dashboards:** Visual representation of air quality indexes (AQI), PM2.5, PM10, and safety categories.
- **Route Optimization Engine:** Selects routes optimized for Speed, Balance, or Health based on distance, travel time, and air pollution, utilizing an offline version of the Vayu min-max normalization priority weights.
- **Exposure Simulator:** Visualizes potential exposure across different scenarios (indoor vs outdoor) and respiratory configurations (with or without N95 mask protection) using custom activity multipliers.
- **AI Health Coach:** Interactive Recovery Assistant that helps with breathing protocols and anti-inflammatory suggestions.
- **Zero Dependencies:** Runs entirely on static HTML/CSS/JS without calling external APIs or backends.

## Getting Started

### Option 1: Open Directly in Browser
You can open `frontend/index.html` directly in any web browser:
1. Double-click the `frontend/index.html` file in your File Explorer.
2. The page will load and function fully offline!

### Option 2: Run Local Dev Server
If you want to run it via a local static web server:
1. Make sure you have [Node.js](https://nodejs.org/) installed.
2. Open a terminal in the `frontend/` directory and run:
   ```bash
   npm install
   npm start
   ```
3. Open your browser and navigate to `http://localhost:3000`.
