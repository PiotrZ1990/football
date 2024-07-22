document.addEventListener('DOMContentLoaded', () => {
  const showOnMapButton = document.getElementById('show-on-map');
  const mapElement = document.getElementById('map');

  if (showOnMapButton && mapElement) {
    showOnMapButton.addEventListener('click', (event) => {
      event.preventDefault();
      mapElement.style.display = 'block';

      const teamLat = parseFloat(mapElement.dataset.lat);
      const teamLng = parseFloat(mapElement.dataset.lng);
      const teamLogo = mapElement.dataset.logo;
      const teamName = mapElement.dataset.name;
      const teamCity = mapElement.dataset.city;

      // Inicjalizacja mapy
      const map = L.map('map').setView([teamLat, teamLng], 13);

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
      }).addTo(map);

      // Tworzenie SVG dla ikony
      const iconSvg = `
        <svg xmlns="http://www.w3.org/2000/svg" width="60" height="80" viewBox="0 0 60 80" class="icon-container">
          <!-- Gałka lodów -->
          <polygon points="30,0 10,40 50,40" fill="#ff0000" />
          <!-- Okrągły kontener -->
          <circle cx="30" cy="30" r="28" stroke="black" stroke-width="2" fill="white" />
          <image href="${teamLogo}" x="2" y="2" width="56" height="56" />
        </svg>
      `;

      const customIcon = L.divIcon({
        className: 'icon-container', // Klasa CSS dla ikon
        html: iconSvg,
        iconSize: [60, 80], // Rozmiar ikony
        iconAnchor: [30, 80], // Punkt kotwiczenia ikony
      });

      L.marker([teamLat, teamLng], { icon: customIcon }).addTo(map)
        .bindPopup(`<b>${teamName}</b><br>${teamCity}`)
        .openPopup();
    });
  }
});
