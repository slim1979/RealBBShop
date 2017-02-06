require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

def get_db

	db = SQLite3::Database.new 'BarberShop.db'	
	db.results_as_hash = true
	return db
end

configure do

  enable :sessions 
  
  db = get_db
  
	#каждый раз происходит проверка существует ли таблица clients в базе данных...
	#если нет, то создается 
	db.execute 'CREATE TABLE IF NOT EXISTS
		"clients"
		(
			id        INTEGER  PRIMARY KEY AUTOINCREMENT,
			Name      VARCHAR,
			Phone     STRING,
			DateStamp DATETIME,
			Barber    VARCHAR
		)'
		
	db.execute 'CREATE TABLE IF NOT EXISTS
		"barbers" 
		(
			id        INTEGER  PRIMARY KEY AUTOINCREMENT,
			Name      VARCHAR			
		)';			
	
end



def new_user	
	
	db = get_db		
	#этот закомментированный способ добавления данных является небезопасным
	#с точки зрения SQL Injections. По этой причине заменен на приведенный ниже.
	# db.execute "INSERT INTO 
	# clients (Name, Phone, DateStamp, Barber) 
	# VALUES ('#{@new_user_name}', '#{@new_user_phone}','#{@new_user_datetime}','#{@barber}')"
	
	db.execute 'INSERT INTO 
				clients (Name, Phone, DateStamp, Barber) 
				VALUES (? , ? , ? , ? )', [@new_user_name, @new_user_phone, @new_user_datetime, @barber_for_user]
				
	db.close
end

def new_barber

	db = get_db
	db.execute 'INSERT INTO 
				barbers (Name)
				VALUES (? )', [@new_barber]
	db.close
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
	db = get_db
	@barbers_list = db.execute 'select * from barbers'
	erb :visit
end

post '/visit' do

	db = get_db
	@barbers_list = db.execute 'select * from barbers'
	
	@new_user_name = params[:new_user_name]
	@new_user_phone = params[:new_user_phone]
	@new_user_datetime = params[:new_user_datetime]
	@barber_for_user = params[:barber]
	
	#======код для обработки пустых строк при записи.
		#если посетитель нажимает сабмит при незаполненных полях формы на /visit,		
		hh ={   
				:new_user_name => 'Введите Ваше имя',
				:new_user_phone => 'Введите Ваш номер телефона',
				:new_user_datetime => 'Введите дату и время посещения',
				:barber => 'Выберите специалиста'
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

post '/cabinet' do

	#******** проверка добавляемого имени парикмахера на уникальность *********
	db = get_db
	@uniq_barber_name = db.execute 'select name from barbers'
	
	@new_barber=params[:new_barber]
	@new_barber.strip!

	#если admin вводит уже существующее имя, выводится ошибка.		
		@uniq_barber_name.each do |value|
			if value['Name'] == @new_barber
				@error = 'Такой сотрудник уже существует. Введите другое имя...'
				return erb :cabinet
			end
		end
	#========конец кода обработки ошибки заполнения полей формы записи нового парикмахера.========
	
	#**********код для обработки пустых строк при записи.************************
	#если посетитель нажимает сабмит при незаполненных полях формы на /visit,		
		hh ={   				
				:new_barber => 'Введите имя специалиста'
			}
		#то этот код проверяет, какие строки незаполнены 
		#и выдает ошибку, равную значению для каждого поля.
		hh.each do |key, value|
			if params[key] =="" || params[key] ==" "
				@error = hh[key]
				return erb :cabinet
				
			end
		end
	#========конец кода обработки ошибки заполнения полей формы записи.	==============
	
	new_barber
	erb "Парикмахер #{@new_barber} добавлен"
				
end

get '/showusers' do		
 
	db = get_db
	
	@results = db.execute 'select * from clients'
	
	erb :showusers
	
end

get '/logout' do

  session.delete(:identity) 
  redirect to '/'
  
end

