function logoFadeInOut() {
  $('#fadelogo').fadeToggle(600);
  $('#fadelogo').fadeToggle(300)
}

$(document).ready(function() {
  logoFadeInOut()
  setInterval(function() { logoFadeInOut() }, 8000);
})
