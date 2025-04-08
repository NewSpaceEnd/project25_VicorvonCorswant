#Skriv alla databas funktioner här som ska användas i controllern

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
        db.execute("UPDATE cars SET user_id = ? WHERE id = ?", [user_id, car_id])
        car_sale_price = purchase_price * 0.6
        db.execute("UPDATE cars SET sell_price = ? WHERE id = ?", [car_sale_price, car_id])
        money_left = (results[0]["money"].to_i - purchase_price).truncate(2)
        db.execute("UPDATE users SET money = ? WHERE id = ?", [money_left, user_id])
        flash[:notice] = "Car successfully purchased!"
        return "/garage"
    else
        flash[:notice] = "You don't have enough money to purchase this car!"
        return "/market"
    end
end

def sell_car(car_id, user_id)
    p car_id
    p user_id
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    db.execute("UPDATE cars SET user_id = 0 WHERE id = ?", [car_id])
    sell_price = db.execute("SELECT sell_price FROM cars WHERE id = ?", [car_id])
    new_purchase_price = (sell_price[0]["sell_price"] * 1.2).truncate(0)
    db.execute("UPDATE cars SET purchase_price = ? WHERE id = ?", [new_purchase_price, car_id])
    results = db.execute("SELECT money FROM users WHERE id = ?", [user_id])
    money = db.execute("SELECT sell_price FROM cars WHERE id = ?", [car_id])
    money_left = results[0]["money"].to_i + money[0]["sell_price"].to_i
    db.execute("UPDATE users SET money = ? WHERE id = ?", [money_left, user_id])
    flash[:notice] = "Car successfully sold!"
    return "/garage"
end

def modify_car(car_id, user_id)
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    results = db.execute("SELECT * FROM cars WHERE id = ?", [car_id])
    user = db.execute("SELECT money FROM users WHERE id = ?", [user_id])
    @car = results[0]
    @user = user[0]
end

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

def load_admin_page()
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    results_users = db.execute("SELECT * FROM users")
    session[:users] = results_users
    @users = session[:users]
end

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

def delete_user(user_id)
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    db.execute("DELETE FROM users WHERE id = ?", [user_id])
    db.execute("UPDATE cars SET user_id = 0 WHERE user_id = ?", [user_id])
    flash[:notice] = "User successfully deleted!"
    return "/admin"
end

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