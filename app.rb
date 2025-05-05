require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require 'sinatra/flash'
enable :sessions
require_relative './model.rb'
set :max_content_length, 10 * 1024 * 1024 # 10 MB

# Move @protected_routes outside the before block and make it a constant
PROTECTED_ROUTES = ["/admin", "/admin/cars", "/admin/new", "/admin/:id", "/", "/logout", "/login", "/signup", "/market", "/garage", "/modify", "/create_car", "/delete_user", "/login_user", "/register", "/purchase", "/sell", "/part_swap"]
#session[:last_time] = time.now.to_i

before do
    # Check if the current path is protected
    if PROTECTED_ROUTES.include?(request.path_info)
        # do not do shit
    else
        flash[:notice] = "Sluta fuska din skitunge"
        redirect("/login")
    end
end

##
# Displays the admin page.
#
# @return [String] Rendered admin page.
get ('/admin') do
    if enforce_cooldown(session[:last_time]) == false
        session[:last_time] = Time.now.to_i
        sleep(1)
        redirect("/")
    end
    session[:last_time] = Time.now.to_i
    load_admin_page()
    slim(:"admin/index")
end

##
# Displays the admin cars page.
#
# @return [String] Rendered admin cars page.
get ('/admin/cars') do
    if enforce_cooldown(session[:last_time]) == false
        session[:last_time] = Time.now.to_i
        sleep(1)
        redirect("/")
    end
    session[:last_time] = Time.now.to_i
    load_all_cars()
    slim(:"admin/cars")

end

##
# Displays the admin create car page.
#
# @return [String] Rendered admin create car page.
get ('/admin/new') do
    if enforce_cooldown(session[:last_time]) == false
        session[:last_time] = Time.now.to_i
        sleep(1)
        redirect("/")
    end
    session[:last_time] = Time.now.to_i
    slim(:"admin/new")
end

##
# Handles the creation of a new car.
#
# @return [void] Redirects to the admin cars page.
post ('/create_car') do 
    # Debugging: Print the params structure to verify the file upload
    #puts "Params: #{params.inspect}"
    # Ensure the file is being accessed correctly
    if params["image_name"] && params["image_name"][:tempfile]
        @filename = params["image_name"][:filename]# Get the filename from the params
        @file = params["image_name"][:tempfile]
        # Pass the tempfile to the create_car method
        redirect(create_car(params["name"], params["manufacturer"], @filename, @file, params["production_year"].to_i, params["mileage"].to_i, params["class"].to_i, params["purchase_price"].to_i, params["sell_price"].to_i, params["horsepower"], params["window_tint"], params["exhaust_power"], params["sound_system"]))
    else
        flash[:notice] = "File upload failed. Please try again."
        redirect("/admin/create")
    end
end

##
# Displays a specific admin user page.
#
# @param [String] id The ID of the user.
# @return [String] Rendered admin user page.
get ('/admin/:id') do
    if enforce_cooldown(session[:last_time]) == false
        session[:last_time] = Time.now.to_i
        sleep(1)
        redirect("/")
    end
    session[:last_time] = Time.now.to_i
    load_user_page(params["id"])
    slim(:"admin/show")
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
    if enforce_cooldown(session[:last_time]) == false
        session[:last_time] = Time.now.to_i
        sleep(1)
        
        redirect("/")
    end
    session[:last_time] = Time.now.to_i
    slim(:"user/index")
end

##
# Logs out the current user.
#
# @return [void] Redirects to the login page with a logout notice.
get ('/logout') do
    if enforce_cooldown(session[:last_time]) == false
        session[:last_time] = Time.now.to_i
        sleep(1)
        
        redirect("/")
    end
    session[:last_time] = Time.now.to_i
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
    if enforce_cooldown(session[:last_time]) == false
        session[:last_time] = Time.now.to_i
        sleep(1)
        redirect("/")
    end
    session[:last_time] = Time.now.to_i
    slim(:"user/index")
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
    if enforce_cooldown(session[:last_time]) == false
        session[:last_time] = Time.now.to_i
        sleep(1)
        
        redirect("/")
    end
    session[:last_time] = Time.now.to_i
    slim(:"user/new")
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
    if enforce_cooldown(session[:last_time]) == false
        session[:last_time] = Time.now.to_i
        sleep(1)
        
        redirect("/")
    end
    session[:last_time] = Time.now.to_i
    load_market(session[:user_id]) 
    slim(:market)
end

##
# Displays the garage page.
#
# @return [void] Redirects to login if the user is not logged in, otherwise renders the garage page.
get ('/garage') do 
    if enforce_cooldown(session[:last_time]) == false
        session[:last_time] = Time.now.to_i
        sleep(1)
        
        redirect("/")
    end
    session[:last_time] = Time.now.to_i
    if load_garage(session[:user_id]) == "/login"
        flash[:notice] = "You need to be logged in to access this page!"
        redirect("/login")
    end
    slim(:"garage/index")
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
    if enforce_cooldown(session[:last_time]) == false
        session[:last_time] = Time.now.to_i
        p "I sleep!"
        sleep(1)
        redirect("/")
    end
    session[:last_time] = Time.now.to_i
    if check_if_owned(params["id"].to_i) != session[:user_id]
        flash[:notice] = "You do not own this!"
        redirect ("/")
    end
    modify_car(params["id"].to_i, session[:user_id])
    slim(:"garage/edit")
end

##
# Handles part installation for a car.
#
# @return [void] Redirects to the appropriate page after part installation.
post ('/part_swap') do
    redirect(install_parts(params["id"].to_i, params["part_value"].to_i, params["part"], session[:user_id]))
end

