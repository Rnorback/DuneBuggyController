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
        var state:String
        switch central.state {
        case .PoweredOn:
            keepScanning = true
            NSTimer.scheduledTimerWithTimeInterval(TIMER_SCAN_INTERVAL, target: self, selector: Selector("pauseScan"), userInfo: nil, repeats: false)
            centralManager.scanForPeripheralsWithServices([BlackWidowService], options: nil)
        default:
            state = "The state of the BLE Manager is unknown"
        }
    }
    
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        keepScanning = false
        blackWidow = peripheral
        blackWidow.delegate = self
        centralManager.connectPeripheral(blackWidow, options: nil)
    }
    
}
