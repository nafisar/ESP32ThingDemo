//
//  ViewController.swift
//  ESP32ThingDemo
//  Uses CoreBlueTooth framework to turn the LED of ESP32 thing board on or off .
//
//  Created by Nafisa Rahman on 3/15/17.
//  LICENSE:-
//  The MIT License (MIT)
//  Copyright (c) 2016 Nafisa Rahman
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom
//  the Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall
//  be included in all copies or substantial portions of the
//  Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
//  OR OTHER DEALINGS IN THE SOFTWARE.
//


import UIKit
import CoreBluetooth

class ViewController: UIViewController,CBCentralManagerDelegate,
CBPeripheralDelegate {
    
    //MARK:- declarations
    var manager:CBCentralManager!
    var connectedPeripheral:CBPeripheral!
    var LEDCharacteristic:CBCharacteristic?
    
    @IBOutlet weak var LEDSwitch: UISwitch!
    
    let deviceName = "Spark32"
    let serviceUUID = CBUUID(string: "00FF")
    let charUUID = CBUUID(string: "FF01")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //MARK:- scan for devices
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
            
        case .poweredOn:
            print("powered on")
            central.scanForPeripherals(withServices: nil, options: nil)
            
        case .poweredOff:
            print("powered off")
            
        case .resetting:
            print("resetting")
            
        case .unauthorized:
            print("unauthorized")
            
        case .unknown:
            print("unknown")
            
        case .unsupported:
            print("unsupported")
        }
    }
    
    //MARK:- connect to a device
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        
        let device = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        
        
        if (device?.contains(deviceName)) != nil {
            
            self.manager.stopScan()
            self.connectedPeripheral = peripheral
            self.connectedPeripheral.delegate = self
            
            manager.connect(peripheral, options: nil)
            
        }
    }
    
    //MARK:- get services on devices
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        peripheral.discoverServices(nil)
        
    }
    
    //MARK:- get characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        guard let services = peripheral.services else {
            return
        }
        
        for service in services {
            
            peripheral.discoverCharacteristics(nil, for: service)
            
            if service.uuid == serviceUUID {
                
                peripheral.discoverCharacteristics(nil, for: service)
                
            }
        }
    }
    
    //MARK:- notification
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        guard let characteristics = service.characteristics else {
            return
        }
        
        for characteristic in characteristics {
            
            if characteristic.uuid == charUUID {
                
                LEDCharacteristic = characteristic
                
                peripheral.readValue(for: characteristic)
                
            }
            
        }
        
    }
    
    //MARK:- characteristic change
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        if characteristic.uuid == charUUID {
            
            if let data = characteristic.value {
                
                if data[0] == 1 {
                    
                    LEDSwitch.setOn(true, animated: true)
                }
                
            }
        }
    }
    
    
    
    //MARK:- disconnect
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK:- turn led on or off
    @IBAction func LEDSwitchChanged(_ sender: UISwitch) {
        
        if sender.isOn {
            
            sendSwitchValue(value: UInt8(1))
            
        }else {
            
            sendSwitchValue(value: UInt8(0))
            
        }
    }
    
    //MARK:- send switch value to peripheral
    func sendSwitchValue(value: UInt8){
        
        let data = Data(bytes: [value])
        
        guard let ledChar = LEDCharacteristic else {
            return
        }
        
        
        connectedPeripheral.writeValue(data, for: ledChar, type: .withResponse)
        
    }
    
}

