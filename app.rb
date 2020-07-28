# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'development'

require './lib/dotenv'
require 'bundler/setup'
Bundler.require 'default', ENV['RACK_ENV']
require 'sinatra/json'

require_relative 'lib/affirm_api/client'
require 'active_record'
require './models/item'

# The App
class App < Sinatra::Base
  def authorized?
    @auth ||= Rack::Auth::Basic::Request.new request.env
    @auth.provided? && @auth.basic? && @auth&.credentials == ['reforge', ENV.fetch('BASIC_AUTH_PASS')]
  end

  before do
    if ENV['RACK_ENV'] != 'development'
      if request.url.start_with?('http:')
        redirect request.url.gsub 'http', 'https'
      end

      unless authorized?
        response['WWW-Authenticate'] = %(Basic realm="Restricted Area")
        throw :halt, [401, "Login\n"]
      end
    end

    @merchant_base_url = "#{request.env['rack.url_scheme']}://#{request.host}:#{request.port}"
    @title = 'Affirm POC'
  end

  use Rack::Auth::Basic, 'Protected Area' do |username, password|
    username == 'reforge' && password == ENV.fetch('BASIC_AUTH_PASS')
  end

  def self.boot
    url = ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection url
  end

  def self.logger
    @@logger ||= Logger.new STDOUT # rubocop:disable Style/ClassVars
  end

  get '/' do
    erb :root
  end

  get '/items' do
    @items = Item.first 500
    @title += " / items"
    erb :items
  end

  get '/items/:id' do
    @item = Item.find params[:id]
    @title += " / items / #{@item.id}"
    erb :item
  end

  get '/checkout' do
    @title += " / checkout"
    erb :checkout
  end

  post '/order_confirmation' do
    if params['checkout_token']
      response = affirm_client.post '/charges', checkout_token: params['checkout_token']
      #  -d '{"checkout_token": "{checkout_token}","order_id": "{order_id}"}'
      if !response.key?('status_code')
        @item = Item.create data: { type: :charge_authorization, response: response }
        @message = "Radical! Please confirm your purchase! (Capture Charge)"
        erb :item
      else
        json response
      end
    else
      require 'pry'; binding.pry
    end
  end

  post '/cancel' do
    require 'pry'; binding.pry
  end

  post '/capture/:id' do
    @item = Item.find params['id']
    response = affirm_client.post "/charges/#{@item.data['response']['id']}/capture", {}
    if !response.key?('status_code')
      @item = Item.create data: { type: :charge_capture, response: response }
      @message = "Thank you. All set. (Charge Captured)"
      erb :item
    else
      json response
    end
  end

  def affirm_client
    @affirm_client ||= AffirmApi::Client.new
  end
end

App.boot
