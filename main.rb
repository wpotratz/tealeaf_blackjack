require 'rubygems'
require 'sinatra'
require 'pry'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'ate_all_my_grits' 

# TO DO: 


helpers do
  WINNING_TOTAL = 21
  DEALER_MINIMUM_TOTAL = 17
  
  def to_currency(amount)
    value = amount.to_i
    "$" + value.to_s
  end
  
  def calculate_total(hand)
    hand_total = 0
    hand.each do |card|  
      if card.last == 'A'
        hand_total += 11
      elsif card.last == '?'
        hand_total += 0
      elsif card.last.to_i == 0
        hand_total += 10
      else 
        hand_total += card.last.to_i
      end
    end
    hand.select {|card| card.last == 'A'}.each do |ace| 
      hand_total -= 10 if hand_total > WINNING_TOTAL
    end
    hand_total
  end
  
  def card_image(card)
    suits = {"C" => "clubs", "D" => "diamonds", "S" => "spades", "H" => "hearts"}
    labels = {"A" => "ace", "J" => "jack", "Q" => "queen", "K" => "king"}
    card_label =  if card.last.to_i == 0
                    labels[card.last]
                  else
                    card.last
                  end
    card_suit = suits[card.first]
    "\"/images/cards/#{card_suit}_#{card_label}.jpg\""
  end
  
  def player_total
    calculate_total(session[:player_cards])
  end
  
  def dealer_total
    calculate_total(session[:dealer_cards])
  end
  
  def bust?(hand_total)
    hand_total > WINNING_TOTAL  
  end
  
  def blackjack?(hand_total)
    hand_total == WINNING_TOTAL
  end

  def five_card_charlie?(player)
    player.size == 5 && !bust?(player_total)
  end
  
  def dealer_hit_minimum?
    dealer_total >= DEALER_MINIMUM_TOTAL
  end 
  
  def win?
    if blackjack?(player_total)
      true
    elsif blackjack?(dealer_total)
      false
    elsif dealer_hit_minimum?
      if bust?(dealer_total) || five_card_charlie?(session[:player_cards])
        true
      elsif bust?(player_total) || player_total < dealer_total
        false
      elsif player_total > dealer_total
        true
      elsif player_total == dealer_total
        "push"
      else
        false
      end
    end
  end

  def payout
    session[:bank] += (session[:bet] * 2)
  end
  
  def return_bet
    session[:bank] += session[:bet]
  end

  def process_bet
    if win? == "push"
      return_bet
    elsif win?
      payout
    end
  end
  
  def display_hand_results
    if win? == "push"
      @success = "The dealer ties with you. It's a push."
    elsif win?
      if five_card_charlie?(session[:player_cards])
        @success = "Five card charlie! #{session[:player_name]} wins!"
      elsif blackjack?(player_total)
        @success = "#{session[:player_name]} has blackjack!"
      elsif bust?(dealer_total)
        @success = "Dealer busts! #{session[:player_name]} wins!"
      else
        @success = "#{session[:player_name]} wins with #{player_total}!"
      end
    elsif bust?(player_total)
      @error = "#{session[:player_name]} busts! Dealer wins."
    elsif blackjack?(dealer_total)
      @error = "The dealer has blackjack."
    else
      @error = "The dealer wins with #{dealer_total}."
    end
  end
  
  def reveal_winner_and_prompt_another_round
    display_hand_results
    @show_play_another_round_buttons = true
    @show_hit_or_stay_buttons = false
    @show_dealers_next_card_button = false
  end
end

before do
  @show_hit_or_stay_buttons = true
  @show_play_another_round_buttons = false
  @show_show_dealers_next_card_button = false
end

get '/' do
  if session[:player_name]
    redirect '/bet'
  else
    redirect '/get_name'
  end
end

get '/get_name' do
  erb :get_name
end

post '/get_name' do
  session[:player_name] = params[:player_name]
  if session[:player_name].strip == ''
    @error = "Not a valid name, try again."
    redirect '/get_name'
  else
    session[:bank] = 1000
    redirect '/bet'
  end
end 

get '/bet' do
  if session[:bank].nil?
    redirect '/get_name'
  elsif session[:bank] <= 0
    redirect '/game/summary'
  end
  erb :bet
end

post '/bet' do
  session[:bet] = params[:bet].to_i
  if session[:bet] <= 0 || session[:bet] > session[:bank]
    @error = "Please enter a valid bet."
    erb :bet
  else
    session[:bank] -= session[:bet].to_i
    session[:initial_cards_are_dealt] = false
    redirect '/game'
  end
end

get '/game/summary' do
  erb :summary
end

get '/game' do
  session[:turn] = session[:player_name]
  
  if session[:initial_cards_are_dealt] == false
    values = ['2','3','4','5','6','7','8','9','10','J','Q','K','A']
    suits = ['H','D','S','C']
    session[:deck] = suits.product(values).shuffle!
    
    session[:dealer_cards] = []
    session[:player_cards] = []
    2.times {session[:dealer_cards] << session[:deck].pop}
    2.times {session[:player_cards] << session[:deck].pop}
    session[:initial_cards_are_dealt] = true
  end
  
  if blackjack?(player_total)
    reveal_winner_and_prompt_another_round
    process_bet
  end
  erb :game
end

get '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  if blackjack?(player_total) || bust?(player_total)
    reveal_winner_and_prompt_another_round
    process_bet
  end
  erb :game
end

get '/game/player/stay' do
  @info = "#{session[:player_name]} has chosen to stay with #{calculate_total(session[:player_cards])}!"
  @show_hit_or_stay_buttons = false
  @show_dealers_hand_button = true
  erb :game
end

get '/game/dealer/show_hand' do
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false
  @show_dealers_hand_button = false
  if dealer_hit_minimum?
    reveal_winner_and_prompt_another_round
    process_bet
  else
    @show_dealers_next_card_button = true
  end  
  erb :game
end

get '/game/dealer/play' do
  @show_hit_or_stay_buttons = false
  @show_dealers_next_card_button = false
  if dealer_hit_minimum?
    reveal_winner_and_prompt_another_round
    process_bet
  else
    session[:dealer_cards] << session[:deck].pop
    @show_dealers_next_card_button = true
    if dealer_hit_minimum?
      reveal_winner_and_prompt_another_round
      process_bet
    end
  end
  erb :game
end

get '/game/player/play_again' do
  session[:initial_cards_are_dealt] = false
  redirect '/bet'
end

get "/goodbye" do
  erb :goodbye
end