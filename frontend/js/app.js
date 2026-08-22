// ============================
// VAYU App — Standalone Frontend Controller
// ============================

// Immediately apply theme before first paint
(function() {
  const savedTheme = localStorage.getItem('vayu-theme');
  if (savedTheme === 'dark') {
    document.body.classList.add('dark-theme');
  }
})();


// Local Profile Storage Key
const PROFILE_STORAGE_KEY = 'vayu_user_profile';

// Default initial profile
const DEFAULT_PROFILE = {
  name: "Siya Satija",
  age: 25,
  is_pregnant: false,
  conditions: ["allergies"],
  protection_mode: "N95 Respirator",
  home_latitude: 28.6139,
  home_longitude: 77.2090
};

// Retrieve profile helper
function getProfile() {
  const stored = localStorage.getItem(PROFILE_STORAGE_KEY);
  if (stored) {
    try {
      return JSON.parse(stored);
    } catch (e) {
      console.warn("Failed to parse local profile:", e);
    }
  }
  return { ...DEFAULT_PROFILE };
}

// Save profile helper
function saveProfile(profileData) {
  localStorage.setItem(PROFILE_STORAGE_KEY, JSON.stringify(profileData));
}

// Screens that show the bottom nav bar
const BOTTOM_NAV_SCREENS = new Set(['dashboard-screen', 'map-screen', 'profile-screen']);

// Map each bottom-nav screen to its tab button ID
const SCREEN_TO_BNAV = {
  'dashboard-screen': 'bnav-home',
  'map-screen':       'bnav-routes',
  'profile-screen':   'bnav-profile'
};

// Navigation system (replicates GoRouter from Flutter)
function navigateTo(screenId) {
  // Switch active screen
  document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
  const target = document.getElementById(screenId);
  if (target) {
    target.classList.add('active');
    window.scrollTo(0, 0);
  }

  // Toggle bottom nav bar visibility
  if (BOTTOM_NAV_SCREENS.has(screenId)) {
    document.body.classList.add('show-bottom-nav');
  } else {
    document.body.classList.remove('show-bottom-nav');
  }

  // Update active tab highlight
  document.querySelectorAll('.bnav-item').forEach(btn => btn.classList.remove('active'));
  const activeBnavId = SCREEN_TO_BNAV[screenId];
  if (activeBnavId) {
    const activeBtn = document.getElementById(activeBnavId);
    if (activeBtn) activeBtn.classList.add('active');
  }
}

// Closes a bottom sheet when the user taps the dim backdrop (outside the panel).
// event.stopPropagation() on .sheet-panel ensures inner taps never reach here.
function handleBackdropClick(event, targetScreenId) {
  if (event.target === event.currentTarget) {
    navigateTo(targetScreenId);
  }
}



// 1. Fetch & Initialize User Profile from LocalStorage
async function loadUserProfile() {
  const data = getProfile();
  
  // Update header username
  const subtitleEl = document.querySelector('.dashboard-header .subtitle');
  if (subtitleEl) {
    subtitleEl.textContent = `Hello, ${data.name || 'User'} • Real-time Air Health`;
  }
  
  // Update profile page UI elements
  const nameField = document.querySelector('.profile-screen h2');
  if (nameField) {
    nameField.textContent = `Welcome, ${data.name || 'User'}`;
  }
  
  const ageSlider = document.getElementById('age-slider');
  const ageDisplay = document.getElementById('age-display');
  if (ageSlider && ageDisplay) {
    ageSlider.value = data.age || 25;
    ageDisplay.textContent = `${data.age || 25} years`;
  }

  // Check current conditions
  const conditionChips = document.querySelectorAll('.profile-form-card .chip');
  conditionChips.forEach(chip => {
    const condName = chip.textContent.trim().toLowerCase();
    if (data.conditions && data.conditions.includes(condName)) {
      chip.classList.add('selected');
    } else {
      chip.classList.remove('selected');
    }
  });

  // Update pregnant checkbox status
  const pregnantCheckbox = document.querySelector('.profile-form-card input[type="checkbox"]');
  if (pregnantCheckbox) {
    pregnantCheckbox.checked = !!data.is_pregnant;
  }

  // Update protection dropdown choice
  const protectionSelect = document.querySelector('.profile-form-card select');
  if (protectionSelect) {
    protectionSelect.value = data.protection_mode || "N95 Respirator";
  }
}

// 2. Fetch Live Localized AQI & Weather (Mocked Client-Side)
async function loadLiveAqi() {
  // Static mock AQI for Dashboard
  const data = {
    aqi: 45,
    pm25: 12.0,
    pm10: 20.0,
    station_name: "New Delhi (Local)",
    category: "GOOD"
  };
  
  // Update Dashboard Hero AQI Card
  const aqiValEl = document.getElementById('dash-aqi-val');
  const aqiCatEl = document.getElementById('dash-aqi-cat');
  const aqiIconWrap = document.getElementById('dash-aqi-icon');
  
  if (aqiValEl) aqiValEl.textContent = data.aqi;
  if (aqiCatEl) aqiCatEl.textContent = data.category;
  
  // Color coding & icon matching
  let aqiColor = 'var(--aqi-good)';
  let aqiBg = 'rgba(0,191,165,0.1)';
  
  if (data.aqi > 50 && data.aqi <= 100) {
    aqiColor = 'var(--aqi-moderate)';
    aqiBg = 'rgba(255,179,0,0.1)';
  } else if (data.aqi > 100) {
    aqiColor = 'var(--aqi-bad)';
    aqiBg = 'rgba(229,57,53,0.1)';
  }
  
  if (aqiValEl) aqiValEl.style.color = aqiColor;
  if (aqiCatEl) aqiCatEl.style.color = aqiColor;
  if (aqiIconWrap) {
    aqiIconWrap.style.background = aqiBg;
    const iconEl = aqiIconWrap.querySelector('.material-icons');
    if (iconEl) iconEl.style.color = aqiColor;
  }
  
  // Update Average AQI Card in Stats Grid
  const avgAqiCard = document.querySelectorAll('.stat-card')[2];
  if (avgAqiCard) {
    const valEl = avgAqiCard.querySelector('.stat-value');
    if (valEl) valEl.textContent = data.aqi;
  }
}

// 3. Save Health Profile Changes via LocalStorage
async function saveUserProfile() {
  const ageSlider = document.getElementById('age-slider');
  const selectedChips = document.querySelectorAll('.profile-form-card .chip.selected');
  const conditions = Array.from(selectedChips).map(chip => chip.textContent.trim().toLowerCase());
  const pregnantCheckbox = document.querySelector('.profile-form-card input[type="checkbox"]');
  const protectionSelect = document.querySelector('.profile-form-card select');
  
  const current = getProfile();
  const payload = {
    ...current,
    age: parseInt(ageSlider ? ageSlider.value : 25),
    conditions: conditions,
    is_pregnant: pregnantCheckbox ? pregnantCheckbox.checked : false,
    protection_mode: protectionSelect ? protectionSelect.value : "N95 Respirator"
  };
  
  saveProfile(payload);
  alert("Profile updated successfully!");
  navigateTo('dashboard-screen');
  loadUserProfile();
}

// Hook up Profile update button
const profileBtn = document.querySelector('.profile-form-card .vayu-btn');
if (profileBtn) {
  profileBtn.removeAttribute('onclick');
  profileBtn.addEventListener('click', saveUserProfile);
}

// 4. Run Exposure Simulation Endpoint (Mocked Client-Side)
async function runSimulation() {
  const activeScenarioEl = document.querySelector('.scenario-chip.active');
  const scenario = activeScenarioEl ? activeScenarioEl.getAttribute('data-scenario') : 'indoor';
  const maskActive = document.getElementById('mask-toggle').classList.contains('active');
  
  // Base default values
  let duration = 60;
  let activity = 'indoor';
  
  if (scenario === 'outdoor') {
    activity = 'outdoor';
    duration = 120;
  } else if (scenario === 'motor' || scenario === 'active') {
    activity = 'commute';
    duration = 45;
  }
  
  // Calculate Personal Exposure Score locally using backend formula:
  // (AQI * duration * activity_multiplier * mask_factor) / 100.0
  const aqi = 120; // Peak forecast simulator target
  let activity_multiplier = 1.0;
  if (activity === 'outdoor') {
    activity_multiplier = 2.0;
  } else if (activity === 'commute') {
    activity_multiplier = 1.5;
  }
  
  const mask_factor = maskActive ? 0.15 : 1.0;
  const exposure_score = (aqi * duration * activity_multiplier * mask_factor) / 100.0;
  const vitality_decay = exposure_score * 0.05;
  
  // Update Diagnostic Outcome values
  const outcomeValEl = document.querySelector('#sim-screen .vayu-card.white div:nth-child(2)');
  if (outcomeValEl) {
    outcomeValEl.textContent = `Personal Exposure Score: ${exposure_score.toFixed(2)} PE.`;
  }
  
  const outcomeDescEl = document.querySelector('#sim-screen .vayu-card.white div:nth-child(3)');
  if (outcomeDescEl) {
    outcomeDescEl.textContent = `Vitality Preserved. Estimated Lung stress index decay: ${vitality_decay.toFixed(3)} stress units. ${maskActive ? 'N95 mask defense enabled.' : 'No respiratory defense active.'}`;
  }
}

// Re-bind scenario chip triggers for simulate logic
document.querySelectorAll('.scenario-chip').forEach(chip => {
  chip.addEventListener('click', () => {
    document.querySelectorAll('.scenario-chip').forEach(c => c.classList.remove('active'));
    chip.classList.add('active');
    runSimulation();
  });
});

// Re-bind mask toggle for simulate logic
const maskToggle = document.getElementById('mask-toggle');
if (maskToggle) {
  maskToggle.addEventListener('click', () => {
    maskToggle.classList.toggle('active');
    runSimulation();
  });
}

// 5. Connect AI Health Coach LLM Endpoint (Rule-Based Chat System)
const COACH_RESPONSES = [
  "Based on your current exposure profile, I recommend wearing an N95 respirator outdoors and utilizing HEPA purifiers inside.",
  "Make sure to practice Box Breathing or other breathing techniques to clear any inhaled particulate matter from your airways.",
  "Staying hydrated and drinking antioxidant-rich teas (like green tea with turmeric/ginger) helps reduce systemic inflammation.",
  "I monitor the surrounding AQI sensors in real time and will automatically notify you if active protective measures are required.",
  "Reducing physical exertion outdoors during high-pollution hours is key to preventing long-term respiratory strain."
];

async function sendCoachMessage() {
  const input = document.getElementById('coach-input');
  if (!input || !input.value.trim()) return;

  const scroll = document.querySelector('.coach-scroll');
  const userText = input.value.trim().toLowerCase();
  
  // Add user bubble
  const userBubble = document.createElement('div');
  userBubble.className = 'chat-bubble user';
  userBubble.textContent = input.value.trim();
  scroll.appendChild(userBubble);
  input.value = '';
  scroll.scrollTop = scroll.scrollHeight;

  // Find a suitable response locally
  let reply = "";
  if (userText.includes("hello") || userText.includes("hi")) {
    reply = "Hello! I'm Vayu, your recovery and wellness coach. How can I help you protect your lungs today? 🌿";
  } else if (userText.includes("mask") || userText.includes("n95")) {
    reply = "Using a certified N95 respirator reduces particulate intake by up to 85-95%. I suggest wearing one when outdoor AQI exceeds 100.";
  } else if (userText.includes("exercise") || userText.includes("run") || userText.includes("workout")) {
    reply = "For workouts when AQI is high, swap outdoor running for indoor yoga or bodyweight training to avoid deep inhalation of toxins.";
  } else if (userText.includes("asthma") || userText.includes("copd") || userText.includes("breath")) {
    reply = "Practice controlled diaphragmatic or Box Breathing. If you feel tightness, return indoors immediately and monitor your symptoms closely.";
  } else {
    // Return a random general Vayu advice
    const idx = Math.floor(Math.random() * COACH_RESPONSES.length);
    reply = COACH_RESPONSES[idx];
  }

  // Simulate a short thinking delay for a premium UI feel
  setTimeout(() => {
    const aiBubble = document.createElement('div');
    aiBubble.className = 'chat-bubble';
    aiBubble.textContent = reply;
    scroll.appendChild(aiBubble);
    scroll.scrollTop = scroll.scrollHeight;
  }, 400);
}

// App-level state for selected route and recommendation tracking
window.selectedRouteId = null;
window.selectedRouteGeometry = null;
window.lastRoutesData = null;

// Handle travel mode tab selection changes
function selectRouteMode(el) {
  document.querySelectorAll('.route-mode-chips .chip').forEach(chip => {
    chip.classList.remove('selected');
  });
  el.classList.add('selected');
  // Clear selected route session state on travel mode change
  window.selectedRouteId = null;
  window.selectedRouteGeometry = null;
  searchRoutes();
}

// Handle route preference optimization mode changes
function selectRoutePreference(el) {
  document.querySelectorAll('.route-preference-chips .chip').forEach(chip => {
    chip.classList.remove('selected');
  });
  el.classList.add('selected');
  // Re-render local routes list based on selected preference without query requests
  renderRoutesUI();
}

// Render dynamic candidate route list and decision badges locally
function renderRoutesUI() {
  const routePanel = document.querySelector('.route-panel');
  if (!routePanel) return;

  const routes = window.lastRoutesData ? window.lastRoutesData.routes : [];
  const recs = window.lastRoutesData ? window.lastRoutesData.recommendations : {};
  
  if (routes.length === 0) {
    routePanel.innerHTML = '<div class="vayu-card white" style="text-align:center; padding: 24px; font-weight: 700; color: var(--aqi-bad);">No routes found between these locations.</div>';
    return;
  }

  // Identify active user priority preference (SPEED, BALANCED, or HEALTH)
  const pref = document.querySelector('.route-preference-chips .chip.selected')?.getAttribute('data-pref') || 'balanced';
  const recInfo = recs[pref] || {};

  // Auto-default active selection to recommended route on initial load
  if (!window.selectedRouteId) {
    const recommendedRoute = routes.find(r => r.id === recInfo.recommended_route_id) || routes[0];
    window.selectedRouteId = recommendedRoute.id;
    window.selectedRouteGeometry = recommendedRoute.geometry;
  }

  routePanel.innerHTML = '';

  // Render Vayu Recommendation Callout Header at the top
  const headerCard = document.createElement('div');
  headerCard.className = 'vayu-card dark-teal';
  headerCard.style.marginBottom = '16px';
  headerCard.style.padding = '16px';
  headerCard.innerHTML = `
    <div style="font-weight: 800; font-size: 10px; letter-spacing: 1.5px; color: var(--teal-100); text-transform: uppercase;">Vayu Recommended Option</div>
    <div style="font-size: 14px; font-weight: 700; color: white; margin-top: 8px; line-height: 1.4;">${recInfo.reason || "Fastest available option."}</div>
  `;
  routePanel.appendChild(headerCard);

  // Render route cards
  routes.forEach((route, index) => {
    const card = document.createElement('div');
    const isRecommended = (route.id === recInfo.recommended_route_id);
    const isSelected = (window.selectedRouteId === route.id);

    card.className = `vayu-card route-card ${isSelected ? 'selected' : 'white'}`;
    card.style.borderRadius = 'var(--card-radius)';
    card.style.cursor = 'pointer';
    card.style.marginBottom = '12px';

    // Set decision engine badge priorities
    let badgeHtml = '';
    if (isSelected && isRecommended) {
      badgeHtml = '<div class="best-badge" style="background:var(--teal-700); color:white;">🏆 VAYU RECOMMENDED</div>';
    } else if (isSelected && !isRecommended) {
      badgeHtml = '<div class="best-badge" style="background:#455A64; color:white;">👤 SELECTED BY YOU</div>';
    } else if (!isSelected && isRecommended) {
      badgeHtml = '<div class="best-badge" style="background:#E0F2F1; color:var(--teal-900); border:1px solid rgba(0,77,64,0.15);">✨ RECOMMENDED OPTION</div>';
    } else if (route.is_fastest) {
      badgeHtml = '<div class="best-badge" style="background:#0288D1; color:white;">⚡ FASTEST ROUTE</div>';
    } else {
      badgeHtml = '<div class="best-badge" style="background:#ECEFF1; color:#37474F; border:1px solid rgba(0,0,0,0.05);">🚗 ALTERNATIVE ROUTE</div>';
    }

    const durationMins = Math.round(route.duration_seconds / 60);
    const distanceKm = (route.distance_meters / 1000).toFixed(1);

    // Match profile icon
    let modeIcon = "directions_car";
    if (route.profile === "foot-walking") modeIcon = "directions_walk";
    else if (route.profile === "cycling-regular") modeIcon = "directions_bike";

    // Build exposure fields template
    const exp = route.exposure || {};
    let exposureHtml = '';
    
    if (exp.data_available) {
      exposureHtml = `
        <div class="route-stats" style="display:flex; flex-wrap:wrap; gap:16px; margin-top:12px;">
          <div class="stat" style="display:flex; align-items:center; gap:6px; color:rgba(0,0,0,0.54); font-size:13px; font-weight:600;">
            <span class="material-icons" style="font-size:16px;">eco</span> Avg AQI: ${exp.average_aqi}
          </div>
          <div class="stat" style="display:flex; align-items:center; gap:6px; color:rgba(0,0,0,0.54); font-size:13px; font-weight:600;">
            <span class="material-icons" style="font-size:16px;">trending_up</span> Peak AQI: ${exp.peak_aqi}
          </div>
          <div class="stat" style="display:flex; align-items:center; gap:6px; color:var(--teal-900); font-size:13px; font-weight:700;">
            <span class="material-icons" style="font-size:16px;">health_and_safety</span> Estimated Exposure: ${exp.exposure_score}
          </div>
        </div>
      `;
    } else {
      exposureHtml = `
        <div class="route-stats" style="display:flex; gap:16px; margin-top:12px;">
          <div class="stat" style="display:flex; align-items:center; gap:6px; color:var(--aqi-bad); font-size:13px; font-weight:600;">
            <span class="material-icons" style="font-size:16px;">warning</span> Exposure data unavailable
          </div>
        </div>
      `;
    }

    card.innerHTML = `
      ${badgeHtml}
      <div class="route-header">
        <div class="route-mode">
          <span class="material-icons" style="color:var(--teal-800); vertical-align:middle; margin-right:4px;">${modeIcon}</span>
          Route ${index + 1} - ${durationMins} min
        </div>
        <div class="route-badge" style="background: rgba(60,211,173,0.1); color: var(--teal-900); font-weight: 700;">${distanceKm} km</div>
      </div>
      <div class="route-summary" style="margin-top:8px; font-size:13px; color:var(--black54); line-height:1.4;">
        ORS Path Alternative ${index + 1}
      </div>
      ${exposureHtml}
    `;

    card.addEventListener('click', () => {
      // Set chosen route in JS memory state
      window.selectedRouteId = route.id;
      window.selectedRouteGeometry = route.geometry;
      console.log("Selected Route updated by user:", route.id, route.geometry ? "Has Geometry" : "No Geometry");
      
      // Re-render UI to update card selection highlights and SELECTED BY YOU badge
      renderRoutesUI();
    });

    routePanel.appendChild(card);
  });
}

// 6. Route Search Coordinates & Geocoding Flow (Mocked Client-Side)
const MOCK_LOCATIONS = {
  "gandhi park": { latitude: 28.6139, longitude: 77.2090 },
  "ito junction": { latitude: 28.5708, longitude: 77.3258 },
  "new delhi": { latitude: 28.6139, longitude: 77.2090 },
  "noida": { latitude: 28.5708, longitude: 77.3258 },
  "delhi": { latitude: 28.6139, longitude: 77.2090 },
  "gurgaon": { latitude: 28.4595, longitude: 77.0266 },
  "gurugram": { latitude: 28.4595, longitude: 77.0266 }
};

function mockGeocode(query) {
  const normalized = query.toLowerCase().trim();
  for (const [key, coords] of Object.entries(MOCK_LOCATIONS)) {
    if (normalized.includes(key)) {
      return { success: true, ...coords, display_name: query };
    }
  }
  return {
    success: true,
    latitude: 28.6139 + (Math.random() - 0.5) * 0.05,
    longitude: 77.2090 + (Math.random() - 0.5) * 0.05,
    display_name: query
  };
}

function mockRoutes(origin, dest, profile, maskFactor) {
  const profileMultipliers = {
    "foot-walking": 2.0,
    "cycling-regular": 3.0,
    "driving-car": 1.5
  };
  const multiplier = profileMultipliers[profile] || 1.0;
  const count = profile === "driving-car" ? 2 : 1;
  const routes = [];

  for (let i = 0; i < count; i++) {
    let baseDistance = 3500;
    let baseDuration = 720;
    
    if (profile === "foot-walking") {
      baseDistance = 2100;
      baseDuration = 1680;
    } else if (profile === "cycling-regular") {
      baseDistance = 2300;
      baseDuration = 600;
    }

    const distance = Math.round(baseDistance * (1.0 + i * 0.15));
    const duration = Math.round(baseDuration * (1.0 + i * 0.17));
    
    const avgAqi = Math.round(55 + (i * 15) + (Math.random() * 5));
    const peakAqi = Math.round(avgAqi * 1.2);
    
    const durationMins = duration / 60.0;
    const exposure = (avgAqi * durationMins * multiplier * maskFactor) / 100.0;

    routes.push({
      id: `${profile}-${i}`,
      geometry: {
        type: "LineString",
        coordinates: [
          [origin.longitude, origin.latitude],
          [dest.longitude, dest.latitude]
        ]
      },
      distance_meters: distance,
      duration_seconds: duration,
      profile: profile,
      alternative: i > 0,
      exposure: {
        data_available: true,
        average_aqi: avgAqi,
        peak_aqi: peakAqi,
        exposure_score: parseFloat(exposure.toFixed(2)),
        exposure_category: avgAqi <= 50 ? "Good" : (avgAqi <= 100 ? "Moderate" : "Unhealthy")
      }
    });
  }

  routes.sort((a, b) => a.duration_seconds - b.duration_seconds);
  routes[0].is_fastest = true;

  const recommendations = mockRecommendations(routes);

  return {
    routes: routes,
    recommendations: recommendations
  };
}

function mockRecommendations(routes) {
  const PREFERENCE_WEIGHTS = {
    "speed": { time: 0.9, exposure: 0.1 },
    "balanced": { time: 0.5, exposure: 0.5 },
    "health": { time: 0.2, exposure: 0.8 }
  };

  const fastestRoute = routes.find(r => r.is_fastest) || routes[0];
  const fastestDuration = fastestRoute.duration_seconds;
  const fastestExposureVal = fastestRoute.exposure ? fastestRoute.exposure.exposure_score : 0.0;

  const recommendations = {};

  for (const [preference, weights] of Object.entries(PREFERENCE_WEIGHTS)) {
    const scoredRoutes = [];
    const durations = routes.map(r => r.duration_seconds);
    const exposures = routes.map(r => r.exposure.exposure_score);

    const minDur = Math.min(...durations);
    const maxDur = Math.max(...durations);
    const minExp = Math.min(...exposures);
    const maxExp = Math.max(...exposures);

    for (const r of routes) {
      let normTime = 0.0;
      if (maxDur > minDur) {
        normTime = (r.duration_seconds - minDur) / (maxDur - minDur);
      }

      let normExposure = 0.0;
      if (maxExp > minExp) {
        normExposure = (r.exposure.exposure_score - minExp) / (maxExp - minExp);
      }

      let score = (weights.time * normTime) + (weights.exposure * normExposure);

      if (preference === "health" && r.duration_seconds > 1.5 * fastestDuration) {
        const penalty = ((r.duration_seconds / fastestDuration) - 1.5) * 0.5;
        score += penalty;
      }

      scoredRoutes.push({ route: r, score: score });
    }

    scoredRoutes.sort((a, b) => a.score - b.score);
    const bestChoice = scoredRoutes[0];
    const bestRoute = bestChoice.route;

    const additionalTime = bestRoute.duration_seconds - fastestDuration;
    const bestExposureVal = bestRoute.exposure.exposure_score;

    let exposureReduction = 0.0;
    if (fastestExposureVal > 0.0) {
      exposureReduction = ((fastestExposureVal - bestExposureVal) / fastestExposureVal) * 100.0;
    }

    let reason = "";
    if (bestRoute.id === fastestRoute.id) {
      reason = "Fastest available route with the lowest available decision score.";
    } else {
      const addMins = Math.round(additionalTime / 60);
      const reductionPct = Math.round(exposureReduction);
      if (addMins === 0) {
        reason = `Matches fastest travel time with an estimated ${reductionPct}% lower exposure.`;
      } else {
        reason = `Adds ${addMins} minutes but has an estimated ${reductionPct}% lower exposure than the fastest route.`;
      }
    }

    recommendations[preference] = {
      recommended_route_id: bestRoute.id,
      decision_score: parseFloat(bestChoice.score.toFixed(3)),
      reason: reason,
      additional_time_seconds: additionalTime,
      exposure_reduction_percent: Math.round(Math.max(0.0, exposureReduction)),
      exposure_data_available: true,
      partial_coverage: false
    };
  }

  return recommendations;
}

async function searchRoutes() {
  const originVal = document.getElementById('origin-input').value.trim();
  const destVal = document.getElementById('destination-input').value.trim();
  
  if (!originVal || !destVal) {
    alert("Please enter both Origin and Destination.");
    return;
  }

  const routePanel = document.querySelector('.route-panel');
  const searchBtn = document.getElementById('route-search-btn');
  const activeMode = document.querySelector('.route-mode-chips .chip.selected')?.getAttribute('data-profile') || 'driving-car';
  
  // Set loading states on button and panel
  if (searchBtn) {
    searchBtn.style.opacity = '0.5';
    searchBtn.style.pointerEvents = 'none';
  }
  routePanel.innerHTML = '<div class="vayu-card white" style="text-align:center; padding: 24px; font-weight: 700; color: var(--teal-800);">Resolving locations...</div>';

  // Artificial short delay to simulate "resolving geocodes" for a premium UI feel
  setTimeout(() => {
    try {
      const originData = mockGeocode(originVal);
      routePanel.innerHTML = '<div class="vayu-card white" style="text-align:center; padding: 24px; font-weight: 700; color: var(--teal-800);">Calculating optimal routes...</div>';

      // Second short delay to simulate "calculating directions"
      setTimeout(() => {
        try {
          const destData = mockGeocode(destVal);
          
          let maskFactor = 1.0;
          const userProfile = getProfile();
          const mode = userProfile.protection_mode;
          if (mode === "N95 Respirator") {
            maskFactor = 0.15;
          } else if (mode === "Surgical Mask") {
            maskFactor = 0.5;
          } else if (mode === "Cloth Mask") {
            maskFactor = 0.8;
          }

          // Calculate routes and recommendations locally
          const data = mockRoutes(originData, destData, activeMode, maskFactor);
          
          // Store locally in memory cache
          window.lastRoutesData = data;
          window.selectedRouteId = null;
          window.selectedRouteGeometry = null;
          
          // Render routes UI
          renderRoutesUI();
        } catch (err) {
          console.error("VAYU Search Inner Error:", err);
          showSearchError(routePanel, err.message);
        } finally {
          resetSearchBtn(searchBtn);
        }
      }, 500);

    } catch (err) {
      console.error("VAYU Search Outer Error:", err);
      showSearchError(routePanel, err.message);
      resetSearchBtn(searchBtn);
    }
  }, 400);
}

function showSearchError(panel, msg) {
  panel.innerHTML = `
    <div class="vayu-card white" style="text-align:center; padding: 24px; color: var(--aqi-bad);">
      <span class="material-icons" style="font-size: 32px; margin-bottom: 8px;">warning</span>
      <div style="font-weight: 700; font-size: 14px;">${msg || "Location not found. Please try a more specific place."}</div>
    </div>
  `;
}

function resetSearchBtn(btn) {
  if (btn) {
    btn.style.opacity = '1';
    btn.style.pointerEvents = 'auto';
  }
}

// Bind Map Routing search button
const searchBtn = document.getElementById('route-search-btn');
if (searchBtn) {
  searchBtn.addEventListener('click', searchRoutes);
}

// Initialize Age range slider logic
const ageSlider = document.getElementById('age-slider');
const ageDisplay = document.getElementById('age-display');
if (ageSlider && ageDisplay) {
  // Initialize fill
  ageSlider.style.setProperty('--val', ageSlider.value + '%');
  ageSlider.addEventListener('input', () => {
    ageDisplay.textContent = ageSlider.value + ' years';
    ageSlider.style.setProperty('--val', ageSlider.value + '%');
  });
}

// Enter key binding for coach chat input
document.addEventListener('keydown', (e) => {
  if (e.key === 'Enter') {
    const coachInput = document.getElementById('coach-input');
    if (document.activeElement === coachInput) {
      sendCoachMessage();
    }
  }
});

// Draw Dashboard Exposure Chart
function drawExposureChart() {
  const canvas = document.getElementById('exposureChart');
  if (!canvas) return;
  const rect = canvas.getBoundingClientRect();
  if (rect.width === 0 || rect.height === 0) return;
  
  const dpr = window.devicePixelRatio || 1;
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  const ctx = canvas.getContext('2d');
  
  ctx.scale(dpr, dpr);
  const w = rect.width;
  const h = rect.height;
  
  const data = [20, 25, 45, 30, 50, 35, 15]; // Sample exposure data
  const maxData = 60;
  
  const padX = 20;
  const padY = 40;
  const stepX = (w - padX * 2) / (data.length - 1);
  
  const points = data.map((val, i) => {
    return {
      x: padX + i * stepX,
      y: h - padY - (val / maxData) * (h - padY * 2)
    };
  });
  
  const primaryColor = getComputedStyle(document.documentElement).getPropertyValue('--primary').trim() || '#3CD3AD';
  
  const gradient = ctx.createLinearGradient(0, 0, 0, h);
  gradient.addColorStop(0, 'rgba(60, 211, 173, 0.4)'); // Teal with opacity
  gradient.addColorStop(1, 'rgba(60, 211, 173, 0.0)');
  
  // Fill
  ctx.beginPath();
  ctx.moveTo(points[0].x, h);
  ctx.lineTo(points[0].x, points[0].y);
  
  for (let i = 0; i < points.length - 1; i++) {
    const cp1x = points[i].x + stepX / 2;
    const cp1y = points[i].y;
    const cp2x = points[i + 1].x - stepX / 2;
    const cp2y = points[i + 1].y;
    ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, points[i + 1].x, points[i + 1].y);
  }
  
  ctx.lineTo(points[points.length - 1].x, h);
  ctx.closePath();
  ctx.fillStyle = gradient;
  ctx.fill();
  
  // Line
  ctx.beginPath();
  ctx.moveTo(points[0].x, points[0].y);
  for (let i = 0; i < points.length - 1; i++) {
    const cp1x = points[i].x + stepX / 2;
    const cp1y = points[i].y;
    const cp2x = points[i + 1].x - stepX / 2;
    const cp2y = points[i + 1].y;
    ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, points[i + 1].x, points[i + 1].y);
  }
  ctx.strokeStyle = primaryColor;
  ctx.lineWidth = 4;
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  ctx.stroke();
}

function drawDeteriorationChart() {
  const canvas = document.getElementById('deteriorationChart');
  if (!canvas) return;
  
  const rect = canvas.getBoundingClientRect();
  if (rect.width === 0 || rect.height === 0) return;
  
  const dpr = window.devicePixelRatio || 1;
  canvas.width = rect.width * dpr;
  canvas.height = rect.height * dpr;
  const ctx = canvas.getContext('2d');
  
  ctx.scale(dpr, dpr);
  const w = rect.width;
  const h = rect.height;
  
  const data = [100, 95, 82, 60, 45, 30, 20]; // Vitality decay data
  const maxData = 100;
  
  const padX = 10;
  const padY = 20;
  const stepX = (w - padX * 2) / (data.length - 1);
  
  const points = data.map((val, i) => {
    return {
      x: padX + i * stepX,
      y: h - padY - (val / maxData) * (h - padY * 2)
    };
  });
  
  const gradient = ctx.createLinearGradient(0, 0, 0, h);
  gradient.addColorStop(0, 'rgba(255, 82, 82, 0.4)');
  gradient.addColorStop(1, 'rgba(255, 82, 82, 0.0)');
  
  ctx.beginPath();
  ctx.moveTo(points[0].x, h);
  ctx.lineTo(points[0].x, points[0].y);
  
  for (let i = 0; i < points.length - 1; i++) {
    const cp1x = points[i].x + stepX / 2;
    const cp1y = points[i].y;
    const cp2x = points[i + 1].x - stepX / 2;
    const cp2y = points[i + 1].y;
    ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, points[i + 1].x, points[i + 1].y);
  }
  
  ctx.lineTo(points[points.length - 1].x, h);
  ctx.closePath();
  ctx.fillStyle = gradient;
  ctx.fill();
  
  ctx.beginPath();
  ctx.moveTo(points[0].x, points[0].y);
  for (let i = 0; i < points.length - 1; i++) {
    const cp1x = points[i].x + stepX / 2;
    const cp1y = points[i].y;
    const cp2x = points[i + 1].x - stepX / 2;
    const cp2y = points[i + 1].y;
    ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, points[i + 1].x, points[i + 1].y);
  }
  ctx.strokeStyle = '#FF5252';
  ctx.lineWidth = 4;
  ctx.lineCap = 'round';
  ctx.lineJoin = 'round';
  ctx.stroke();
}

// App Startup Initializers
document.addEventListener('DOMContentLoaded', () => {
  initTheme();
  loadUserProfile();
  loadLiveAqi();
  runSimulation();
  searchRoutes(); // Auto-load initial route recommendations
  
  // Use ResizeObserver for robust canvas rendering when layout size stabilizes
  const exposureCanvas = document.getElementById('exposureChart');
  if (exposureCanvas) {
    const roExp = new ResizeObserver(() => {
      if (exposureCanvas.getBoundingClientRect().width > 0) drawExposureChart();
    });
    roExp.observe(exposureCanvas);
  }
  
  const deteriorationCanvas = document.getElementById('deteriorationChart');
  if (deteriorationCanvas) {
    const roDet = new ResizeObserver(() => {
      if (deteriorationCanvas.getBoundingClientRect().width > 0) drawDeteriorationChart();
    });
    roDet.observe(deteriorationCanvas);
  }
});

// Theme Toggle Logic
function initTheme() {
  const themeBtn = document.getElementById('theme-toggle-btn');
  if (!themeBtn) return;
  const icon = themeBtn.querySelector('.material-icons');
  if (!icon) return;
  
  // Set initial icon content based on current body theme
  const isDark = document.body.classList.contains('dark-theme');
  icon.textContent = isDark ? 'light_mode' : 'dark_mode';
  
  themeBtn.addEventListener('click', () => {
    document.body.classList.toggle('dark-theme');
    const nowDark = document.body.classList.contains('dark-theme');
    icon.textContent = nowDark ? 'light_mode' : 'dark_mode';
    localStorage.setItem('vayu-theme', nowDark ? 'dark' : 'light');
    
    // Redraw charts if visible to update colors
    if (typeof drawExposureChart === 'function') drawExposureChart();
    if (typeof drawDeteriorationChart === 'function') drawDeteriorationChart();
  });
}

