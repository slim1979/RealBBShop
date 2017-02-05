require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

configure do

  enable :sessions 
  
  @db = get_db
  
	#каждый раз происходит проверка существует ли таблица clients в базе данных...
	#если нет, то создается 
	@db.execute 'CREATE TABLE IF NOT EXISTS
		clients 
		(
			id        INTEGER  PRIMARY KEY AUTOINCREMENT,
			Name      VARCHAR,
			Phone     STRING,
			DateStamp DATETIME,
			Barber    VARCHAR
		)'		
end

def get_db

	return SQLite3::Database.new 'BarberShop.db'	
	
end

def new_user	
	
	#db = get_db		
	#этот закомментированный способ добавления данных является небезопасным
	#с точки зрения SQL Injections. По этой причине заменен на приведенный ниже.
	# db.execute "INSERT INTO 
	# clients (Name, Phone, DateStamp, Barber) 
	# VALUES ('#{@new_user_name}', '#{@new_user_phone}','#{@new_user_datetime}','#{@barber}')"
	
	@db.execute 'INSERT INTO 
				clients (Name, Phone, DateStamp, Barber) 
				VALUES (? , ? , ? , ? )', [@new_user_name, @new_user_phone, @new_user_datetime, @barber]
				
	@db.close
end

helpers do
  def username
    session[:identity] ? 'Вы вошли, как ' + session[:identity] : 'Войдите в кабинет' 
  end
end

before '/cabinet' do

	unless session[:identity]
		session[:previous_url] = request.path
		@error = 'Для входа в кабинет необходимо авторизоваться'
		halt erb(:login_form)
	end
	
end

get '/' do	
	erb :index
end

get '/visit' do
	erb :visit
end

post '/visit' do
	
	@new_user_name = params[:new_user_name]
	@new_user_phone = params[:new_user_phone]
	@new_user_datetime = params[:new_user_datetime]
	@barber = params[:barber]
	
	#======код для обработки пустых строк при записи.
		#если посетитель нажимает сабмит при незаполненных полях формы на /visit,		
		hh ={   :new_user_name => 'Введите имя',
				:new_user_phone => 'Введите номер телефона',
				:new_user_datetime => 'Введите дату и время посещения'
			}
		#то этот код проверяет, какие строки незаполнены 
		#и выдает ошибку, равную значению для каждого поля.
		hh.each do |key, value|
			if params[key] =="" 
				@error = hh[key]
				return erb :visit
			end
		end
	#========конец кода обработки ошибки заполнения полей формы записи.
	
	new_user
	erb "Уважаемый #{@new_user_name}, мы будем ждать Вас #{@new_user_datetime}!"

end

get '/login/form' do

		erb :login_form
  
end

post '/login/attempt' do

		@login = params[:username]
		@password = params[:user_password]
	
	if @login == 'admin' && @password == 'secret'	
		
		session[:identity] = params[:username]	
				
		new_user = File.open "./public/users_list.txt","r"
		new_user.read
		
		erb :cabinet		
	else
		@message = " Доступ закрыт. Введите правильные логин и пароль."
		erb :login_form
		
	end      
end

get '/cabinet' do

	erb :cabinet
	
end

get '/showusers' do		
 
	db = get_db
	db.results_as_hash = true
	@results = db.execute 'select * from clients'
	
	erb :showusers
	
end

get '/usersshow1' do
  
  erb "Hello World"
  
end

get '/logout' do

  session.delete(:identity) 
  redirect to '/'
  
end

