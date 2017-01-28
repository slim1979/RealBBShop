# encoding: cp866

require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'

def new_user

	new_user = File.open "users_list.txt","a"
	new_user.write "Клиент #{@new_user_name} записан на #{@new_user_datetime}. Телефон для связи #{@new_user_phone}. \n"
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

before '/secure/*' do
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
	new_user
	erb "Уважаемый #{@new_user_name}, мы будем рады видеть Вас #{@new_user_datetime}!"
	

end

get '/login/form' do

		erb :login_form
  
end

post '/login/attempt' do

		@login = params[:username]
		@password = params[:user_password]
	
	if @login == 'admin' && @password == 'secret'
		session[:identity] = params[:username]
		erb :welcome
		#erb 'This is a secret place that only <%=session[:identity]%> has access to!'
	else
		@message = "Access denied"
		where_user_came_from = session[:previous_url] || '/'
		redirect to where_user_came_from
	end   
   
end

get '/logout' do
  session.delete(:identity)
  erb "<div class='alert alert-message'>Logged out</div>"
end

get '/secure/place' do
  erb 'This is a secret place that only <%=session[:identity]%> has access to!'
end
