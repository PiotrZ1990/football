//= require leaflet
//= require teams
//= require leagues
//= require rails-ujs
//= require chartkick
//= require Chart.bundle
//= require bootstrap
 
document.addEventListener('DOMContentLoaded', () => {
  const compareTeamsModal = new bootstrap.Modal(document.getElementById('compareTeamsModal'));

  document.querySelector('.btn-success').addEventListener('click', () => {
    compareTeamsModal.show();
  });

  document.querySelectorAll('[data-bs-dismiss="modal"]').forEach(button => {
    button.addEventListener('click', () => {
      compareTeamsModal.hide();
    });
  });

  const form = document.querySelector('#compareTeamsModal form');
  if (form) {
    form.addEventListener('submit', (event) => {
      event.preventDefault(); // Zapobiega domyślnemu działaniu formularza
      const formData = new FormData(form);
      fetch(form.action, {
        method: 'POST', // Ustaw metodę na POST
        body: formData,
        headers: {
          'X-Requested-With': 'XMLHttpRequest' // Dodaj nagłówek, aby Rails rozpoznał żądanie AJAX
        }
      })
      .then(response => response.json()) // Oczekuj odpowiedzi JSON
      .then(data => {
        console.log('Response data:', data); // Logowanie danych odpowiedzi
        if (data.redirect_url) {
          window.location.href = data.redirect_url; // Przekierowuje na stronę porównań
        } else {
          alert('Something went wrong. Please try again.');
        }
      })
      .catch(error => {
        console.error('Error:', error);
      });
    });
  }
});
