package org.openscales.core.events
{
	import org.openscales.basetypes.Bounds;
	import org.openscales.core.feature.Feature;

	/**
	 * Event related to a Feature.
	 */
	public class FeatureEvent extends OpenScalesEvent
	{

		/**
		 * An array of features concerned by the event. Array is used in order to handle cases when the event concern one or
		 * more features like selection. 
		 */
		private var _features:Vector.<Feature> = null;

		/**
		 * To know if ctrl key is pressed
		 */
		private var _ctrlPressed:Boolean = false;


		/**
		 * Event type dispatched before inserting a new feature. 
		 */
		public static const FEATURE_PRE_INSERT:String="openscales.feature.preinsert";
		
		/**
		 * Event type dispatched after inserting a new feature. 
		 */
		public static const FEATURE_INSERT:String="openscales.feature.insert";
		
		/**
		 * Event type dispatched when the cursor is over a feature. 
		 */
		public static const FEATURE_OVER:String="openscales.feature.over";
		
		/**
		 * Event type dispatched when the cursor is leaving a feature. 
		 */
		public static const FEATURE_OUT:String="openscales.feature.out";
		
		/**
		 * Event type dispatched when a click occur on a feature. 
		 */
		public static const FEATURE_CLICK:String="openscales.feature.click";
		
		/**
		 * Event type dispatched when a double click occur on a feature. 
		 */
		public static const FEATURE_DOUBLECLICK:String="openscales.feature.doubleclick";
		
		/**
		 * Event type dispatched when left mouse button is down over a feature. 
		 */
		public static const FEATURE_MOUSEDOWN:String="openscales.feature.mousedown";
		
		/**
		 * Event type dispatched when left mouse button is up over a feature. 
		 */
		public static const FEATURE_MOUSEUP:String="openscales.feature.mouseup";
		
		/**
		 * Event type dispatched when the cursor is moving over a feature. 
		 */
		public static const FEATURE_MOUSEMOVE:String="openscales.feature.mousemove";
		
		/**
		 * Event type dispatched while dragging a feature. 
		 */
		public static const FEATURE_DRAGGING:String="openscales.feature.dragging";
		/**
		 * Event type dispatched when  a feature is deleting
		 * */
		public static const FEATURE_DELETING:String="openscales.feature.deleting";
		
		
		/**
		 * Event type dispatched when  a feature's dragging start
		 * */
		public static const FEATURE_DRAG_START:String="openscales.feature.dragstart";
		
		/**
		 * Event type dispatched when  a feature's dragging stop
		 * */
		public static const FEATURE_DRAG_STOP:String="openscales.feature.dragstop";
		
		/**
		 * Event type dispatched when one or more features are selected. 
		 */
		public static const FEATURE_SELECTED:String="openscales.feature.selected";
		
		/**
		 * Event type dispatched when one or more features are unselected. 
		 */
		public static const FEATURE_UNSELECTED:String="org.openscales.feature.unselected";

		/**
		 * Event type dispatched when we start dragging of a temporary features
		 * */
		
		public static const EDITION_POINT_FEATURE_DRAG_START:String="org.openscales.editionFeature.dragstart";	
		/**
		 * Event type dispatched when we stop dragging of a temporary features
		 * */
		
		public static const EDITION_POINT_FEATURE_DRAG_STOP:String="org.openscales.editionFeature.dragstop";	
		
		/**
		 * Event type dispatched when a feature is selected, and we want to update information in FeatureInfo component
		 */
		 public static const FEATURE_SHOW_INFORMATIONS:String="org.openscales.feature.showinformations";
		
		/**
		 * FeatureEvent constructor
		 *
		 * @param type event
		 * @param active to determinates if the handler is active
		 */

		public function FeatureEvent(type:String,feature:Feature,ctrlStatus:Boolean = false,bubbles:Boolean=false,cancelable:Boolean=false,bounds:Bounds = null) 
		{
			super(type, bubbles, cancelable);
			this.feature=feature;
			this._ctrlPressed = ctrlStatus;
		}

		/**
		 * Features concerned by the event. If only one feature is concerned, you should use the feature (without s) getter and setter.
		 */
		public function get features():Vector.<Feature>{
			return this._features;
		}
		public function set features(value:Vector.<Feature>):void{
			this._features=value;
		}
		
		/**
		 * Feature concerned by the event. If the event concern multiple features, the first one is returned.
		 */
		public function get feature():Feature{
			return this._features[0];
		}
		public function set feature(value:Feature):void{
			var v:Vector.<Feature> = new Vector.<Feature>();
			v[0]=value;
			this._features = v;
		}

		/**
		 * To know if ctrl key is pressed
		 * @default false
		 */
		public function get ctrlPressed():Boolean{
			return this._ctrlPressed;
		}
	}
}

