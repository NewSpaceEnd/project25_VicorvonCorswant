require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
enable :sessions



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
    password_confirm = params["password_confirm"]
    if password == password_confirm
        password_digest = BCrypt::Password.create(password)
        db = SQLite3::Database.new("db/database.db")
        db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [username, password_digest])
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
    @cars = session[:cars]
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
    car_id = params["id"].to_i
    p car_id
    db = SQLite3::Database.new("db/database.db")
    db.execute("UPDATE cars SET user_id = 1 WHERE id = ?", [car_id])
    redirect('/garage')
end