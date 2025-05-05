#Skriv alla databas funktioner här som ska användas i controllern

##
# Registers a new user in the database.
#
# @param [String] username The username of the new user.
# @param [String] password The password of the new user.
# @return [String] Redirect path after registration.
def register_new_user(username, password)   

    db = SQLite3::Database.new("db/website.db")
    db.results_as_hash = true
    password_confirm = params["password_confirm"]
    if password == password_confirm
        password_digest = BCrypt::Password.create(password)
        db = SQLite3::Database.new("db/database.db")
        db.execute("INSERT INTO users (username, password, money) VALUES (?, ?, ?)", [username, password_digest, 1000])
        flash[:notice] = "Account successfully created!"
        return "/login"
    else
        flash[:notice] = "Opps! Something went wrong, please try again!"
        return "/signup"
    end
end

##
# Logs in a user by verifying their credentials.
#
# @param [String] username The username of the user.
# @param [String] password The password of the user.
# @return [String] Redirect path after login.
def login_user(username, password)
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    results = db.execute("SELECT * FROM users WHERE username = ?", [username])
    hashed_password = results[0]["password"]
    if !results.nil?
        if BCrypt::Password.new(hashed_password) == password
            session[:user_id] = results[0]["id"]
            p results[0]["access_level"]
            if results[0]["access_level"] == 1
                session[:admin] = true
            end
            flash[:notice] = "Welcome back! #{username}"
            return "/garage"
        else
            flash[:notice] = "Opps! Something went wrong, please try again!"
            return "/login"
        end
    else
        flash[:notice] = "Opps! Something went wrong, please try again!"
        return "/login" 
    end
end

##
# Loads the market data for the current user.
#
# @param [Integer] user_id The ID of the user.
# @return [void]
def load_market(user_id)
    
    #Loads the current market
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    results = db.execute("SELECT * FROM cars WHERE user_id = 0")
    session[:cars] = results
    #Loads the users money
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    results = db.execute("SELECT money FROM users WHERE id = ?", [user_id])
    session[:user] = results
    @cars = session[:cars]
    @user = session[:user]
end

##
# Loads the garage data for the current user.
#
# @param [Integer] user_id The ID of the user.
# @return [String, nil] Redirect path if the user is not logged in, otherwise nil.
def load_garage(user_id)
    if user_id.nil?
        return "/login"
    end
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    results = db.execute("SELECT * FROM cars WHERE user_id = ?", [user_id])
    session[:garage] = results
    @garage = session[:garage]
end

##
# Handles the purchase of a car by a user.
#
# @param [Integer] car_id The ID of the car to purchase.
# @param [Integer] purchase_price The price of the car.
# @param [Integer] user_id The ID of the user purchasing the car.
# @return [String] Redirect path after purchase.
def purchase_car(car_id, purchase_price, user_id)
    if user_id.nil?
        flash[:notice] = "You need to be logged in to purchase a car!"
        return "/login"
    end
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    results = db.execute("SELECT money FROM users WHERE id = ?", [user_id])
    if results[0]["money"] >= purchase_price
        db = SQLite3::Database.new("db/database.db")
    else
        flash[:notice] = "You don't have enough money to purchase this car!"
        return "/market"
    end
end
##
# Loads the data for modifying a specific car.
#
# @param [Integer] car_id The ID of the car to modify.
# @param [Integer] user_id The ID of the user modifying the car.
# @return [void]
def modify_car(car_id, user_id)
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    results = db.execute("SELECT * FROM cars WHERE id = ?", [car_id])
    user = db.execute("SELECT money FROM users WHERE id = ?", [user_id])
    @car = results[0]
    @user = user[0]
end

##
# Installs a part on a car and updates its attributes.
#
# @param [Integer] car_id The ID of the car.
# @param [Integer] part_value The value of the part to install.
# @param [String] part_name The name of the part to install (e.g., "horsepower").
# @param [Integer] user_id The ID of the user installing the part.
# @return [String] Redirect path after part installation.
def install_parts(car_id, part_value, part_name, user_id)
    if part_name == "horsepower"
        times_value = 100
    elsif part_name == "window_tint"
        times_value = 10
    elsif part_name == "exhaust_power"
        times_value = 100
    elsif part_name == "sound_system"
        times_value = 50
    end
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    user = db.execute("SELECT money FROM users WHERE id = ?", [user_id])    
    if user[0]["money"] >= part_value * times_value
        money_left = (user[0]["money"].to_i - part_value * times_value).truncate(2)
        db.execute("UPDATE users SET money = ? WHERE id = ?", [money_left, user_id])
        current_power = db.execute("SELECT #{part_name} FROM cars WHERE id = ?", [car_id])
        new_value = current_power[0]["#{part_name}"].to_i + part_value
        db.execute("UPDATE cars SET #{part_name} = ? WHERE id = ?", [new_value, car_id])

        sale_price = db.execute("SELECT sell_price FROM cars WHERE id = ?", [car_id])
        new_sale_price = (((part_value * times_value) * 1.2) + sale_price[0]["sell_price"]).truncate(2)
        db.execute("UPDATE cars SET sell_price = ? WHERE id = ?", [new_sale_price, car_id])
        flash[:notice] = "Part successfully installed!"
        return "/garage"
    else
        flash[:notice] = "You don't have enough money to install some parts!"
        return "/garage"
    end
end

##
# Loads the admin page data.
#
# @return [void]
def load_admin_page()
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    results_users = db.execute("SELECT * FROM users")
    session[:users] = results_users
    @users = session[:users]
end

##
# Loads the data for a specific user page.
#
# @param [Integer] user_id The ID of the user.
# @return [void]
def load_user_page(user_id)
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    p results_cars = db.execute("SELECT * FROM cars WHERE user_id = ?", [user_id])
    results_users = db.execute("SELECT * FROM users WHERE id = ?", [user_id])
    session[:users] = results_users
    session[:cars] = results_cars
    @cars = session[:cars]
    @users = session[:users]
end

##
# Deletes a user and updates related data.
#
# @param [Integer] user_id The ID of the user to delete.
# @return [String] Redirect path after deletion.
def delete_user(user_id)
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    db.execute("DELETE FROM users WHERE id = ?", [user_id])
    db.execute("UPDATE cars SET user_id = 0 WHERE user_id = ?", [user_id])
    flash[:notice] = "User successfully deleted!"
    return "/admin"
end

##
# Loads all cars and their associated user data.
#
# @return [void]
def load_all_cars()
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    results_cars = db.execute("
        SELECT * 
        FROM cars 
        INNER JOIN users 
        ON cars.user_id = users.id
    ")
    @cars = results_cars
end

##
# Validates form input.
#
# @param [Object] input The input to validate.
# @param [String] check_for The type of validation to perform ("Text" or "Integer").
# @return [Boolean, String] True if valid, otherwise a redirect path.
#def check_form(input, check_for)
#    if input.nil?
#        flash[:notice] = "Opps! Something went wrong, please try again!"
#        return "/admin/create_cars"
#    end
#    if check_for == "Text"
#        if input.type != "".type
#            flash[:notice] = "Opps! Something went wrong, please try again!"
#            return "/admin/create_cars"
#        elsif input.type != 0.type
#            flash[:notice] = "Opps! Something went wrong, please try again!"
#            return "/admin/create_cars"
#        end
#    end
#    return true
#end

##
# Creates a new car in the database.
#
# @param [Array] array The array of car attributes.
# @return [String] Redirect path after car creation.
def create_car(name, manufacturer, image_name, file, production_year, mileage, class_type, purchase_price, sell_price, horsepower, window_tint, exhaust_power, sound_system)
    # Ensure the file is saved to the public/img folder
    File.open("public/img/#{image_name}", 'wb') do |f|
        f.write(file.read)
    end

    # Log success for debugging
    puts "File saved successfully to public/img/#{image_name}"

    p "Allt gick bra inget paja :3"
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    db.execute("INSERT INTO cars (user_id, name, manufacturer, production_year, mileage, class, img, purchase_price, sell_price, horsepower, window_tint, exhaust_power, sound_system) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", [0, name, manufacturer, production_year, mileage, class_type, image_name, purchase_price, sell_price, horsepower, window_tint, exhaust_power, sound_system])
    flash[:notice] = "Car successfully created!"
    return "/admin/cars"

end 

##
# Enforces cooldown logic for user actions.
#
# @param [Hash] session The session hash containing user data.
# @return [Boolean] True if cooldown is enforced, otherwise false.
def enforce_cooldown(last_time)
    if last_time.nil?
        #p "First time, you can do this action"
        return true
    end
    current_time = Time.now.to_i
    if current_time.to_f - last_time.to_f >= 0.001
        #p "BAMSE"
        return true
    else
        #p "Cooldown not passed, you can't do this action"
        flash[:notice] = "Du är för snabb, vänta lite!"
        return false
    end
end

def check_if_owned(car_id)
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true

    results = db.execute("SELECT * FROM cars WHERE id = ?", [car_id])
    if results.empty?
        return false
    else
        p results[0]["user_id"]
        return results[0]["user_id"]
    end
end