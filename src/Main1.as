package 
{
	import flash.display.Sprite;
	import flash.events.Event;
	import funnel.*;
	
	/**
	 * ...
	 * @author Chanisco
	 */
	public class Main1 extends Sprite 
	{
		private var aio:Arduino;
		public function Main():void 
		{
			var config:Configuration = Arduino.FIRMATA;
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
			aio = new Arduino(config);
			aio.analogPin(0).addEventListener(PinEvent.CHANGE,
			function(e:Event):void {
				 trace("A0: " + e.target.value);
			})
			aio.addEventListener(Event.ENTER_FRAME, loop);
		}
		
		private function loop(e:Event):void 
		{
			
		}
		
		private function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
		}
		
	}
	
}