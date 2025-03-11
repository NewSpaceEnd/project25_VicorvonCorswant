require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
enable :sessions
require_relative 'model.rb'


get ('/') do
    slim(:main_page)
end

get ('/login') do
    slim(:login)
end

get ('/signup') do
    slim(:register)
end

post ('/register') do
    db = SQLite3::Database.new("db/website.db")
    db.results_as_hash = true
    username = params["username"]
    password = params["password"]
    money = params["money"]
    password_confirm = params["password_confirm"]
    if password == password_confirm
        password_digest = BCrypt::Password.create(password)
        db = SQLite3::Database.new("db/database.db")
        db.execute("INSERT INTO users (username, password, money) VALUES (?, ?, ?)", [username, password_digest, 1000])
        redirect('/login')
    else
        redirect('/signup')
    end
end

get ('/load_market') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    results = db.execute("SELECT * FROM cars WHERE user_id = 0")
    session[:cars] = results
    redirect('/market')
end

get ('/market') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    results = db.execute("SELECT money FROM users WHERE id = 1")
    session[:user] = results
    @cars = session[:cars]
    @user = session[:user]
    #p @user
    slim(:market)
end

get ('/garage') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    results = db.execute("SELECT * FROM cars WHERE user_id = 1")
    session[:garage] = results
    @garage = session[:garage]
    slim(:garage)
end

post ('/purchase') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    results = db.execute("SELECT money FROM users WHERE id = 1")
    if results[0]["money"] >= params["purchase_price"].to_i
    car_id = params["id"].to_i
    db = SQLite3::Database.new("db/database.db")
    db.execute("UPDATE cars SET user_id = 1 WHERE id = ?", [car_id])
    money_left = results[0]["money"].to_i - params["purchase_price"].to_i
    db.execute("UPDATE users SET money = ? WHERE id = 1", [money_left])
    redirect('/garage')
    else
        redirect('/market')
    end
end

post ('/sell') do
    car_id = params["id"].to_i
    p car_id
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    db.execute("UPDATE cars SET user_id = 0 WHERE id = ?", [car_id])
    results = db.execute("SELECT money FROM users WHERE id = 1")
    money = db.execute("SELECT sell_price FROM cars WHERE id = ?", [car_id])
    money_left = results[0]["money"].to_i + money[0]["sell_price"].to_i
    db.execute("UPDATE users SET money = ? WHERE id = 1", [money_left])
    redirect('/garage')
end

get ('/modify') do
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    car_id = params["id"].to_i
    p car_id
    results = db.execute("SELECT * FROM cars WHERE id = ?", [car_id])
    user = db.execute("SELECT money FROM users WHERE id = 1")
    p results[0]
    @car = results[0]
    @user = user[0]
    slim(:modify)
end

post ('/engine_swap') do
    horsepower = params[:horsepower].to_i
    horse_price = horsepower * 250
    db = SQLite3::Database.new("db/database.db")
    db.results_as_hash = true
    car_id = params["id"].to_i
    user = db.execute("SELECT money FROM users WHERE id = 1")
    if user[0]["money"] >= horse_price
        money_left = user[0]["money"].to_i - horse_price
        db.execute("UPDATE users SET money = ? WHERE id = 1", [money_left])
        power = db.execute("SELECT horsepower FROM cars WHERE id = ?", [car_id])
        new_horsepower = power[0]["horsepower"].to_i + horsepower
        db.execute("UPDATE cars SET horsepower = ? WHERE id = ?", [new_horsepower, car_id])
        redirect('/garage')
    else
        redirect('/garage')
    end


end


