//
//  DuneBuggyVC.swift
//  DuneBuggyController
//
//  Created by Rob Norback on 11/29/15.
//  Copyright © 2015 Norback Solutions, LLC. All rights reserved.
//

import UIKit
import CoreBluetooth

class DuneBuggyVC: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet var leftLabel: UILabel!
    @IBOutlet var leftSlider: UISlider!
    @IBOutlet var rightLabel: UILabel!
    @IBOutlet var rightSlider: UISlider!
    @IBOutlet var connectionImageView: UIImageView!
    
    var centralManager:CBCentralManager!
    var blackWidow:CBPeripheral!
    var keepScanning:Bool = true
    
    let TIMER_SCAN_INTERVAL = 2.0
    let TIMER_WAIT_INTERVAL = 10.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Rotate sliders to vertical
        leftSlider.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2 * 3))
        rightSlider.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2 * 3))
        
        // Set thumb image on slider
        leftSlider.setThumbImage(UIImage(named: "Bar"), forState: .Normal)
        rightSlider.setThumbImage(UIImage(named: "Bar"), forState: .Normal)
        
        // Add actions to sliders
        leftSlider.addTarget(self, action: Selector("sliderValueChanged:"), forControlEvents: .ValueChanged)
        rightSlider.addTarget(self, action: Selector("sliderValueChanged:"), forControlEvents: .ValueChanged)
        leftSlider.addTarget(self, action: Selector("sliderTouchUpInside:"), forControlEvents: .TouchUpInside)
        rightSlider.addTarget(self, action: Selector("sliderTouchUpInside:"), forControlEvents: .TouchUpInside)
    }
    
    //MARK: Press Handling
    
    @IBAction func connectButtonPressed(sender: AnyObject) {
        centralManager = CBCentralManager(delegate: self, queue: nil, options: nil)
    }
    
    func sliderTouchUpInside(sender:UISlider) {
        UIView.animateWithDuration(1.0, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 10, options: .CurveEaseInOut, animations: { () -> Void in
                sender.setValue(0, animated: true)
            }, completion: nil)
        
        
        
        if sender == leftSlider {
            leftLabel.text = "0"
        } else if sender == rightSlider {
            rightLabel.text = "0"
        }
        
    }
    
    func sliderValueChanged(sender:UISlider) {
        if sender == leftSlider {
            leftLabel.text = String(format: "%.0f", round(sender.value))
        } else if sender == rightSlider {
            rightLabel.text = String(format: "%.0f", round(sender.value))
        }
    }
    
    //MARK: Scanning
    
    func pauseScan() {
        NSTimer.scheduledTimerWithTimeInterval(TIMER_WAIT_INTERVAL, target: self, selector: Selector("resumeScan"), userInfo: nil, repeats: false)
        centralManager.stopScan()
    }
    
    func resumeScan() {
        if keepScanning {
            NSTimer.scheduledTimerWithTimeInterval(TIMER_SCAN_INTERVAL, target: self, selector: Selector("pauseScan"), userInfo: nil, repeats: false)
            centralManager.scanForPeripheralsWithServices([BlackWidowService], options: nil)
        }
    }
    
    //MARK: CBCentralManagerDelegate
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        var state:String = ""
        var showAlert:Bool = true
        
        switch central.state {
        case .Unsupported:
            state = "This device does not support Bluetooth Low Energy."
        case .Unauthorized:
            state = "This app is not authorized to use Bluetooth Low Energy."
        case .PoweredOff:
            state = "Bluetooth on this device is currently powered off."
        case .Resetting:
            state = "The BLE Manager is resetting; a state update is pending."
        case .PoweredOn:
            showAlert = false
            state = "Bluetooth LE is turned on and ready for communication."
            keepScanning = true
            NSTimer.scheduledTimerWithTimeInterval(TIMER_SCAN_INTERVAL, target: self, selector: Selector("pauseScan"), userInfo: nil, repeats: false)
            centralManager.scanForPeripheralsWithServices([BlackWidowService], options: nil)
        case .Unknown:
            state = "The state of the BLE Manager is unknown."
        }
        
        if showAlert {
            let ac = UIAlertController(title: "Central Manager State", message: state, preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
            ac.addAction(okAction)
            self.presentViewController(ac, animated: true, completion: nil)
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        if let name = peripheral.name {
            if name.containsString("Black Widow") {
                keepScanning = false
                blackWidow = peripheral
                blackWidow.delegate = self
                centralManager.connectPeripheral(blackWidow, options: nil)
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        connectionImageView.image = UIImage(named: "Bluetooth_Connected")
        peripheral.discoverServices([BlackWidowService])
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        // Connection failed
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        connectionImageView.image = UIImage(named: "Bluetooth_Disconnected")
        keepScanning = true
        self.resumeScan()
    }
    
    //MARK: CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        for service:CBService in peripheral.services! {
            if service.UUID == BlackWidowService {
                peripheral.discoverCharacteristics(nil, forService: service)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        
        for characteristic:CBCharacteristic in service.characteristics! {
            if characteristic.UUID == BlackWidowCharRead {
                blackWidow.setNotifyValue(true, forCharacteristic: characteristic)
            }
            
            if characteristic.UUID == BlackWidowCharWrite {
                print("Slider value: \(leftSlider.value)")
                var motorValue:UInt8 = UInt8(leftSlider.value)
                let motorBytes = NSData(bytes: &motorValue, length: sizeof(UInt8))
                blackWidow.writeValue(motorBytes, forCharacteristic: characteristic, type: .WithResponse)
            }
        }
        
        
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
    }
}
