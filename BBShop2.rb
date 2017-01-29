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
    session[:identity] ? session[:identity] : 'Hello stranger'
  end
end

before '/welcome/*' do

	unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Wrong login/password. Sorry, you need to be logged in to enter ' + request.path
    halt erb(:login_form)
  end
end

get '/' do
	
	
	erb 'Мы открылись! Спешите <a href="/visit">записаться</a> на прием!'
end

get '/visit' do

	erb :visit

end

post '/visit' do
	
	@new_user_name = params[:new_user_name]
	@new_user_phone = params[:new_user_phone]
	@new_user_datetime = params[:new_user_datetime]
	@barber = params[:dzen]
	
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
		
		erb :welcome		
	else
		@message = " Доступ закрыт. Введите правильные логин и пароль."
		erb :login_form
		
	end      
end

get '/welcome' do

	new_user.read
end

get '/logout' do

  session.delete(:identity) 
  redirect to '/'
  
end

