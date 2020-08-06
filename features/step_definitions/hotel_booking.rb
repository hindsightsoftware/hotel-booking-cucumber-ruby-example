require 'cucumber'
require 'rest-client'
require 'json'
require 'test/unit/assertions'

World(Test::Unit::Assertions)

def auth_token
  body = {
    'username': 'admin',
    'password': 'password123'
  }
  response = RestClient.post 'http://localhost:8080/login', body.to_json
  parsed = JSON.parse response.to_str
  parsed['token']
end

Given('a user wants to make a booking with the following details') do |table|
  data = table.hashes
  row = data[0]

  @request_body = {
    firstname: row['firstname'],
    lastname: row['lastname'],
    totalprice: row['price'],
    depositpaid: row['paid'],
    bookingdates: {
      checkin: row['from'],
      checkout: row['to']
    },
    additionalneeds: row['needs']
  }
end

When('the booking is submitted by the user') do
  headers = {
    Authorization: 'Bearer ' + auth_token,
    content_type: :json,
    accept: :json
  }
  @response = RestClient.post 'http://localhost:8080/api/booking', @request_body.to_json, headers
end

Then('the booking is successfully stored') do
  assert_equal @response.code, 200
end

Then('shown to the user as stored') do
  parsed = JSON.parse @response.to_str
  assert_true parsed['id'] >= 1
end

Given('Hotel Booking has existing bookings') do
  body = {
    firstname: 'Rose',
    lastname: 'Boylu',
    totalprice: 10,
    depositpaid: 'true',
    bookingdates: {
      checkin: '2020-07-24',
      checkout: '2020-07-25'
    },
    additionalneeds: 'Nothing'
  }

  headers = {
    Authorization: 'Bearer ' + auth_token,
    content_type: :json,
    accept: :json
  }

  @response = RestClient.post 'http://localhost:8080/api/booking', body.to_json, headers
  parsed = JSON.parse @response.to_str
  assert_true parsed['id'] >= 1

  @last_booking_id = parsed['id']
end

When('a specific booking is requested by the user') do
  headers = {
    Authorization: 'Bearer ' + auth_token,
    content_type: :json,
    accept: :json
  }

  @response = RestClient.get "http://localhost:8080/api/booking/#{@last_booking_id}", headers
  assert_equal @response.code, 200
end

Then('the booking is shown') do
  parsed = JSON.parse @response.to_str
  assert_equal parsed['firstname'], 'Rose'
  assert_equal parsed['lastname'], 'Boylu'
  assert_equal parsed['totalprice'], 10
  assert_equal parsed['depositpaid'], true
  assert_equal parsed['bookingdates']['checkin'], '2020-07-24'
  assert_equal parsed['bookingdates']['checkout'], '2020-07-25'
  assert_equal parsed['additionalneeds'], 'Nothing'
end

When('a specific booking is updated by the user') do
  body = {
    firstname: 'Matus',
    lastname: 'Novak',
    totalprice: 30,
    depositpaid: 'true',
    bookingdates: {
      checkin: '2020-07-24',
      checkout: '2020-07-25'
    },
    additionalneeds: 'Nothing'
  }

  headers = {
    Authorization: 'Bearer ' + auth_token,
    content_type: :json,
    accept: :json
  }

  @response = RestClient.put "http://localhost:8080/api/booking/#{@last_booking_id}", body.to_json, headers
  assert_equal @response.code, 200
end

Then('the booking is shown to be updated') do
  parsed = JSON.parse @response.to_str
  assert_equal parsed['firstname'], 'Matus'
  assert_equal parsed['lastname'], 'Novak'
end

When('a specific booking is deleted by the user') do
  headers = {
    Authorization: 'Bearer ' + auth_token,
    content_type: :json,
    accept: :json
  }

  @response = RestClient.delete "http://localhost:8080/api/booking/#{@last_booking_id}", headers
  assert_equal @response.code, 200
end

Then('the booking is removed') do
  headers = {
    Authorization: 'Bearer ' + auth_token,
    content_type: :json,
    accept: :json
  }

  assert_raises RestClient::NotFound do
    @response = RestClient.get "http://localhost:8080/api/booking/#{@last_booking_id}", headers
  end
end
