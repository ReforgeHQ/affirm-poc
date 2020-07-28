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
  def self.boot
    url = ENV['DATABASE_URL']
    ActiveRecord::Base.establish_connection url
  end

  def self.logger
    @@logger ||= Logger.new STDOUT # rubocop:disable Style/ClassVars
  end

  before do
    @title = 'Affirm POC'
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
        @message = "Radical! Please confirm your purchase! (Authorize Charge)"
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

  #TODO: Make this a POST
  get '/capture/:id' do
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
