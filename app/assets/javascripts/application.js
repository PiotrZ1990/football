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
});
