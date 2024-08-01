document.addEventListener('DOMContentLoaded', () => {
  const showOnMapButton = document.getElementById('show-on-map');
  const mapElement = document.getElementById('map');
  const showHistoryButton = document.getElementById('show-history');
  const historyElement = document.getElementById('history');
  const rankingElement = document.getElementById('ranking');
  const backToDetailsButton = document.getElementById('back-to-details');

  let matchMarkers = [];
  let matchData = [];
  let teamData = [];
  let currentIndex = 0;
  let interval;
  let map;

  const currentTeamId = rankingElement.dataset.currentTeamId; // Pobierz ID drużyny z danych elementu

  // Initialize teamData with zeroed values
  function initializeTeamData(teams) {
    teamData = teams.map(team => ({
      id: team.id,
      name: team.name,
      matches: team.matches || 0,
      wins: team.wins || 0,
      points: team.points || 0
    }));
    populateRankingTable(teamData);
  }

  // Populate the ranking table with the initial team data
  function populateRankingTable(teams) {
    const rankingTbody = rankingElement.querySelector('tbody');

    rankingTbody.innerHTML = ''; // Clear any existing ranking

    teams.forEach((team, index) => {
      const rankingRow = document.createElement('tr');
      const isCurrentTeam = team.id === parseInt(currentTeamId, 10); // Sprawdź, czy to obecna drużyna

      rankingRow.innerHTML = `
        <td>${index + 1}</td>
        <td class="${isCurrentTeam ? 'table-success' : ''}">${team.name}</td>
        <td>${team.matches}</td>
        <td>${team.wins}</td>
        <td>${team.points}</td>
      `;
      rankingTbody.appendChild(rankingRow);
    });
  }

  // Update an existing row in the ranking table
  function updateRankingTable(team) {
    const rankingTbody = rankingElement.querySelector('tbody');
    const rows = rankingTbody.querySelectorAll('tr');

    rows.forEach(row => {
      const teamNameCell = row.querySelector('td:nth-child(2)');
      if (teamNameCell.textContent === team.name) {
        row.querySelector('td:nth-child(3)').textContent = team.matches;
        row.querySelector('td:nth-child(4)').textContent = team.wins;
        row.querySelector('td:nth-child(5)').textContent = team.points;
      }
    });
  }

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
          initializeTeamData(data.league_teams); // Initialize with zeroed values

          // Sort matches chronologically by date
          matchData.sort((a, b) => new Date(a.date) - new Date(b.date));

          historyElement.style.display = 'block';
          rankingElement.style.display = 'block';
          startHighlighting();
        })
        .catch(error => console.error('Error fetching history:', error));
    });

    if (backToDetailsButton) {
      backToDetailsButton.addEventListener('click', (event) => {
        event.preventDefault();
        historyElement.style.display = 'none';
        rankingElement.style.display = 'none';
        if (interval) {
          clearInterval(interval);
        }
        // Remove all markers from the map
        matchMarkers.forEach(marker => marker.remove());
        matchMarkers = [];
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

      if (map) {
        if (homeLatLng) {
          const homeIcon = L.icon({
            iconUrl: match.home_team_logo,
            iconSize: [40, 40],
            iconAnchor: [20, 40]
          });

          const homeMarker = L.marker(homeLatLng, { icon: homeIcon }).addTo(map);
          homeMarker.bindPopup(`
            <b>Home Team:</b> ${match.home_team}<br>
            <b>Away Team:</b> ${match.away_team}<br>
            <b>Score:</b> ${match.home_score} - ${match.away_score}<br>
            <b>Outcome:</b> ${match.outcome}
          `);
          matchMarkers.push(homeMarker);
        }
        if (awayLatLng) {
          const awayIcon = L.icon({
            iconUrl: match.away_team_logo,
            iconSize: [40, 40],
            iconAnchor: [20, 40]
          });

          const awayMarker = L.marker(awayLatLng, { icon: awayIcon }).addTo(map);
          awayMarker.bindPopup(`
            <b>Home Team:</b> ${match.home_team}<br>
            <b>Away Team:</b> ${match.away_team}<br>
            <b>Score:</b> ${match.home_score} - ${match.away_score}<br>
            <b>Outcome:</b> ${match.outcome}
          `);
          matchMarkers.push(awayMarker);
        }
      }

      const tbody = historyElement.querySelector('tbody');
      const row = document.createElement('tr');
      row.innerHTML = `
        <td>${match.home_team}</td>
        <td>${match.away_team}</td>
        <td>${match.home_score} - ${match.away_score}</td>
        <td>${match.outcome}</td>
      `;
      tbody.appendChild(row);

      row.style.opacity = 0; 
      setTimeout(() => {
        row.style.transition = 'opacity 1s';
        row.style.opacity = 1; 
      }, 0);

      row.scrollIntoView({ behavior: 'smooth', block: 'end' });

      // updateRanking(match);

      currentIndex++;
    }, 2000);
  }
});
