require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'mysql2'
require 'uber_api'
require 'geocoder'
require 'twilio-ruby'

set :port, 8100
set :environment, :production
set :logging, false

get '/text' do # Ensure this matches the request URL you provide in your Twilio number's SMS & MMS settings
	body = params[:Body].split("/")
	number = params[:From]

	handleQuery(body, number)
end

post '/update' do # Ensure this matches the webhook URL you provide in your Uber app settings
	request.body.rewind
	requestBody = JSON.parse request.body.read
	requestID = requestBody["id"]
	requestStatus = requestBody["status"]

	number = getDB().query("SELECT Number FROM UberText_Numbers WHERE RequestID = '" + requestID + "'").first["Number"]

	if requestStatus == "processing"
		message = "Your Uber request is being processed."
	elsif requestStatus == "accepted"
		uberRequestDetails = getClient(number).request_status(requestID)
		uberRequestName = uberRequestDetails["driver"]["name"]
		uberRequestETA = String(uberRequestDetails["eta"])
		uberRequestLicense = uberRequestDetails["vehicle"]["license_plate"]

		p message = "Your Uber request has been accepted by " + uberRequestName + ". They will arrive at your location in " + uberRequestETA + " minutes with license place " + uberRequestLicense + "."
	else
		message = "A problem has occurred."
	end

	sendText(message, number)
end

def handleQuery(body, number)
	if body[0] == "Products" or body[0] == "products"
		p productNames = getProducts(body[1], number)

		if not productNames == ""
			sendText(productNames, number)
		else
			sendText("No Uber products available at this location.", number)
		end
	else
		productName = body[0]
		startAddress = body[1]
		endAddress = body[2]

		productID = getProductID(productName, startAddress, endAddress, number)

		if not productID == ""
			requestUber(productID, startAddress, endAddress, number)
		else
			sendText("Invalid Uber product name.", number)
		end
	end
end

def requestUber(productID, startAddress, endAddress, number)
	startCoord = Geocoder.coordinates(startAddress)
	endCoord = Geocoder.coordinates(endAddress)
	startLat = startCoord[0]
	startLong = startCoord[1]
	endLat = endCoord[0]
	endLong = endCoord[1]

	client = getClient(number)
	request = client.request(:product_id => productID, :start_latitude => startLat, :start_longitude => startLong, :end_latitude => endLat, :end_longitude => endLong)
	requestID = request["request_id"]

	getDB().query("UPDATE UberText_Numbers SET RequestID = '" + requestID + "' WHERE Number = '" + number + "'")

	sleep 10

	client.move_request(requestID, "accepted") # Temp force statuses
	# client.move_request(requestID, "arriving")
	# client.move_request(requestID, "in_progress")
	# client.move_request(requestID, "completed")
	# requestStatus = client.request_status(requestID)
	# requestStatus["status"]
end

def getProducts(startAddress, number)
	startCoord = Geocoder.coordinates(startAddress)
	startLat = startCoord[0]
	startLong = startCoord[1]

	products = getClient(number).products(startLat, startLong)
	productNamesArray = []

	products.each do |product|
		productNamesArray.push(product["display_name"])
	end

	productNamesArray.join(", ")
end

def getProductID(productName, startAddress, endAddress, number)
	startCoord = Geocoder.coordinates(startAddress)
	endCoord = Geocoder.coordinates(endAddress)
	startLat = startCoord[0]
	startLong = startCoord[1]
	endLat = endCoord[0]
	endLong = endCoord[1]

	products = getClient(number).products(startLat, startLong)
	productID = ""

	products.each do |product|
		if product["display_name"] == productName
			productID = product["product_id"]
		end
	end

	return productID
end

def getClient(number)
	bearer = getDB().query("SELECT Bearer FROM UberText_Numbers WHERE Number = '" + number + "'").first["Bearer"]

	Uber::Client.new(:server_token => 'YOUR_SERVER_TOKEN', :bearer_token => bearer, :sandbox => true) # Add your own Uber server token
end

def getDB
	Mysql2::Client.new(:host => 'YOUR_HOST', :username => 'YOUR_USERNAME', :password => 'YOUR_PASSWORD', :database => 'YOUR_DATABASE') # Add your own MySQL server details
end

def sendText(body, number)
	account_sid = "YOUR_ACCOUNT_SID" # Add your own Twilio account SID
	auth_token = "YOUR_AUTH_TOKEN" # Add your own Twilio auth token
	@client = Twilio::REST::Client.new account_sid, auth_token
	@client.account.messages.create(:body => body, :to => number, :from => '+YOUR_PHONE_NUMBER') #Add your own Twilio phone number
end
