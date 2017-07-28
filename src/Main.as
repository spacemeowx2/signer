package
{
	import flash.display.Sprite;
	import flash.events.Event;
    import flash.display.MovieClip;
	import flash.net.URLLoader;
    import flash.system.ApplicationDomain
    import flash.system.SecurityDomain
    import flash.system.LoaderContext
    import flash.net.URLRequest
    import flash.display.Loader;
    import flash.events.Event;
    import flash.events.UncaughtErrorEvent;
    import flash.events.TimerEvent;
    import flash.events.ProgressEvent;
    import flash.events.IOErrorEvent;
    import flash.utils.Timer;
	import flash.external.ExternalInterface;
	
	/**
	 * ...
	 * @author space
	 */
	public class Main extends Sprite 
	{
        public var loader: Loader;
        public var CModule: Object;
		private var timer: Timer;
		private var urlloader: URLLoader;
		
		public function trace(s: Object): void {
			
		}
		
		public function jsCall(func: String): void {
			try {
				trace(flash.external.ExternalInterface.available);
				ExternalInterface.call(func);
			} catch (e: Error) {
				trace("jscall");
				trace(e);	
			}
		}
		
		public function Main() 
		{
			if (stage) init();
			else addEventListener(Event.ADDED_TO_STAGE, init);
		}
		
		public function requestNewest(cb: Function):void {
			trace("request newest");
			var request: URLRequest = new URLRequest("http://douyu.coding.me/newest.txt?v="+((new Date()).getTime().toString()));
			urlloader = new URLLoader();
			urlloader.addEventListener(Event.COMPLETE, function (e: Event):void {
				cb(true, e.target.data);
			});
			urlloader.addEventListener(IOErrorEvent.IO_ERROR, function (e: IOErrorEvent):void {
				cb(false, null);
			});
			request.method = "GET";
			urlloader.load(request);
		}
		
		public function init(e:Event = null):void 
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			// entry point
			ExternalInterface.addCallback("sign", doSign)
			jsCall("signerLoaded");
			requestNewest(function (success:Boolean, data: String): void{
				if (!success) {
					trace("failed");
				}
				trace(data);
				loadSWF(data);
			});
		}
		public function loadSWF(swfurl: String): void {
            var loaderContext:LoaderContext = new LoaderContext(false, ApplicationDomain.currentDomain, SecurityDomain.currentDomain);
            loader = new Loader();
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, this.loadComplete);
			loader.contentLoaderInfo.addEventListener(ProgressEvent.PROGRESS, this.onProgress);
			loader.load(new URLRequest(swfurl), loaderContext);
            
            trace('load');
			timer = new Timer(100);
			timer.addEventListener(TimerEvent.TIMER, this.isCModuleReady);
		}
		public function isCModuleReady(e:Event): void {
			try {
				this.CModule = ApplicationDomain.currentDomain.getDefinition("sample.xx.CModule");
				timer.stop();
			} catch (e: Error) {
				trace(e);
				return
			}
			jsCall("signerReady");
			trace("ready");
        }
		// Test.sign(687423, 25020488, 'D2C2C9675D34594BCD066616B5C9AE44')
		public function doSign(roomId: Number, timeInSec: Number, did: String): String {
			trace("sign");
			var StreamSignDataPtr: Number = CModule.malloc(4);
			var outptr1: Number = CModule.malloc(4);
			var obj: Object = flash.utils.getDefinitionByName("xx");
			// var datalen: Number = obj.sub_13(687423, 25020488, 'D2C2C9675D34594BCD066616B5C9AE44', outptr1, StreamSignDataPtr);
			var datalen: Number = obj.sub_13(roomId, timeInSec, did, outptr1, StreamSignDataPtr);
			var sign:String = CModule.readString(CModule.read32(StreamSignDataPtr), 32)
			var verData:Number = CModule.read32(outptr1);
			trace(sign);
			trace(verData);
			CModule.free(StreamSignDataPtr);
			CModule.free(outptr1);
			return sign;
		}
        public function loadComplete(e:Event):void{
            trace('COMPLETE');
			timer.start();
        }
		public function onProgress(e:ProgressEvent):void{
			trace(e.type + ":" + e.bytesLoaded + "/" + e.bytesTotal);
		}
	}
	
}