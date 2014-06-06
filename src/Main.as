package  
{
	import flash.events.ErrorEvent;
	import flash.events.TextEvent;
	import flash.events.TimerEvent;
	import flash.events.Event;
	import net.eriksjodin.arduino.Arduino;
	import net.eriksjodin.arduino.ArduinoWithServo;
	import net.eriksjodin.arduino.events.ArduinoEvent;
	import net.eriksjodin.arduino.events.ArduinoSysExEvent;

	/**
	 * ...
	 * @author Chanisco
	 */
	public class Main 
	{
		public var ball1:MovieClip = ball1;
		public var ball2:MovieClip = ball2;
		public var ball3:MovieClip = ball3;

		// store a digitalValue for edge/state change detection. 
		public var lastDigitalValue:int;

		// make a timer object that calls the timerEvent function 20 times a second (every 50ms)
		public var refreshTimer = new Timer(50);
		public var defaultPinConfig:Array = new Array(
			null,		// Pin 0   null (is RX)
			null,		// Pin 1   null (is TX)
			'digitalIn',  // Pin 2   digitalIn or digitalOut 
			'digitalIn',  // Pin 3   pwmOut or digitalIn or digitalOut 
			'digitalIn',  // Pin 4   digitalIn or digitalOut  
			'digitalIn',  // Pin 5   pwmOut or digitalIn or digitalOut 
			'digitalIn',  // Pin 6   pwmOut or digitalIn or digitalOut 
			'digitalIn',  // Pin 7   digitalIn or digitalOut  
			'digitalIn',  // Pin 8   digitalIn or digitalOut  
			'digitalIn',  // Pin 9   pwmOut or digitalIn or digitalOut or servo 
			'digitalIn',  // Pin 10  pwmOut or digitalIn or digitalOut or servo
			'digitalIn',  // Pin 11  pwmOut or digitalIn or digitalOut 
			'digitalIn',  // Pin 12  digitalIn or digitalOut 
			'digitalOut'  // Pin 13  digitalIn or digitalOut ( led connected )
		);

		public function Main() 
		{
			refreshTimer.addEventListener(TimerEvent.TIMER, onTick);
			a = new ArduinoWithServo("127.0.0.1", 5331);
			// listen for connection 
			a.addEventListener(Event.CONNECT,onSocketConnect); 
			a.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
						
			// listen for firmware (sent on startup)
			a.addEventListener(ArduinoEvent.FIRMWARE_VERSION, onReceiveFirmwareVersion);
		}
		// == SETUP AND INITIALIZE CONNECTION ( don't modify ) ==================================

		// triggered when there is an IO Error
		function errorHandler(errorEvent:IOErrorEvent):void 
		{   trace("- "+errorEvent.text);
			trace("- Did you start the Serproxy program ?");
		}

		// triggered when a serial socket connection has been established
		function onSocketConnect(e:Object):void 
		{	trace("- Connection with Serproxy established. Wait one moment.");
			
			// request the firmware version
			a.requestFirmwareVersion();	
		}

		function onReceiveFirmwareVersion(e:ArduinoEvent):void 
		{   trace("- Connection with Arduino - Firmata version: " + String(e.value)); 		
			trace("- Set default pin configuration.");

			// set Pinmodes by the default array. 
			for(var i:int = 2; i<defaultPinConfig.length; i++)
			{ // set digital output pins
			  if(defaultPinConfig[i] == "digitalOut") a.setPinMode(i, Arduino.OUTPUT);
			  // set digital input pins
			  if(defaultPinConfig[i] == "digitalIn")  a.setPinMode(i, Arduino.INPUT);
			  // set pwm output pins
			  if(defaultPinConfig[i] ==  "pwmOut")    a.setPinMode(i, Arduino.PWM);
			  // set servo output pins
			  if(defaultPinConfig[i] ==  "servo")    
			  { a.setupServo(i, 0);
				// write set start position to 0 otherwise it turns directly to 90 degrees.
				a.writeAnalogPin(i, 0);
			  }
			}	
			
			if(isMega == true)
			{	// set digitalpins on the mega as output
				// you can modify this or the default array to use inputs on the Mega.
				for(i = 22; i<53; i++)
				{	a.setPinMode(i, Arduino.OUTPUT);
				}
			}
			
			// you have to turn on reporting for every ANALOG pin individualy. 
			// 6 analog inputs on the normal Arduino, 16 analog inputs on the Mega
			
			var maxAnaloginputs:int;
			
			if(isMega) maxAnaloginputs = 16;
			else	   maxAnaloginputs = 6;
			
			for(var j:int = 0; j<maxAnaloginputs; j++)
			{ a.setAnalogPinReporting(j, Arduino.ON);	
			}
			
			// for digital pins its only one setting
			a.enableDigitalPinReporting();	
			
			startProgram();	
		}

		// == START PROGRAM =====================================================================

		function startProgram()
		{	trace("- Start program.");

			// start the timer that calls the onTick function
			refreshTimer.start();	
		}

		// == YOUR PROGRAM HERE =================================================================

		/* 	

		How the get data from the Arduino :
			
			a.getDigitalData(<pin number>); 
			example : a.getDigitalData(2);
			
			a.getAnalogData(<analog pin number>);  
			example : a.getAnalogData(0);

			note : you can only get data from a pin if its configured as INPUT 
				   input. 
			
		Set Arduino outputs :
			
			a.writeDigitalPin(<pin number>, <0 or 1>); 
			example : a.writeDigitalPin(13, 1);
			
			When configured as PWM	 :	a.writeAnalogPin(<pin number>, <0 - 255>); 
			When configured as Servo :  a.writeAnalogPin(<pin number>, <0 - 179>);
			
			example : a.writeAnalogPin(9,128);	
			
			note :  to write digital data the pin has to be configured as OUTPUT
					to write analog data the pin has to be configured as PWM
					to write servo position data the pin has to be configured as servo

		*/
		 
		/* In the function onTick we change the y positions of 3 sprites on the stage.
		   - ball1: direct analogValue of input 0
		   - ball2: analogValue doesn't exceed the stageHeight-the height of the ball.  
		   - ball3: as ball2 but then smoothed
		   
		   Check other inputs also in the onTick function. 
		*/

		function onTick(event:TimerEvent):void 
		{	
			// calculate position
			var analogValueH:Number;
			var analogValueV:Number;
			analogValueH = a.getAnalogData(1);
			analogValueV = a.getAnalogData(0);
			
			// use analogValue directly for ball1 y value
			ball1.y = analogValueH;
			ball1.x = analogValueV;
			
			// keep the ball2 in range of the stage 
			ball2.y = analogValueV * ((stage.stageHeight-ball2.height)/1023); 
			
			// keep the ball3 in range of the stage and smooth movement
			var position:Number = analogValueH * ((stage.stageHeight-ball3.height)/1023); 
			
			// smooth factor between 0-1. The higher the slower the changes, but more smooth. 
			var factor:Number = 0.8; 
			
			// set ball y position
			ball3.y = (factor * ball3.y) + ((1-factor) * position);
			
			// alpha change with button
			var digitalValue:int;
			digitalValue = a.getDigitalData(8);
			
			// check if the button has changed from true, to false.
			// lastDigitalValue is declared outside this function.
			// more info: http://www.kasperkamperman.com/blog/arduino/arduino-programming-state-change/
			if (digitalValue != lastDigitalValue) {
				
				// button pressed?
				if(digitalValue == true) {
					// change the alpha with 20% (alpha a value between 0.0 and 1.0)
					ball3.alpha = ball3.alpha + 0.2;
					
					// if the alpha exceeds 1.0 make it 0.1;
					if(ball3.alpha>1.0) ball3.alpha = 0.2;
				}
				
				// store the current digitalValue in lastDigitalValue for the 
				// next check (following call of the onTick function).
				lastDigitalValue = digitalValue;
			}
			
			// set the light on pin13 to HIGH (1) when the analogValue is higher than 512
			// otherwise to LOW (0) when the analogValue is below 512
			if(analogValueV>512) 
			{ a.writeDigitalPin(13, 1);
			  //a.writeDigitalPin(22, 1); // Mega
			  //a.writeDigitalPin(24, 1); // Mega
			  //a.writeDigitalPin(26, 1); // Mega
			}
			else				
			{ a.writeDigitalPin(13, 0);
			  //a.writeDigitalPin(22, 0); // Mega
			  //a.writeDigitalPin(24, 0); // Mega
			  //a.writeDigitalPin(26, 0); // Mega
			}
		}
				
	}

}