$(document).ready(function() {
  player_hit();
  dealer_hit();
  show_dealers_hand();
  show_dealers_next_card();
}); 

function player_hit() {
  $(document).on('click', '#hit_btn', function() {
    $.ajax({
      url: '/game/player/hit'
    }).done(function(msg) {
      $('#game_container').replaceWith(msg);
    });
    return false;
  });
}

function dealer_hit() {
  $(document).on('click', '#stay_btn', function() {
    $.ajax({
      url: '/game/player/stay'
    }).done(function(msg) {
      $('#game_container').replaceWith(msg);
    });
    return false;
  });
}

function show_dealers_hand() {
  $(document).on('click', '#show_dealers_hand_btn', function() {
    $.ajax({
      url: '/game/dealer/show_hand'
    }).done(function(msg) {
      $('#game_container').replaceWith(msg);
    });
    return false;
  });
}

function show_dealers_next_card() {
  $(document).on('click', '#show_dealers_next_card_btn', function() {
    $.ajax({
      url: '/game/dealer/play'
    }).done(function(msg) {
      $('#game_container').replaceWith(msg);
    });
    return false;
  });
}
