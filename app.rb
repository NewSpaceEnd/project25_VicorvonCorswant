require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require 'sinatra/flash'
enable :sessions
require_relative './model.rb'

#lägg till dynamiska routes
#Fråga om redirect är okej?

get ('/') do
    slim(:main_page)
end

get ('/logout') do
    session[:user_id] = nil
    flash[:notice] = "You have been logged out!"
    redirect("/")
end

get ('/login') do
    slim(:login)
end

post ('/login_user') do
    redirect((login_user(params["username"], params["password"])))
end

get ('/signup') do
    slim(:register)
end

post ('/register') do
    redirect(register_new_user(params["username"], params["password"]))
end

get ('/market') do
    load_market(session[:user_id]) 
    slim(:market)
end

get ('/garage') do #Inte så fin lösning
    if load_garage(session[:user_id]) == "/login"
        flash[:notice] = "You need to be logged in to access this page!"
        redirect("/login")
    end
    slim(:garage)
end

post ('/purchase') do
    redirect(purchase_car(params["id"].to_i, params["purchase_price"].to_i, session[:user_id]))
end

post ('/sell') do
    redirect(sell_car(params["id"].to_i, session[:user_id]))
end

get ('/modify') do
    modify_car(params["id"].to_i, session[:user_id])
    slim(:modify)
end

post ('/engine_swap') do
    redirect(install_parts(params["id"].to_i, params["horsepower"].to_i, "horsepower", session[:user_id], 250))
end

post ('/tint_swap') do
    redirect(install_parts(params["id"].to_i, params["tint"].to_i, "window_tint", user_isession[:user_id], 10))
end

post ('/exhaust_swap') do
    redirect(install_parts(params["id"].to_i, params["exhaust_power"].to_i, "exhaust_power", session[:user_id], 100))
end

post ('/sound_system_swap') do
    redirect(install_parts(params["id"].to_i, params["sound_system"].to_i, "sound_system", session[:user_id], 50))
end