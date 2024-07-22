document.addEventListener('DOMContentLoaded', () => {
  const showOnMapButton = document.getElementById('show-league-map');
  const mapElement = document.getElementById('league-map');

  if (showOnMapButton && mapElement) {
    showOnMapButton.addEventListener('click', (event) => {
      event.preventDefault();
      mapElement.style.display = 'block';

      const teamsData = JSON.parse(mapElement.dataset.teams);

      if (teamsData.length === 0) {
        alert('No teams to display on the map.');
        return;
      }

      const map = L.map('league-map').setView([teamsData[0].lat, teamsData[0].lng], 10);

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
      }).addTo(map);

      teamsData.forEach(team => {
        const iconSvg = `
          <svg xmlns="http://www.w3.org/2000/svg" width="60" height="80" viewBox="0 0 60 80" class="icon-container">
            <polygon points="30,0 10,40 50,40" fill="#ff0000" />
            <circle cx="30" cy="30" r="28" stroke="black" stroke-width="2" fill="white" />
            <image xlink:href="${team.logo_url}" x="2" y="2" width="56" height="56" />
          </svg>
        `;

        const customIcon = L.divIcon({
          className: 'icon-container',
          html: iconSvg,
          iconSize: [60, 80],
          iconAnchor: [30, 80],
        });

        L.marker([team.lat, team.lng], { icon: customIcon }).addTo(map)
          .bindPopup(`<b>${team.name}</b>`)
          .openPopup();
      });
    });
  }
});
