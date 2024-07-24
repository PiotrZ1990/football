document.addEventListener('DOMContentLoaded', () => {
  const showOnMapButton = document.getElementById('show-on-map');
  const mapElement = document.getElementById('map');
  const showHistoryButton = document.getElementById('show-history');
  const historyElement = document.getElementById('history');
  const backToDetailsButton = document.getElementById('back-to-details');

  let matchMarkers = [];
  let matchData = [];
  let currentIndex = 0;
  let interval;
  let map;

  if (showOnMapButton && mapElement) {
    showOnMapButton.addEventListener('click', (event) => {
      event.preventDefault();
      mapElement.style.display = 'block';

      if (!map) {
        const teamLat = parseFloat(mapElement.dataset.lat);
        const teamLng = parseFloat(mapElement.dataset.lng);
        map = L.map('map').setView([teamLat, teamLng], 13);

        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
          attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        }).addTo(map);

        const teamLogo = mapElement.dataset.logo;
        const teamName = mapElement.dataset.name;
        const teamCity = mapElement.dataset.city;

        const iconSvg = `
          <svg xmlns="http://www.w3.org/2000/svg" width="60" height="80" viewBox="0 0 60 80" class="icon-container">
            <polygon points="30,0 10,40 50,40" fill="#ff0000" />
            <circle cx="30" cy="30" r="28" stroke="black" stroke-width="2" fill="white" />
            <image href="${teamLogo}" x="2" y="2" width="56" height="56" />
          </svg>
        `;

        const customIcon = L.divIcon({
          className: 'icon-container',
          html: iconSvg,
          iconSize: [60, 80],
          iconAnchor: [30, 80],
        });

        L.marker([teamLat, teamLng], { icon: customIcon }).addTo(map)
          .bindPopup(`<b>${teamName}</b><br>${teamCity}`)
          .openPopup();
      }
    });
  }

  if (showHistoryButton && historyElement) {
    showHistoryButton.addEventListener('click', (event) => {
      event.preventDefault();
      const teamId = historyElement.dataset.teamId;

      fetch(`/teams/${teamId}/history`)
        .then(response => response.json())
        .then(data => {
          matchData = data.matches;
          historyElement.style.display = 'block';
          startHighlighting();
        })
        .catch(error => console.error('Error fetching history:', error));
    });

    if (backToDetailsButton) {
      backToDetailsButton.addEventListener('click', (event) => {
        event.preventDefault();
        historyElement.style.display = 'none';
        if (interval) {
          clearInterval(interval);
        }
        // Optionally, clear all markers if desired
        // matchMarkers.forEach(marker => marker.remove());
        // matchMarkers = [];
      });
    }
  }

  function startHighlighting() {
    interval = setInterval(() => {
      if (currentIndex >= matchData.length) {
        clearInterval(interval);
        return;
      }

      const match = matchData[currentIndex];
      const homeLatLng = [match.home_team_lat, match.home_team_lng];
      const awayLatLng = [match.away_team_lat, match.away_team_lng];

      // Determine color based on outcome
      const color = match.outcome === 'Win' ? 'green' : (match.outcome === 'Loss' ? 'red' : 'gray');

      // Add new markers if map is initialized
      if (map) {
        if (homeLatLng) {
          const homeMarker = L.circle(homeLatLng, { color: color, radius: 5000 }).addTo(map);
          matchMarkers.push(homeMarker);
        }
        if (awayLatLng) {
          const awayMarker = L.circle(awayLatLng, { color: color, radius: 5000 }).addTo(map);
          matchMarkers.push(awayMarker);
        }
      }

      // Append the corresponding row to the table and make it visible
      const tbody = historyElement.querySelector('tbody');
      const row = document.createElement('tr');
      row.innerHTML = `
        <td>${match.home_team}</td>
        <td>${match.away_team}</td>
        <td>${match.home_score} - ${match.away_score}</td>
        <td>${match.outcome}</td>
      `;
      tbody.appendChild(row);

      // Highlight the row
      row.style.opacity = 0; // Initially hide the row
      setTimeout(() => {
        row.style.transition = 'opacity 1s';
        row.style.opacity = 1; // Fade in
      }, 0);

      // Scroll to the new row
      row.scrollIntoView({ behavior: 'smooth', block: 'end' });

      currentIndex++;
    }, 2000);
  }
});
