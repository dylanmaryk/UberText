require 'rubygems'
require "bundler/setup"
require "mysql2"

db = Mysql2::Client.new(:host => "YOUR_HOST", :username => "YOUR_USERNAME", :password => "YOUR_PASSWORD", :database => "YOUR_DATABASE") # Add your own MySQL server details
db.query("DROP TABLE IF EXISTS UberText_Numbers")
db.query("CREATE TABLE UberText_Numbers(Number VARCHAR(200) PRIMARY KEY NOT NULL, Bearer VARCHAR(200), RequestID VARCHAR(200), DateTime TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL)")