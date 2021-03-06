require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'





def new_user	
	
	new_user = File.open "./public/users_list.txt","a"
	
	if @barber == "Не важно"	
		new_user.write "Клиент #{@new_user_name} записан на #{@new_user_datetime}. К любому специалисту. Телефон для связи #{@new_user_phone}. \n"
	else 
		new_user.write "Клиент #{@new_user_name} записан на #{@new_user_datetime} к специалисту #{@barber}. Телефон для связи #{@new_user_phone}. \n"
	end
	new_user.close

end


configure do
  enable :sessions
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
	
	hh ={   :new_user_name => 'Введите имя',
			:new_user_phone => 'Введите номер телефона',
			:new_user_datetime => 'Введите дату и время посещения'
		}
	hh.each do |key, value|
		if params[key] =="" 
			@error = hh[key]
			return erb :visit
		end
	end
	
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
get '/cabinet' do

	new_user.read
end

get '/logout' do

  session.delete(:identity) 
  redirect to '/'
  
end

