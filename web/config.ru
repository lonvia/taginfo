require 'rubygems'
require 'sinatra'
require 'taginfo.rb'
 
set :run, false
set :environment, :production

run Taginfo
