package org.openscales.core.layer
{
	import org.openscales.core.Map;
	import org.openscales.core.basetypes.Bounds;
	import org.openscales.core.basetypes.LonLat;
	import org.openscales.core.basetypes.Pixel;
	import org.openscales.core.basetypes.Size;
	import org.openscales.core.events.LayerEvent;
	import org.openscales.core.security.ISecurity;
	import org.openscales.proj4as.ProjProjection;
	
	import flash.display.Sprite;

	/**
	 * A Layer display image of vector datas on the map, usually loaded from a remote datasource.
	 * @author Bouiaw
	 */
	public class Layer extends Sprite
	{
		private const RESOLUTION_TOLERANCE:Number = 0.000001;

		private var _isBaseLayer:Boolean = false;
		private var _isFixed:Boolean = false;
		private var _projection:ProjProjection = null;
		private var _units:String = null;
		private var _resolutions:Array = null;
		private var _maxExtent:Bounds = null;
		private var _maxResolution:Number = NaN;
		private var _minResolution:Number = NaN;
		private var _numZoomLevels:Number = NaN;
		private var _minZoomLevel:Number = NaN;
		private var _maxZoomLevel:Number = NaN;
		protected var _imageSize:Size = null;
		private var _proxy:String = null;
		private var _map:Map = null;
		private var _security:ISecurity = null;
		private var _loading:Boolean = false;

		/**
		 * Layer constructor
		 */
		public function Layer (name:String, isBaseLayer:Boolean = false, visible:Boolean = true, 
			projection:String = null, proxy:String = null, security:ISecurity = null) {

			this.name = name;
			this.doubleClickEnabled = true;
			this.isBaseLayer = isBaseLayer;
			this.visible = visible;

			/* If projection string is null or empty, we init the layer's projection
			 with EPSG:4326 */
			if (projection != null && projection != "")
				this._projection = new ProjProjection(projection);
			else
				this._projection = new ProjProjection("EPSG:4326");

			this._proxy = proxy;
		}



		public function destroy(setNewBaseLayer:Boolean = true):void {
			if (this.map != null) {
				this.map.removeLayer(this, setNewBaseLayer);
			}
			this.map = null;

		}

		public function onMapResize():void {

		}

		/**
		 * Redraws the layer.
		 * @return true if the layer was redrawn, false if not
		 *
		 */
		public function redraw():Boolean {
			var redrawn:Boolean = false;
			if (this.map) {

				if (this.extent && this.inRange && this.visible) {
					this.moveTo(this.extent, true, false);
					redrawn = true;
				}
			}  
			return redrawn;
		}

		/**
		 * Set the map where this layer is attached.
		 * Here we take care to bring over any of the necessary default properties from the map.
		 */
		public function set map(map:Map):void {
			this._map = map;
			
			if(!this.maxExtent)
				this.maxExtent = this.map.maxExtent;
			if(!this.units)
				this.units = this.map.units;
			
			this.initResolutions();
		}

		public function get map():Map {
			return this._map;
		}

		/**
		 * This method's responsibility is to set up the 'resolutions' array
		 * for the layer -- this array is what the layer will use to interface
		 * between the zoom levels of the map and the resolution display
		 * of the layer.
		 */
		public function initResolutions():void {
				
			if(isNaN(this.minResolution))
				this.minResolution = this.map.minResolution;
			if(isNaN(this.maxResolution))
				this.maxResolution = this.map.maxResolution;
			if(isNaN(this.numZoomLevels))
				this.numZoomLevels = this.map.numZoomLevels;
			
			if ( (!this.numZoomLevels) && (this.maxZoomLevel) ) {
				this.numZoomLevels = this.maxZoomLevel + 1;
			}

			if (this.minResolution) {
				var ratio:Number = this.maxResolution / this.minResolution;
				this.numZoomLevels = Math.floor(Math.log(ratio) / Math.log(2)) + 1;
			}

			if(!this.resolutions) {
				this.resolutions = new Array();
				for (var i:int=0; i < this.numZoomLevels; i++) {
					var res:Number = this.maxResolution / Math.pow(2, i);
					this.resolutions.push(res);
				}
			}

			this.resolutions.sort(Array.NUMERIC | Array.DESCENDING);

			this.maxResolution = this.resolutions[0];
			this.minResolution = this.resolutions[this.resolutions.length - 1];

		}

		/**
		 * A Bounds object which represents the lon/lat bounds of the current viewPort.
		 */
		public function get extent():Bounds {
			return this.map.extent;
		}

		public function getZoomForExtent(extent:Bounds):Number {
			var viewSize:Size = this.map.size;
			var idealResolution:Number = Math.max( extent.width  / viewSize.w,
				extent.height / viewSize.h );

			return this.getZoomForResolution(idealResolution);
		}

		/**
		 * Return The index of the zoomLevel (entry in the resolutions array)
		 * that corresponds to the best fit resolution given the passed in
		 * value and the 'closest' specification.
		 */
		public function getZoomForResolution(resolution:Number):Number {
			for(var i:int=1; i < this.resolutions.length; i++) {
				if (this.resolutions[i] < resolution && Math.abs(this.resolutions[i] - resolution) > RESOLUTION_TOLERANCE) {
					break;
				}
			}
			return (i - 1);
		}

		/**
		 * Return a LonLat which is the passed-in map Pixel, translated into
		 * lon/lat by the layer.
		 */
		public function getLonLatFromMapPx(viewPortPx:Pixel):LonLat {
			var lonlat:LonLat = null;
			if (viewPortPx != null) {
				var size:Size = this.map.size;
				var center:LonLat = this.map.center;
				if (center) {
					var res:Number  = this.map.resolution;

					var delta_x:Number = viewPortPx.x - (size.w / 2);
					var delta_y:Number = viewPortPx.y - (size.h / 2);

					lonlat = new LonLat(center.lon + delta_x * res ,
						center.lat - delta_y * res);
				}
			}
			return lonlat;
		}

		/**
		 * Return a Pixel which is the passed-in LonLat,translated into map pixels.
		 */
		public function getMapPxFromLonLat(lonlat:LonLat):Pixel {
			var px:Pixel = null;
			if (lonlat != null) {
				var resolution:Number = this.map.resolution;
				var extent:Bounds = this.map.extent;
				px = new Pixel(
					Math.round(1/resolution * (lonlat.lon - extent.left)),
					Math.round(1/resolution * (extent.top - lonlat.lat))
					);
			}
			return px;
		}

		public function moveTo(bounds:Bounds, zoomChanged:Boolean, dragging:Boolean = false,resizing:Boolean=false):void {
			var display:Boolean = this.visible; 
			if (!this.isBaseLayer) {
				display = display  && this.inRange ;
			}
			this.visible = display; 
		}

		public function get inRange():Boolean {
			var inRange:Boolean = false;
			if (this.map) {
				inRange = ( (this.map.resolution >= this.minResolution) &&
					(this.map.resolution <= this.maxResolution) );
			}
			return inRange; 
		}


		/**
		 * The currently selected resolution of the map, taken from the
		 * resolutions array, indexed by current zoom level
		 */
		public function get resolution():Number {
			var zoom:Number = this.map.zoom;
			return this.resolutions[zoom];
		}

		public function getURL(bounds:Bounds):String {
			return null;
		}

		/**
		 * For layers with a gutter, the image is larger than
		 * the tile by twice the gutter in each dimension.
		 */
		public function get imageSize():Size {
			return this._imageSize;
		}

		public function set imageSize(value:Size):void {
			this._imageSize = value;
		}

		public function get zindex():int
		{
			return this.parent.getChildIndex(this);
		}

		public function set zindex(value:int):void {
			this.parent.setChildIndex(this, value);
		}

		public function get minZoomLevel():Number {
			return this._minZoomLevel;
		}

		public function set minZoomLevel(value:Number):void {
			this._minZoomLevel = value;
		}
		
		public function get maxZoomLevel():Number {
			return this._maxZoomLevel;
		}

		public function set maxZoomLevel(value:Number):void {
			this._maxZoomLevel = value;
		}

		/**
		 * Number of zoom levels
		 */
		public function get numZoomLevels():Number {
			return this._numZoomLevels;
		}

		public function set numZoomLevels(value:Number):void {
			this._numZoomLevels = value;
		}

		public function get maxResolution():Number {
			return this._maxResolution;
		}

		public function set maxResolution(value:Number):void {
			this._maxResolution = value;
		}

		public function get minResolution():Number {
			return this._minResolution;
		}

		public function set minResolution(value:Number):void {
			this._minResolution = value;
		}

		/**
		 * The center of these bounds will not stray outside
		 * of the viewport extent during panning.  In addition, if
		 * <displayOutsideMaxExtent> is set to false, data will not be
		 * requested that falls completely outside of these bounds.
		 */
		public function get maxExtent():Bounds {
			return this._maxExtent;
		}

		public function set maxExtent(value:Bounds):void {
			this._maxExtent = value;
		}

		/**
		 * A list of map resolutions (map units per pixel) in descending
		 * order. If this is not set in the layer constructor, it will be set
		 * based on other resolution related properties (maxExtent, maxResolution, etc.).
		 */
		public function get resolutions():Array {
			return this._resolutions;
		}

		public function set resolutions(value:Array):void {
			this._resolutions = value;
		}

		/**
		 * The layer units. Check possible values in the Unit class.
		 */
		public function get units():String {
			return this._units;
		}

		public function set units(value:String):void {
			this._units = value;
		}

		/**
		 * Override the default projection. You should also set maxExtent,
		 * maxResolution, and units if appropriate.
		 */
		public function get projection():ProjProjection {
			return this._projection;
		}

		public function set projection(value:ProjProjection):void {
			this._projection = value;
		}


		/**
		 * Whether or not the layer is a base layer. This should be set
		 * individually by all subclasses. Default is false
		 */
		public function get isBaseLayer():Boolean {
			return this._isBaseLayer;
		}

		public function set isBaseLayer(value:Boolean):void {
			this._isBaseLayer = value;
		}

		/**
		 * Whether or not the layer is a fixed layer. 
		 * Fixed layers cannot be controlled by users
		 */
		public function get isFixed():Boolean {
			return this._isFixed;
		}

		public function set isFixed(value:Boolean):void {
			this._isFixed = value;
		}

		/**
		 * Proxy (usually a PHP, Python, or Java script) used to request remote servers like
		 * WFS servers in order to allow crossdomain requests. Remote servers can be used without
		 * proxy script by using crossdomain.xml file like http://openscales.org/crossdomain.xml
		 *
		 * If not defined, use map proxy
		 */
		public function get proxy():String {
			return this._proxy;
		}

		public function set proxy(value:String):void {
			this._proxy = value;
		}

		public function get security():ISecurity {
			return this._security;
		}

		public function set security(value:ISecurity):void {
			this._security = value;
		}
		
		public override function set visible(value:Boolean):void{
			super.visible = value;
			if (this.map != null)
			{
			 	this.map.dispatchEvent(new LayerEvent(LayerEvent.LAYER_VISIBLE_CHANGED,this));
			}
		}
		
		/**
		 * Whether or not the layer is loading data
		 */
		public function get loadComplete():Boolean {
			return !this._loading;
		}
		
		/**
		 * Used to set loading status of layer
		 */
		protected function set loading(value:Boolean):void {
			if (value == true && this._loading == false && this.map != null) {
			  _loading = value;
			  this.map.dispatchEvent(new LayerEvent(LayerEvent.LAYER_LOAD_START,this));
			}
						 
			if (value == false && this._loading == true && this.map != null) {
			  _loading = value;
			  this.map.dispatchEvent(new LayerEvent(LayerEvent.LAYER_LOAD_END,this));
			} 
			
		}
	}
}

