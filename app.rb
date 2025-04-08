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

get ('/admin') do
    load_admin_page()
    slim(:"admin/admin")
end

get ('/admin/cars') do
    load_all_cars()
    slim(:"admin/cars")

end

get ('/admin/create') do
    slim(:"admin/create")
end

get ('/admin/:id') do
    load_user_page(params["id"])
    slim(:"admin/user")
end

post ('/delete_user') do
    redirect(delete_user(params["id"].to_i))
end



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

get ('/garage') do 
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
    if params["user_id"].nil?
        redirect(sell_car(params["id"].to_i, session[:user_id]))
    else
        redirect(sell_car(params["id"].to_i, params["user_id"]))
    end
end

get ('/modify') do
    modify_car(params["id"].to_i, session[:user_id])
    slim(:modify)
end

post ('/part_swap') do
    redirect(install_parts(params["id"].to_i, params["part_value"].to_i, params["part"], session[:user_id]))
end
