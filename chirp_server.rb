$:.unshift(File.expand_path('lib', File.dirname(__FILE__)))

require 'sinatra/base'

require 'shield'

require 'slim'

require 'user.rb'
require 'chirp.rb'

class ChirpServer < Sinatra::Base
  enable :sessions

  helpers Shield::Helpers

  get '/' do
    slim :home
  end

  get '/signup' do
    slim :signup
  end

  post '/signup' do
    user = User.new :username => params[:username], :password => params[:password], :password_confirmation => params[:password_confirmation]
    
    if user.save
      login User, params[:username], params[:password]

      redirect '/channel'
    else
      errors = user.errors

      slim :signup, :locals => {:errors => errors}
    end
  end

  get '/login' do
    slim :login
  end

  post '/login' do
    if login User, params[:username], params[:password]
      redirect '/channel'
    else
      errors = 'Username and Password does not match.'

      slim :login, :locals => {:errors => errors}
    end
  end

  get '/logout' do
    logout User

    redirect '/'
  end

  get '/channel' do
    ensure_authenticated User

    slim :channel, :locals => {:user => authenticated(User)}
  end

  post '/chirp' do
    ensure_authenticated User

    user = authenticated User
    user.chirp params[:chirp]

    redirect '/channel'
  end

  get '/:username' do
    pass if params[:username] == 'favicon.ico'

    user = User.find(:username => params[:username]).first

    slim :user, :locals => {:user => user}
  end

  get '/:username/following' do
    user = User.find(:username => params[:username]).first

    slim :user_following, :locals => {:user => user}
  end

  get '/:username/followers' do
    user = User.find(:username => params[:username]).first

    slim :user_followers, :locals => {:user => user}
  end

  get '/:username/mentions' do
    user = User.find(:username => params[:username]).first

    slim :user_mentions, :locals => {:user => user}
  end

  run! if app_file == $0
end