# frozen_string_literal: true

ENV['RACK_ENV'] ||= 'development'

require './lib/dotenv'
require 'bundler/setup'
Bundler.require 'default', ENV['RACK_ENV']

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
end

App.boot
