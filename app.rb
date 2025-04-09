require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require 'sinatra/flash'
enable :sessions
require_relative './model.rb'
set :max_content_length, 10 * 1024 * 1024 # 10 MB

#lägg till dynamiska routes
#Fråga om redirect är okej?

##
# Displays the admin page.
#
# @return [String] Rendered admin page.
get ('/admin') do
    load_admin_page()
    slim(:"admin/admin")
end

##
# Displays the admin cars page.
#
# @return [String] Rendered admin cars page.
get ('/admin/cars') do
    load_all_cars()
    slim(:"admin/cars")

end

##
# Displays the admin create car page.
#
# @return [String] Rendered admin create car page.
get ('/admin/create') do
    slim(:"admin/create")
end

##
# Handles the creation of a new car.
#
# @return [void] Redirects to the admin cars page.
post ('/create_car') do
    
    @filename = params["image_name"][:filename]
    @file = params["image_name"][:tempfile]

    create_car([params["name"], params["manufacturer"], @filename, params["production_year"].to_i, params["mileage"].to_i, params["class"].to_i, params["purchase_price"].to_i, params["sell_price"].to_i, params["horsepower"], params["window_tint"], params["exhaust_power"], params["sound_system"]])
    redirect("/admin/cars")
end

##
# Displays a specific admin user page.
#
# @param [String] id The ID of the user.
# @return [String] Rendered admin user page.
get ('/admin/:id') do
    load_user_page(params["id"])
    slim(:"admin/user")
end

##
# Deletes a user.
#
# @return [void] Redirects to the appropriate page after deletion.
post ('/delete_user') do
    redirect(delete_user(params["id"].to_i))
end

##
# Displays the login page.
#
# @return [String] Rendered login page.
get ('/') do
    slim(:"user/login")
end

##
# Logs out the current user.
#
# @return [void] Redirects to the login page with a logout notice.
get ('/logout') do
    session[:user_id] = nil
    session[:admin] = false
    flash[:notice] = "You have been logged out!"
    redirect("/")
end

##
# Displays the login page.
#
# @return [String] Rendered login page.
get ('/login') do
    slim(:"user/login")
end

##
# Handles user login.
#
# @return [void] Redirects to the appropriate page after login.
post ('/login_user') do
    redirect((login_user(params["username"], params["password"])))
end

##
# Displays the signup page.
#
# @return [String] Rendered signup page.
get ('/signup') do
    slim(:"user/register")
end

##
# Handles user registration.
#
# @return [void] Redirects to the appropriate page after registration.
post ('/register') do
    redirect(register_new_user(params["username"], params["password"]))
end

##
# Displays the market page.
#
# @return [String] Rendered market page.
get ('/market') do
    load_market(session[:user_id]) 
    slim(:market)
end

##
# Displays the garage page.
#
# @return [void] Redirects to login if the user is not logged in, otherwise renders the garage page.
get ('/garage') do 
    if load_garage(session[:user_id]) == "/login"
        flash[:notice] = "You need to be logged in to access this page!"
        redirect("/login")
    end
    slim(:"garage/garage")
end

##
# Handles car purchase.
#
# @return [void] Redirects to the appropriate page after purchase.
post ('/purchase') do
    redirect(purchase_car(params["id"].to_i, params["purchase_price"].to_i, session[:user_id]))
end

##
# Handles car selling.
#
# @return [void] Redirects to the appropriate page after selling.
post ('/sell') do
    if params["user_id"].nil?
        redirect(sell_car(params["id"].to_i, session[:user_id]))
    else
        redirect(sell_car(params["id"].to_i, params["user_id"]))
    end
end

##
# Displays the car modification page.
#
# @return [String] Rendered car modification page.
get ('/modify') do
    modify_car(params["id"].to_i, session[:user_id])
    slim(:"garage/modify")
end

##
# Handles part installation for a car.
#
# @return [void] Redirects to the appropriate page after part installation.
post ('/part_swap') do
    redirect(install_parts(params["id"].to_i, params["part_value"].to_i, params["part"], session[:user_id]))
end
