addEventListener('turbolinks:load', function(event) {
  $('.need-section .feed .event .user').popup({ hoverable: true });
  $('select.ui.selection.dropdown').dropdown();
});