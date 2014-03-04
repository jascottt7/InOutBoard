require 'rubygems'
require 'sinatra'
require 'data_mapper'
require 'json'

helpers do
  def protected!
    return if authorized?
    headers['WWW-Authenticate'] = 'Basic realm="Restricted Area"'
    halt 401, "Not authorized\n"
  end

  def authorized?
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', 'admin']
  end
end


DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/in_out.db")
class Staff
  include DataMapper::Resource
  property :id, Serial
  property :fname, Text, :required => true
  property :lname, Text, :required => true
  property :status, Boolean, :required => true, :default => false
  property :comments, Text
  property :created, DateTime
end
DataMapper.finalize.auto_upgrade!

get '/?' do
  protected!
  @staff = Staff.all(:order => :created.desc)
  redirect '/new' if @staff.empty?
  erb :index
end

get '/new/?' do
  @title = "Add Staff"
  erb :new
end

post '/new/?' do
  Staff.create(:fname => params[:fname], :lname => params[:lname], :created => Time.now)
  redirect '/'
end

post '/status/?' do
  staff = Staff.first(:id => params[:id])
  staff.status = !staff.status
  staff.save
  content_type 'application/json'
  value = staff.status ? 'Out' : 'In'
  { :id => params[:id], :status => value }.to_json
end

get '/delete/:id/?' do
  @staff = Staff.first(:id => params[:id])
  erb :delete
end

post '/delete/:id/?' do
  if params.has_key?("ok")
    staff = Staff.first(:id => params[:id])
    staff.destroy
    redirect '/'
  else
    redirect '/'
  end
end
