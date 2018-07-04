function logoFadeInOut() {
  $('#fadelogo').fadeToggle(600);
  $('#fadelogo').fadeToggle(300)
}

function refreshData() {
  $.get( "/users", function( data ) {
    $( "#registeredUsersCount" ).html( data.registered_users );
    $( "#onlineUsersCount" ).html( data.users.length );

    if (data.status_ok == true) {
      $('#error-banner').attr('hidden', true) // hide error banner
    } else if (data.status_ok == false) {
      $('#error-banner').attr('hidden', false) // show error banner
    }

    var names = "";

    $.each(data.users, function( _, user ) {
      el = `
<li class='pt-2'>
  <a href='${user.profile_url}'>
  <img height=50 src='${user.image_url}' class='rounded'>
    ${user.name}
  </a>
</li>`;
      names += el;
    });

    $( ".names-list").html(names);
  })
  .fail(function() {
    location.reload();
  });
}

$(document).ready(function() {
  $(function () {
    $('[data-toggle="popover"]').popover()
  })
  
  refreshData();

  setInterval(function() { logoFadeInOut() }, 4500);
  setInterval(function() { refreshData() }, 15000)
})
