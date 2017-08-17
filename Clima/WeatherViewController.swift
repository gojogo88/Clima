//
//  ViewController.swift
//  WeatherApp
//
//  Created by Angela Yu on 23/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON

class WeatherViewController: UIViewController, CLLocationManagerDelegate, ChangeCityDelegate {
    
    //Constants
    let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
    let APP_ID = "e72ca729af228beabd5d20e3b7749713"
    

    //TODO: Declare instance variables here
    let locationManager = CLLocationManager()  //creates an object of CLLocaitonManager (to get the gps coordinates)
    let weatherDataModel = WeatherDataModel()  //creates an object of the WeatherDataModel
    
    
    //Pre-linked IBOutlets
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var mySwitch: UISwitch!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        //TODO:Set up the location manager here.
        locationManager.delegate = self  //in order to use locationManager and all its capabilities, we need to make WeatherViewController a delegate of locationManager
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters  //always specify accuracy if using location
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()  //to look for gps in the background
        
    }
    
    
    
    //MARK: - Networking (makes the http request to openweather)
    /***************************************************************/
    
    //Write the getWeatherData method here:
    func getWeatherData(url: String, parameters: [String: String]) {
        
        //Alamofire block of code to make a get request...
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
         
            response in
            if response.result.isSuccess {
                print("Success. Got the weather data")
                
                let weatherJSON: JSON = JSON(response.result.value!)  //force unwrap is ok here bec we are already checking if the result is a succes (there is data)
            
                self.updateWeatherData(json: weatherJSON)
                
            } else {
                
                print(response.result.error as Any)
                self.cityLabel.text = "Connection issues"
            }
        }
        
    }
    
    
    //MARK: - JSON Parsing
    /***************************************************************/
   
    
    //Write the updateWeatherData method here:
    func updateWeatherData(json: JSON) {
        
        if let tempResult = json["main"]["temp"].double { //location of temp in the json data.  .double changes the result to a double.  we use if let bec the data the we get might be an error message and not contain the data we need.
        
            weatherDataModel.temperature = Int(tempResult - 273.15) //to convert it to celcius.
            weatherDataModel.city = json["name"].stringValue   //converts the value into a string.
            weatherDataModel.condition = json["weather"][0]["id"].intValue
        
            weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition: weatherDataModel.condition)
        
            updateUIWithWeatherData()
        } else {
            
            cityLabel.text = "Weather Unavailable"
        }
    }

    
    
    
    //MARK: - UI Updates
    /***************************************************************/
    
    
    //Write the updateUIWithWeatherData method here:
    func updateUIWithWeatherData() {
        
        cityLabel.text = weatherDataModel.city
        
        if mySwitch.isOn {
        
            temperatureLabel.text = "\(weatherDataModel.temperature)°C"
        
        } else {
            
            let ftemp = Int(Double(weatherDataModel.temperature) + 273.15)
            temperatureLabel.text = "\(ftemp)°F"
        }
        weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
    }
    
    
    
    
    
    //MARK: - Location Manager Delegate Methods
    /***************************************************************/
    
    
    //Write the didUpdateLocations method here (This method gets activated once the .startUpdatingLocation gets the gps):
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations[locations.count - 1]  //the last entry in the locations array is the most accurate 
        if location.horizontalAccuracy > 0 {
        //This means we got a valid result and we should stop the updatingLocation
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil  //stops our func from receiving messages from locationManager when it is doing .stopUpdatingLocation(). prevents getting multiple data before it fully stops so we only get it once.
            
            print("longitude = \(location.coordinate.longitude), latitiude = \(location.coordinate.latitude)")
            
            let latitude = String(location.coordinate.latitude)   //we need to use string to call the http
            let longitude = String(location.coordinate.longitude)
            
            let params = ["lat" : latitude, "lon" : longitude, "appid" : APP_ID]
            //these are the values required by openweather to get the weather info
            
            getWeatherData(url: WEATHER_URL, parameters: params)
        }
    }
    
    
    //Write the didFailWithError method here:
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
        cityLabel.text = "Location unavailable"
    }
    
    

    
    //MARK: - Change City Delegate methods
    /***************************************************************/
    
    
    //Write the userEnteredANewCityName Delegate method here:
    func userEnteredANewCityName(city: String) {
        let params: [String : String] = ["q" : city, "appid" : APP_ID]  //using q bec that is what openweather is requiring (see openweather's documentation on how to get the weather by city name)
        getWeatherData(url: WEATHER_URL, parameters: params)
    }

    
    //Write the PrepareForSegue Method here
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "changeCityName" {   //changeCityName is the identifier name of the segue
            
            let destinationVC = segue.destination as! ChangeCityViewController
            
            destinationVC.delegate = self
        }
    }
    
    
    //MARK: - Toggles the temperature from Celcius to Fahrenheit
    /***************************************************************/
    
    @IBAction func onOffSwtich(_ sender: Any) {
        if mySwitch.isOn {
            let ftemp = Int(Double(weatherDataModel.temperature) + 273.15)
            temperatureLabel.text = "\(ftemp)°F"
            mySwitch.setOn(false, animated:true)
        } else {
            temperatureLabel.text = "\(weatherDataModel.temperature)°C"
            mySwitch.setOn(true, animated:true)
        }
    }
    

}




