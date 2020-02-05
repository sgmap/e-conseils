function semantic_ui_calendar_datepicker_params() {
  // This can’t just be in semantic-ui.js with the other initializer, as we need to dynamically set the text from rails i18n.
  return {
    type: 'date',
    firstDayOfWeek: 1,
    disableMonth: true,
    disableYear: true,
    formatter: {
      date: function (date, settings) {
        var d = date.getDate();
        var m = date.getMonth() + 1;
        var y = date.getFullYear();
        return ("0"+d).slice(-2) + "/" + ("0"+m).slice(-2) + "/" + y;
      }
    },
    parser: {
      date: function (text, settings) {
        var parts = text.split('-');
        if(parts.length !== 3){
          parts = text.split('/').reverse();
        }
        if(parts.length === 3){
          return new Date(parts[0], parts[1] - 1, parts[2]);
        }
      }
    },
  };
}