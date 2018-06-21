function logoFadeInOut() {
  $('#fadelogo').fadeToggle(600);
  $('#fadelogo').fadeToggle(300)
}

function refreshData() {
  $.get( "/users", function( data ) {
    $( "#registeredUsersCount" ).html( data.registered_users );
    $( "#onlineUsersCount" ).html( data.users.length );

    var names = "";

    $.each(data.users, function( _, name ) {
      el = "<li>" + name + "</li>";
      names += el;
    });

    $( ".names-list").html(names);
  })
  .fail(function() {
    location.reload();
  });
}

$(document).ready(function() {
  logoFadeInOut();
  setTimeout(function() {logoFadeInOut()}, 5000);
  setTimeout(function() {refreshData()}, 5000)
})