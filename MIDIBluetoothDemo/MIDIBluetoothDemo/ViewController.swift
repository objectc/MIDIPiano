//
//  ViewController.swift
//  MIDIBluetoothDemo
//
//  Created by Christopher Fonseka on 23/09/2014.
//  Copyright (c) 2014 ROLI. All rights reserved.
//

import UIKit
import CoreAudioKit // At time of writing CoreAudioKit only works on iOS8 devices, not the simulator
import CoreMIDI

class ViewController: UIViewController  {

	var central		: CABTMIDICentralViewController
	var peripheral	: CABTMIDILocalPeripheralViewController
	var midi		: Midi
    var notePressed        : UInt8
	@IBOutlet weak var latencyLabel: UILabel!
	
	
	required init(coder aDecoder: NSCoder)
	{
		central = CABTMIDICentralViewController()
		peripheral = CABTMIDILocalPeripheralViewController()
		midi = Midi()
        notePressed = 0
		super.init(coder: aDecoder)!
	}
	
	override func viewDidAppear(_ animated: Bool)
	{
		self.latencyLabel.text = "Pending"
	}

	/*
		When "Central" button is pressed, the CABTMIDICentralViewController takes over
		to set up the current device as a Bluetooth Central device, over which MIDI can be recieved
	*/
	@IBAction func setUpCentral(_ sender: AnyObject)
	{
		self.navigationController?.pushViewController(central, animated: true)
	}
	
	/*
		When "Peripheral" button is pressed, the CABTMIDILocalPeripheralViewController takes over
		to set up the current device as a Bluetooth Peripher device, over which MIDI can be sent
	*/
	@IBAction func setUpPeripheral(_ sender: AnyObject)
	{
		self.navigationController?.pushViewController(peripheral, animated: true)
	}	

	
	/*
		When a note is pressed on the mysterious blue keyboard a note is sent, in addtion to a
		SYSEX message containing the current timestamp
	*/
	@IBAction func notePressed(_ sender: UIButton)
	{
		let note = sender.tag
		self.sendNoteOn(UInt8(note))
		
//		midi.sendTimestamp()
	}
	
	/*
		This when a note on the blue keyboard is unpressed, send note off
	*/
	@IBAction func noteUnPressed(_ sender: UIButton)
	{
		let note = sender.tag
		self.sendNoteOff(UInt8(note))
	}
	
    //音量调节
    @IBAction func velocityChangeAction(_ sender: Any) {
        let velocity = UInt8((sender as! UISlider).value)
        let note = UInt8(notePressed)
        let velocityChange = [0xa0,note,velocity]
        print(velocity)
        let size  = UInt32(MemoryLayout<UInt8>.size * 3)
        
        midi.sendBytes(velocityChange, size: size)
    }
    
    //发送音符start指令
	func sendNoteOn(_ noteNo : UInt8)
	{
        notePressed = noteNo
		let note      = noteNo
        //三个参数分别为start标记（0x90），音符，velocity
		let noteOn	  = [0x90, note, 127]
		
		let size  = UInt32(MemoryLayout<UInt8>.size * 3)
		midi.sendBytes(noteOn, size: size)
	}
	
	func sendNoteOff(_ noteNo : UInt8)
	{
		let note	= noteNo
        //三个参数分别为start标记（0x80），音符，velocity
		let noteOff	= [0x80, note, 0]
	
		let size	= UInt32(MemoryLayout<UInt8>.size * 3)
		midi.sendBytes(noteOff, size: size)
	}
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}


}

