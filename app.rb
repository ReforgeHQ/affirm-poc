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
    @items = Item.first 500
    erb :index
  end

  get '/item/:id' do
    @item = Item.find params[:id]
    @title += " - #{@item.name}"
    erb :item
  end

  post '/confirm' do
    checkout_token = '0VOL74HBH9CJVWH2' # TODO: REMOVE BEFORE COMMIT
    json affirm_client.post '/charges', checkout_token: checkout_token
    #  -d '{"checkout_token": "{checkout_token}","order_id": "{order_id}"}'
  end

  post '/cancel' do
    require 'pry'; binding.pry
  end

  def affirm_client
    @affirm_client ||= AffirmApi::Client.new
  end
end

App.boot
